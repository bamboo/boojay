namespace Boojay.Compilation.TypeSystem

import System

import java.util.jar

import Boo.Lang.Useful.Attributes
import Boo.Lang.Compiler
import Boo.Lang.Compiler.TypeSystem
import Boo.Lang.Compiler.TypeSystem.Services

class JarTypeSystemProvider:
	
	def ForJar(jar as string):
		return JarCompileUnit(jar)
		
class JarCompileUnit(ICompileUnit):
	
	_root as JarRootNamespace
	
	def constructor(jar as string):
		_root = JarRootNamespace(jar)
		
	EntityType:
		get: return EntityType.CompileUnit
		
	Name:
		get: return _root.Jar.getName()
		
	FullName:
		get: return Name
		
	RootNamespace:
		get: return _root
		
class JarRootNamespace(JarNamespaceCommon):
			
	def constructor(jar as string):
		_jar = JarFile(jar)

class JarNamespace(JarNamespaceCommon):
	_entry as JarEntry
	_parentName as string
	
	[getter(Name)]
	_name as string
	
	override FullName as string:
		get:
			return _name if string.IsNullOrEmpty(_parentName) 
			return "${_parentName}/${_name}"
	
	def constructor(parentName as string, jar as JarFile, name as string):
		_jar = jar
		_name = name
		_parentName = parentName

	override def ShouldProcess(entry as JarEntry):
		return entry.getName().StartsWith("${FullName}/")

	override def GetRelativeEntryName(entry as JarEntry):
		return StringUtil.RemoveStart(entry.getName(), "${FullName}/")
		
abstract class JarNamespaceCommon(AbstractNamespace):

	[getter(Jar)]
	_jar as JarFile

	_children = {}
	
	virtual FullName as string:
		get:
			return ""
			
	[once]
	override def GetMembers():
		return array(LoadMembers())
		
	private def LoadMembers() as IEntity*:
		entries = _jar.entries()
		while entries.hasMoreElements():
			entry as JarEntry = entries.nextElement()
			continue unless ShouldProcess(entry)

			relativeName = GetRelativeEntryName(entry)
			
			if HasNamespace(relativeName):
				yield ProcessNamespace(relativeName)
			else:
				yield JarClass(_jar, entry)

	virtual protected def ShouldProcess(entry as JarEntry):
		return true
			
	virtual protected def GetRelativeEntryName(entry as JarEntry):
		return entry.getName()

	private def HasNamespace(name as string):
		return "/" in name

	private def ProcessNamespace(name as string) as INamespace:
		return GetNamespace(/\//.Split(name)[0])
		
	private def GetNamespace(name as string):
		_children[name] = JarNamespace(FullName, _jar, name) unless _children.Contains(name)
		return _children[name]
		
class JavaMethod(IMethod):
	
	_declaringType as IType
	_name as string
	_descriptor as string
	_access as int
	
	def constructor(declaringType as IType, name as string, descriptor as string, access as int):
		_declaringType = declaringType
		_name = name
		_descriptor = descriptor
		_access = access
	
	EntityType:
		get: return EntityType.Method
		
	Name:
		get: return _name
		
	FullName:
		get: return "${_declaringType.FullName}.${_name}"
		
	DeclaringType:
		get: return _declaringType
		
	IsPublic:
		get: return (_access & org.objectweb.asm.Opcodes.ACC_PUBLIC) != 0
		
	IsProtected:
		get: return (_access & org.objectweb.asm.Opcodes.ACC_PROTECTED) != 0

	IsStatic:
		get: return (_access & org.objectweb.asm.Opcodes.ACC_STATIC) != 0
		
	AcceptVarArgs: 
		get: return (_access & org.objectweb.asm.Opcodes.ACC_VARARGS) != 0

	IsExtension:
		get: return false // FIXME
		
	Type:
		get: return self.CallableType
	
	CallableType:
		get: return my(TypeSystemServices).GetCallableType(self)
	
	ReturnType as IType: // FIXME
		get:
			print "RETURNTYPE:", org.objectweb.asm.Type.getReturnType(_descriptor)
			return null // return my(NameResolutionService).ResolveQualifiedName()
		
	def GetParameters(): // FIXME
		return array[of IParameter](0)

class JavaConstructor(IConstructor):
	_declaringType as IType
	
	def constructor(declaringType as IType):
		_declaringType = declaringType
			
	EntityType:
		get: return EntityType.Constructor
				
	Name:
		get: return "constructor"
		
	FullName:
		get: return "${_declaringType.FullName}.${Name}"
		
	DeclaringType:
		get: return _declaringType
		
	def GetParameters():
		return array[of IParameter](0)

class StringUtil:
	static def RemoveStart(value as string, start as string):
		return value unless value.StartsWith(start)
		return value[start.Length:]
		
	static def RemoveEnd(value as string, end as string):
		return value unless value.EndsWith(end)
		return value[:-end.Length]


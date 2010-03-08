namespace Boojay.Compilation.TypeSystem

import System
import System.Collections.Generic
import System.IO

import java.util.jar

import Boo.Lang.Useful.Attributes

import Boo.Lang.Compiler
import Boo.Lang.Compiler.TypeSystem
import Boo.Lang.Compiler.TypeSystem.Core
import Boo.Lang.Compiler.TypeSystem.Services

import org.objectweb.asm
import org.objectweb.asm.commons

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
			
			if (HasNamespace(relativeName)):
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

class JarClass(AbstractType):
	
	_jar as JarFile
	_entry as JarEntry
	_name as string
	_fullName as string
	
	def constructor(jar as JarFile, entry as JarEntry):
		_jar = jar
		_entry = entry
		_name = Path.GetFileNameWithoutExtension(entry.getName())
		_fullName = StringUtil.RemoveEnd(entry.getName().Replace("/", "."), ".class")
		
	override Name:
		get: return _name
		
	override FullName:
		get: return _fullName
		
	override EntityType:
		get: return EntityType.Type
		
	[once]
	override def GetMembers():
		return array(LoadMembers())
			
	def Resolve(result as ICollection[of IEntity], name as string, typesToConsider as EntityType):
		return my(NameResolutionService).Resolve(name, GetMembers(), typesToConsider, result)
		
	private def LoadMembers() as IEntity*:
		reader = ClassReader(_jar.getInputStream(_entry))
		visitor = ClassFileParser(self)
		flags = ClassReader.SKIP_CODE | ClassReader.SKIP_DEBUG | ClassReader.SKIP_FRAMES
		reader.accept(visitor, flags)
		return visitor.Members
		
class ClassFileParser(EmptyVisitor):
	
	_declaringType as IType
	[getter(Members)] _members = List[of IEntity]()
	
	def constructor(declaringType as IType):
		_declaringType = declaringType
		
	override def visit(version as int, access as int, name as string,
			signature as string, superName as string, 
			interfaces as (string)):
		pass

	override def visitMethod(access as int, name as string,
					desc as string, signature as string, exceptions as (string)):
		method = JavaMethod(_declaringType, name)
		_members.Add(method)
		return super(access, name, desc, signature, exceptions)
		
class JavaMethod(IMethod):
	
	_declaringType as IType
	_name as string
	
	def constructor(declaringType as IType, name as string):
		_declaringType = declaringType
		_name = name
	
	EntityType:
		get: return EntityType.Method
		
	Name:
		get: return _name
		
	FullName:
		get: return "${_declaringType.FullName}.${_name}"
		
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
		

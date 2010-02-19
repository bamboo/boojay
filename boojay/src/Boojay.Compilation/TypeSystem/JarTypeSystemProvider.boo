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
		
class JarRootNamespace(AbstractNamespace):
	
	[getter(Jar)]
	_jar as JarFile
	
	def constructor(jar as string):
		_jar = JarFile(jar)
		
	[once]
	override def GetMembers():
		return array(LoadMembers())
		
	private def LoadMembers() as IEntity*:
		entries = _jar.entries()
		while entries.hasMoreElements():
			entry as JarEntry = entries.nextElement()
			entryName = entry.getName()
			continue unless entryName.EndsWith(".class")
			assert not entry.isDirectory()
			
			yield JarClass(_jar, entry)

class JarClass(AbstractType):
	
	_jar as JarFile
	_entry as JarEntry
	_name as string
	
	def constructor(jar as JarFile, entry as JarEntry):
		_jar = jar
		_entry = entry
		_name = Path.GetFileNameWithoutExtension(entry.getName())
		
	override Name:
		get: return _name
		
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

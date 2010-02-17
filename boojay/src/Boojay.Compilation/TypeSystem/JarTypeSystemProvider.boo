namespace Boojay.Compilation.TypeSystem

import System
import System.IO

import java.util.jar

import Useful.Attributes
import Boo.Lang.Compiler.TypeSystem
import Boo.Lang.Compiler.TypeSystem.Core

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
		get: return _root.Jar
		
	FullName:
		get: return Name
		
	RootNamespace:
		get: return _root
		
class JarRootNamespace(AbstractNamespace):
	
	[getter(Jar)]
	_jar as string
	
	def constructor(jar as string):
		_jar = jar
		
	[once]
	override def GetMembers():
		return array(LoadMembers())
		
	private def LoadMembers() as IEntity*:
		jar = JarFile(_jar)
		try:
			entries = jar.entries()
			while entries.hasMoreElements():
				entry as JarEntry = entries.nextElement()
				entryName = entry.getName()
				continue unless entryName.EndsWith(".class")
				assert not entry.isDirectory()
				
				yield JarClass(Path.GetFileNameWithoutExtension(entryName))
				
		ensure:
			jar.close()

class JarClass(AbstractType):
	
	_name as string
	
	def constructor(name as string):
		_name = name
		
	override Name:
		get: return _name
		
	override EntityType:
		get: return EntityType.Type
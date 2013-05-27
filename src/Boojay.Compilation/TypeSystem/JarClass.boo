namespace Boojay.Compilation.TypeSystem

import System
import System.Collections.Generic
import System.IO

import Boo.Lang.Compiler.TypeSystem
import Boo.Lang.Compiler.TypeSystem.Core
import Boo.Lang.Compiler.TypeSystem.Services

import Boo.Lang.Environments
import Boo.Lang.Useful.Attributes

import java.util.jar

class JarClass(AbstractType):
	
	_jar as JarFile
	_entry as JarEntry
	
	def constructor(jar as JarFile, entry as JarEntry):
		_jar = jar
		_entry = entry
		
	override Name:
		[once] get: return Path.GetFileNameWithoutExtension(_entry.getName())
		
	override FullName:
		[once] get: return _entry.getName().Replace("/", ".").RemoveEnd(".class")
		
	override EntityType:
		get: return EntityType.Type
		
	override IsClass:
		get: return not Descriptor.IsInterface
		
	override IsInterface:
		get: return Descriptor.IsInterface

	override IsFinal:
		get: return Descriptor.IsFinal
		
	override def IsAssignableFrom(other as IType):
		return other is self
		
	override def GetMembers():
		return Descriptor.members
		
	def Resolve(result as ICollection[of IEntity], name as string, typesToConsider as EntityType):
		return my(NameResolutionService).Resolve(name, GetMembers(), typesToConsider, result)
		
	Descriptor:
		[once] get:
			classFile = _jar.getInputStream(_entry)
			try:
				return ClassDescriptor.FromFile(classFile, self)
			ensure:
				classFile.close()
		


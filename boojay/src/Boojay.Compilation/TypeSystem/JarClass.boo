namespace Boojay.Compilation.TypeSystem

import System
import System.Collections.Generic
import System.IO

import Boo.Lang.Compiler
import Boo.Lang.Compiler.TypeSystem
import Boo.Lang.Compiler.TypeSystem.Core
import Boo.Lang.Compiler.TypeSystem.Services
import Boo.Lang.Useful.Attributes

import org.objectweb.asm

import java.util.jar

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
		
	[once]
	override def GetConstructors():
		return [ctor for ctor in GetMembers() if ctor isa IConstructor].ToArray(IConstructor)
			
	def Resolve(result as ICollection[of IEntity], name as string, typesToConsider as EntityType):
		return my(NameResolutionService).Resolve(name, GetMembers(), typesToConsider, result)
		
	private def LoadMembers() as IEntity*:
		reader = ClassReader(_jar.getInputStream(_entry))
		visitor = ClassFileParser(self)
		flags = ClassReader.SKIP_CODE | ClassReader.SKIP_DEBUG | ClassReader.SKIP_FRAMES
		reader.accept(visitor, flags)
		return visitor.Members
		

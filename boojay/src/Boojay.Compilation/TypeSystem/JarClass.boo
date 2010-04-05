namespace Boojay.Compilation.TypeSystem

import System
import System.Collections.Generic
import System.IO

import Boo.Lang.Compiler
import Boo.Lang.Compiler.TypeSystem
import Boo.Lang.Compiler.TypeSystem.Core
import Boo.Lang.Compiler.TypeSystem.Services

import org.objectweb.asm

import java.util.jar

class JarClass(AbstractType):
	
	_jar as JarFile
	_entry as JarEntry
	_name as string
	_fullName as string
	_visitor as ClassFileParser
	
	def constructor(jar as JarFile, entry as JarEntry):
		_jar = jar
		_entry = entry
		_name = Path.GetFileNameWithoutExtension(entry.getName())
		_fullName = entry.getName().Replace("/", ".").RemoveEnd(".class")
		
	override Name:
		get: return _name
		
	override FullName:
		get: return _fullName
		
	override EntityType:
		get: return EntityType.Type
		
	override IsClass:
		get: return true

	override IsFinal:
		get: 
			VisitClass()
			return _visitor.IsFinal
		
	override def GetMembers():
		VisitClass()
		return array(_visitor.Members)
		
	def Resolve(result as ICollection[of IEntity], name as string, typesToConsider as EntityType):
		return my(NameResolutionService).Resolve(name, GetMembers(), typesToConsider, result)
		
	private def VisitClass():
		return if _visitor
		reader = ClassReader(_jar.getInputStream(_entry))
		_visitor = ClassFileParser(self)
		flags = ClassReader.SKIP_CODE | ClassReader.SKIP_DEBUG | ClassReader.SKIP_FRAMES
		reader.accept(_visitor, flags)


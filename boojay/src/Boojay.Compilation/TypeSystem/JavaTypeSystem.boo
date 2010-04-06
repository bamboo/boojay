namespace Boojay.Compilation.TypeSystem

import Boo.Lang.Compiler
import Boo.Lang.Compiler.TypeSystem
import Boo.Lang.Compiler.TypeSystem.Reflection

class JavaReflectionTypeSystemProvider(ReflectionTypeSystemProvider):
	
	public static final SharedTypeSystemProvider = JavaReflectionTypeSystemProvider()
	
	def constructor():
		ReplaceMapping(System.String, JavaLangString)
		ReplaceMapping(java.lang.String, JavaLangString)
		ReplaceMapping(System.MulticastDelegate, Boojay.Lang.MulticastDelegate)
		ReplaceMapping(Boo.Lang.List, Boojay.Lang.List)
		ReplaceMapping(Boo.Lang.Hash, Boojay.Lang.Hash)
		ReplaceMapping(System.NotImplementedException, Boojay.Lang.NotImplementedException)
		
	override def CreateEntityForRegularType(type as System.Type):
		return BeanAwareType(self, type)
	
	def ReplaceMapping(existing as System.Type, new as System.Type):
		mapping = Map(new)
		MapTo(existing, mapping)
		return mapping

class JavaTypeSystem(TypeSystemServices):
	
	def constructor():
		self(CompilerContext())
	
	def constructor(context as CompilerContext):
		super(context)
		
	override ExceptionType:
		get: return Map(java.lang.Exception)
		
class JavaLangString(java.lang.Character*):

	self[index as int] as char:
		get: raise System.NotImplementedException()
	
	Length as int:
		get: raise System.NotImplementedException()
		
	def GetEnumerator():
		pass
		
	def System.Collections.IEnumerable.GetEnumerator():
		pass
		
	def toUpperCase():
		return self
		
	def toLowerCase():
		return self
		
	def trim():
		return self
		
	def toCharArray() as (char):
		return null

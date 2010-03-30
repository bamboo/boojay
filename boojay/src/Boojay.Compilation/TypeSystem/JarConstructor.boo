namespace Boojay.Compilation.TypeSystem

import Boo.Lang.Compiler.TypeSystem

class JarConstructor(IConstructor):
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
		
	IsStatic:
		get: return false
		
	def GetParameters():
		return array[of IParameter](0)

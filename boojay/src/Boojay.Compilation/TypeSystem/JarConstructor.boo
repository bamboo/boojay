namespace Boojay.Compilation.TypeSystem

import Boo.Lang.Compiler
import Boo.Lang.Compiler.TypeSystem

import org.objectweb.asm

class JarConstructor(IConstructor):
	_declaringType as IType
	_access as int
	
	def constructor(declaringType as IType, access as int):
		_declaringType = declaringType
		_access = access
	
	IsPublic as bool:
		get: return (_access & Opcodes.ACC_PUBLIC) != 0

	IsPrivate as bool:
		get: return (_access & Opcodes.ACC_PRIVATE) != 0

	IsStatic as bool:
		get: return (_access & Opcodes.ACC_STATIC) != 0
	
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

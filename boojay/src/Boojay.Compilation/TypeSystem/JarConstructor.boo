namespace Boojay.Compilation.TypeSystem

import Boo.Lang.Compiler
import Boo.Lang.Compiler.TypeSystem

import org.objectweb.asm

class JarConstructor(IConstructor, IMethod):
	_declaringType as IType
	_access as int
	
	def constructor(declaringType as IType, access as int):
		_declaringType = declaringType
		_access = access
	
	IsPublic:
		get:
			return (_access & Opcodes.ACC_PUBLIC) != 0

	IsPrivate:
		get: return (_access & Opcodes.ACC_PRIVATE) != 0
		
	/*
	IsProtected:
		get: return (_access & Opcodes.ACC_PROTECTED) != 0
		
	IsInternal:
		get: return false
	*/

	IsStatic:
		get: return (_access & Opcodes.ACC_STATIC) != 0
		
	AcceptVarArgs:
		get: return false
		
	CallableType:
		get: return my(TypeSystemServices).GetCallableType(self)
	
	EntityType:
		get: return EntityType.Constructor
	
	Type:
		get:
			return self.CallableType
		
	ReturnType:
		get: return my(TypeSystemServices).VoidType
					
	Name:
		get: return "constructor"
		
	FullName:
		get: return "${_declaringType.FullName}.${Name}"
		
	DeclaringType:
		get: return _declaringType
				
	def GetParameters():
		return array[of IParameter](0)

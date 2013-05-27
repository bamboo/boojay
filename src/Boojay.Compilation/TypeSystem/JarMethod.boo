namespace Boojay.Compilation.TypeSystem

import Environments

import Compiler.TypeSystem
import Boo.Lang.Useful.Attributes
import org.objectweb.asm

class JarMethod(IMethod):
	
	_declaringType as IType
	_name as string
	_descriptor as string
	_access as int
	
	def constructor(declaringType as IType, name as string, descriptor as string, access as int):
		_declaringType = declaringType
		_name = name
		_descriptor = descriptor
		_access = access
	
	EntityType:
		get: return EntityType.Method
		
	Name:
		get: return _name
		
	FullName:
		get: return "${_declaringType.FullName}.${_name}"
		
	DeclaringType:
		get: return _declaringType
		
	IsPublic:
		get: return (_access & Opcodes.ACC_PUBLIC) != 0
		
	IsProtected:
		get: return (_access & Opcodes.ACC_PROTECTED) != 0

	IsPrivate:
		get: return (_access & Opcodes.ACC_PRIVATE) != 0

	IsInternal:
		get: return false
		
	IsPInvoke:
		get: return false
		
	IsFinal:
		get: return (_access & Opcodes.ACC_FINAL) != 0

	IsStatic:
		get: return (_access & Opcodes.ACC_STATIC) != 0
		
	AcceptVarArgs: 
		get: return (_access & Opcodes.ACC_VARARGS) != 0
		
	IsVirtual:
		get: return (_access & Opcodes.ACC_FINAL) == 0
		
	IsAbstract:
		get: return (_access & Opcodes.ACC_ABSTRACT) != 0

	IsExtension:
		get: return false // FIXME
		
	IsSpecialName:
		get: return false // FIXME
		
	Type:
		get: return self.CallableType
	
	CallableType:
		get: return my(TypeSystemServices).GetCallableType(self)
		
	GenericInfo:
		get: return null
		
	ConstructedInfo:
		get: return null
		
	IsDuckTyped:
		get: return false
	
	ReturnType as IType:
		[once] get:
			asmType = org.objectweb.asm.Type.getReturnType(_descriptor)
			return my(AsmTypeResolver).ResolveType(asmType)
	
	[once]
	def GetParameters():
		asmParamTypes = org.objectweb.asm.Type.getArgumentTypes(_descriptor)
		return array(Parameter(self, "arg${i}", param) for i, param in enumerate(asmParamTypes))
		
	def IsDefined(annotationType as IType):
		return false

class Parameter(IParameter):
	_declaringMethod as IMethod
	_name as string
	__type as org.objectweb.asm.Type
		
	def constructor(declaringMethod as IMethod, name as string, type as org.objectweb.asm.Type):
		_declaringMethod = declaringMethod
		_name = name
		__type = type
		
	Type:
		[once] get: return my(AsmTypeResolver).ResolveType(__type)
		
	EntityType:
		get: return EntityType.Parameter

	Name:
		get: return _name
		
	FullName:
		get: return "${_declaringMethod.FullName}.${_name}"
		
	IsByRef:
		get: return false

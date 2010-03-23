namespace Boojay.Compilation.TypeSystem

import Boo.Lang.Compiler
import Boo.Lang.Compiler.TypeSystem
import Boo.Lang.Compiler.TypeSystem.Services
import Boo.Lang.PatternMatching

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
		get: return (_access & org.objectweb.asm.Opcodes.ACC_PUBLIC) != 0
		
	IsProtected:
		get: return (_access & org.objectweb.asm.Opcodes.ACC_PROTECTED) != 0

	IsStatic:
		get: return (_access & org.objectweb.asm.Opcodes.ACC_STATIC) != 0
		
	AcceptVarArgs: 
		get: return (_access & org.objectweb.asm.Opcodes.ACC_VARARGS) != 0

	IsExtension:
		get: return false // FIXME
		
	Type:
		get: return self.CallableType
	
	CallableType:
		get: return my(TypeSystemServices).GetCallableType(self)
	
	ReturnType as IType:
		get:
			asmType = org.objectweb.asm.Type.getReturnType(_descriptor)
			return ResolveTypeName(asmType)
		
	private def ResolveTypeName(asmType as org.objectweb.asm.Type):
		asmTypeName = asmType.ToString()
		match asmTypeName:
			case "b": return my(TypeSystemServices).ByteType
			otherwise: return ResolveNonPrimitive(asmTypeName)
	
	private def ResolveNonPrimitive(typeName as string):
		if typeName[0:1] == "L":
			booTypeName = typeName[1:].Replace("/", ".")
			resolvedType = my(NameResolutionService).ResolveQualifiedName(booTypeName)
			raise "ResolveQualifiedName failed to resolve ${booTypeName}" unless resolvedType
			return resolvedType
		raise "Unknown NonPrimitive ${typeName}"
		
	def GetParameters(): // FIXME
		return array[of IParameter](0)

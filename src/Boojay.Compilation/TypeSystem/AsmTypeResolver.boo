namespace Boojay.Compilation.TypeSystem

import Environments

import Compiler.TypeSystem
import Compiler.TypeSystem.Services
import Boo.Lang.PatternMatching
import org.objectweb.asm(Type)

class AsmTypeResolver:
	
	def ResolveType(asmType as Type):		
		match asmType.getSort():
			case Type.BYTE:
				return TypeSystemServices.ByteType
			case Type.BOOLEAN:
				return TypeSystemServices.BoolType
			case Type.VOID:
				return TypeSystemServices.VoidType
			case Type.INT:
				return TypeSystemServices.IntType
			case Type.OBJECT:
				return ResolveReferenceType(asmType)
			otherwise:
				raise "Invalid type descriptor `$asmType'"
				
	def ResolveReferenceType(asmType as Type):
		match asmType.getClassName():
			case "java.lang.String":
				return TypeSystemServices.StringType
			case typeName:
				return ResolveQualifiedTypeName(typeName)
	
	def ResolveQualifiedTypeName(typeName as string):
		entity = NameResolutionService.ResolveQualifiedName(typeName)			
		if entity is null:
			raise "Failed to resolve `$typeName'"
		if entity.EntityType != EntityType.Type:
			raise "'$typeName' is not a type: `$entity'"
		return entity
		
	defEnvironmentProperty TypeSystemServices
	defEnvironmentProperty NameResolutionService

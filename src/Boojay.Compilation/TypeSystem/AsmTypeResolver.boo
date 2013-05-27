namespace Boojay.Compilation.TypeSystem

import Environments

import Compiler.TypeSystem
import Compiler.TypeSystem.Services
import Boo.Lang.PatternMatching

static class AsmTypeResolver:
	
	def ResolveType(asmType as org.objectweb.asm.Type):
		resolved = _ResolveTypeName(asmType)
		#print asmType, "=>", repr(resolved)
		return resolved
		
	private def _ResolveTypeName(asmType as org.objectweb.asm.Type) as IType:
		asmTypeName = asmType.ToString()
		match asmTypeName:
			case "b": return my(TypeSystemServices).ByteType
			case "V": return my(TypeSystemServices).VoidType
			case "I": return my(TypeSystemServices).IntType
			case "Ljava/lang/String": return my(TypeSystemServices).StringType
			otherwise: return ResolveNonPrimitive(asmTypeName)
	
	private def ResolveNonPrimitive(typeName as string):
		if typeName[0] == char('L'):
			booTypeName = typeName[1:-1].Replace("/", ".")
			entity = my(NameResolutionService).ResolveQualifiedName(booTypeName)			
			if entity is null:
				raise "Failed to resolve `$booTypeName'"
			if entity.EntityType != EntityType.Type:
				raise "'$booTypeName' is not a type: `entity'"
			return entity  
		raise "Invalid type descriptor `$typeName'"
	
def repr(o):
	code = (0 if o is null else o.GetHashCode())
	return "${o} (${code})"

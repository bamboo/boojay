namespace Boojay.Compilation.TypeSystem

import Boo.Lang.Compiler
import Boo.Lang.Compiler.TypeSystem

import org.objectweb.asm

class JarConstructor(IConstructor, JarMethod):
	
	def constructor(declaringType as IType, descriptor as string, access as int):
		super(declaringType, "constructor", descriptor, access)

	EntityType:
		get: return EntityType.Constructor

	ReturnType:
		get: return my(TypeSystemServices).VoidType

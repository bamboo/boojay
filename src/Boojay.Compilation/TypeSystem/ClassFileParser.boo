namespace Boojay.Compilation.TypeSystem

import System
import Boo.Adt
import Boo.Lang.Compiler.TypeSystem
import org.objectweb.asm
import org.objectweb.asm.commons

data ClassDescriptor(access as int, members as (IEntity)):
	
	static def FromFile(classFile as java.io.InputStream, declaringType as IType):
		reader = ClassReader(classFile)
		parser = ClassFileParser(declaringType)
		flags = ClassReader.SKIP_CODE | ClassReader.SKIP_DEBUG | ClassReader.SKIP_FRAMES
		reader.accept(parser, flags)
		return ClassDescriptor(parser.access, parser.members.ToArray())
	
	public IsPublic:
		get: return HasFlag(Opcodes.ACC_PUBLIC)

	public IsPrivate:
		get: return HasFlag(Opcodes.ACC_PRIVATE)

	public IsStatic:
		get: return HasFlag(Opcodes.ACC_STATIC)

	public IsFinal:
		get: return HasFlag(Opcodes.ACC_FINAL)
		
	public IsInterface:
		get: return HasFlag(Opcodes.ACC_INTERFACE)
		
	def HasFlag(flag as int):
		return (access & flag) != 0
	
	
class ClassFileParser(EmptyVisitor):
	
	_declaringType as IType
	
	public access as int
	
	public final members = List[of IEntity]()
		
	def constructor(declaringType as IType):
		_declaringType = declaringType
		
	override def visit(
			version as int, access as int, name as string,
			signature as string, superName as string, 
			interfaces as (string)):
		self.access = access

	override def visitMethod(
			access as int, name as string,
			descriptor as string, signature as string, exceptions as (string)):
		if isConstructor(name):
			members.Add(JarConstructor(_declaringType, descriptor, access))
		else:
			members.Add(JarMethod(_declaringType, name, descriptor, access))
		return super(access, name, descriptor, signature, exceptions)
		
	def isConstructor(methodName as string):
		return methodName.Equals("<init>")

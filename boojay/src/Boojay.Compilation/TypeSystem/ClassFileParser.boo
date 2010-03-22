namespace Boojay.Compilation.TypeSystem

import System
import Boo.Lang.Compiler.TypeSystem
import org.objectweb.asm.commons

class ClassFileParser(EmptyVisitor):
	
	_declaringType as IType
	[getter(Members)] _members = List[of IEntity]()
	
	def constructor(declaringType as IType):
		_declaringType = declaringType
		
	override def visit(version as int, access as int, name as string,
			signature as string, superName as string, 
			interfaces as (string)):
		pass

	override def visitMethod(access as int, name as string,
					desc as string, signature as string, exceptions as (string)):
		if isConstructor(name):
			_members.Add(JavaConstructor(_declaringType))
		else:
			_members.Add(JavaMethod(_declaringType, name, desc, access))
		return super(access, name, desc, signature, exceptions)
		
	private def isConstructor(methodName as string):
		return methodName.Equals("<init>")

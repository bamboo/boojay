namespace Boojay.Compilation.TypeSystem

import Boo.Lang.Compiler.TypeSystem
import Boo.Lang.Compiler.TypeSystem.Reflection

class BeanAwareType(ExternalType):
	
	def constructor(typeSystem as TypeSystemServices, type as System.Type):
		super(typeSystem, type)
		
	override def CreateMembers():
		originalMembers = super()
		beanProperties = BeanPropertyFinder(originalMembers).findAll()
		return array(IEntity, cat(originalMembers, beanProperties))
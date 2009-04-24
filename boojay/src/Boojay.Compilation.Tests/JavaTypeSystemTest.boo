namespace Boojay.Compilation.Tests

import NUnit.Framework

import Boo.Lang.Compiler
import Boo.Lang.Compiler.TypeSystem

[TestFixture]
class JavaTypeSystemTest(TestWithCompilerContext):
	
	class Bean:
		def getName() as string:
			pass
		def setName(value as string):
			pass
	
	[Test]
	def BeanProperties():
		
		WithCompilerContext:
			
			typeSystem = my(TypeSystemServices)
			members = typeSystem.Map(Bean).GetMembers()
			System.Array.Sort(members, { l as IEntity, r as IEntity | l.Name.CompareTo(r.Name) })
			
			Assert.AreEqual("constructor, getName, name, setName", join(member.Name for member in members, ", "))
		
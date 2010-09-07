namespace Boojay.Compilation.Tests

import NUnit.Framework
import Boo.Lang.Environments
import Boo.Lang.Compiler.TypeSystem
import System.Linq.Enumerable

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
			members = typeSystem.Map(Bean).GetMembers().ToArray()
			System.Array.Sort(members, { l, r | l.Name.CompareTo(r.Name) })
			
			Assert.AreEqual("constructor, getName, name, setName", join(member.Name for member in members, ", "))
		
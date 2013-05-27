namespace Boojay.Compilation.Tests

import NUnit.Framework
import Boojay.Compilation.TypeSystem
import Compiler.TypeSystem

[TestFixture]
class SourceJarReferenceTest(TestWithCompilerContext):
	
	[Test]
	def SourceFileDoesNotAppearAsNamespaceMember():
		jarEntries = (Entry("foo/Bar.class"), Entry("foo/Bar.java"))
		jar = generateTempJar(jarEntries)
		
		WithCompilerContext:
			compileUnit = JarTypeSystemProvider().ForJar(jar)
			resolved = compileUnit.ResolveQualifiedName("foo.Bar")
			Assert.AreEqual(EntityType.Type, resolved.EntityType)
		

namespace Boojay.Compilation.Tests

import NUnit.Framework

partial class JarIntergrationTest:

	[Test]
	def Classes():
		runTestCase("tests/jar_integration/Infrastructure.boo")

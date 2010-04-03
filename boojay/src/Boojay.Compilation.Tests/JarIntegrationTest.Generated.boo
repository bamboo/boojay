namespace Boojay.Compilation.Tests

import NUnit.Framework

partial class JarIntergrationTest:

	[Test]
	def Infrastucture():
		runTestCase("tests/jar_integration/Infrastructure.boo")

	[Test]
	def Classes():
		runTestCase("tests/jar_integration/Classes.boo")

namespace Boojay.Compilation.Tests

import Boo.Lang.Compiler.Ast

import NUnit.Framework from nunit.framework

[TestFixture]
partial class JarIntergrationTest(CommonIntegrationTest):
	
	override def compileTest(unit as CompileUnit):
		pass
				
	override def runTest(main as Module):
		return ""

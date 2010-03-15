namespace Boojay.Compilation.Tests

import System.IO

import Boo.Lang.Compiler.Ast

import Boojay.Compilation

[TestFixture]
partial class IntegrationTest(CommonIntegrationTest):

	override def compileTest(unit as CompileUnit):
		boojayCompile(unit)
		
	override def runTest(main as Module):
		return JavaClassRunner.run(moduleClassFor(main))

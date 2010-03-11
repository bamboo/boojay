namespace Boojay.Compilation.Tests

import Boo.Lang.Compiler.Ast

import NUnit.Framework from nunit.framework

[TestFixture]
partial class JarIntergrationTest(CommonIntegrationTest):
	override def compileTest(unit as CompileUnit):
		main = unit.Modules[0]
		main.Imports.Add([| import Boojay.Compilation.Tests |])
		
		compiler = newBooCompiler()
		compiler.Parameters.References.Add(typeof(CommonIntegrationTest).Assembly)
	
		result = compiler.Run(unit)
		assert 0 == len(result.Errors), result.Errors.ToString(true) + unit.ToCodeString()
			
	override def runTest(main as Module):
		return ""

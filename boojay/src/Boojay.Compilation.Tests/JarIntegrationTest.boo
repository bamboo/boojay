namespace Boojay.Compilation.Tests

import System.IO

import Boo.Lang.Compiler
import Boo.Lang.Compiler.Ast

import NUnit.Framework from nunit.framework

[TestFixture]
partial class JarIntergrationTest(CommonIntegrationTest):

	_assembly as Assembly
	
	override def compileTest(unit as CompileUnit):
		main = unit.Modules[0]
		main.Imports.Add([| import Boojay.Compilation.Tests |])
		
		compiler = newBooCompiler()
		compiler.Parameters.References.Add(typeof(CommonIntegrationTest).Assembly)
		compiler.Parameters.References.Add(typeof(Boo.Lang.Compiler.BooCompiler).Assembly)
	
		result = compiler.Run(unit)
		assert 0 == len(result.Errors), result.Errors.ToString(true) + unit.ToCodeString()
		
		_assembly = result.GeneratedAssembly
			
	override def runTest(main as Module):
		result = captureOutput:
			_assembly.EntryPoint.Invoke(null, (null,))
		
		return result
		
	private def captureOutput(block as callable):
		old = System.Console.Out
		writer = StringWriter()
		System.Console.SetOut(writer)
		
		try:
			block()
		ensure:
			System.Console.SetOut(old)
			
		return writer.ToString()
		

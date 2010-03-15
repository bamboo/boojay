namespace Boojay.Compilation.Tests

import Boo.Lang.Parser
import Boo.Lang.Compiler.Ast

import NUnit.Framework from nunit.framework

import System.IO

abstract class CommonIntegrationTest:

	def runTestCase(testFile as string):
		unit = parse(fullpathFor(testFile))	
		main = unit.Modules[0]
		compileTest(unit)
		output = runTest(main)
		Assert.IsNotNull(main.Documentation, "Expecting documentation for '${testFile}'")
		Assert.AreEqual(normalizeWhiteSpace(main.Documentation), normalizeWhiteSpace(output))

	abstract def compileTest(unit as CompileUnit):
		pass
		
	abstract def runTest(main as Module) as string:
		pass

	def fullpathFor(testFile as string):
		return Path.Combine(ProjectFolders.testParentFolder(), testFile)
		
	def normalizeWhiteSpace(s as string):
		return s.Trim().Replace("\r\n", "\n")
		
	def parse(fname as string):
		return BooParser.ParseFile(System.IO.Path.GetFullPath(fname))
		
	def moduleClassFor(module as Module):
		return module.FullName.Replace("-", "_") + "Module"

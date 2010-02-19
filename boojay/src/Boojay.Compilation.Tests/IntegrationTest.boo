namespace Boojay.Compilation.Tests

import System.IO

import NUnit.Framework from nunit.framework

import Boo.Lang.Parser
import Boo.Lang.Compiler
import Boo.Lang.Compiler.IO
import Boo.Lang.Compiler.Ast
import Boojay.Compilation
import Useful.Attributes

[TestFixture]
partial class IntegrationTest:

	def runTestCase(testFile as string):
		unit = parse(fullpathFor(testFile))	
		main = unit.Modules[0]
		compile(unit)
		output = runJavaClass(moduleClassFor(main))
		Assert.IsNotNull(main.Documentation, "Expecting documentation for '${testFile}'")
		Assert.AreEqual(normalizeWhiteSpace(main.Documentation), normalizeWhiteSpace(output))
		
	def fullpathFor(testFile as string):
		return Path.Combine(testParentFolder(), testFile)
		
	def binFolder():
		return Path.GetFullPath(Path.Combine(testParentFolder(), "bin"))
		
	def distFolder():
		return Path.GetFullPath(Path.Combine(testParentFolder(), "dist"))
		
	[once]
	def testParentFolder():
		folder = "."
		while not Directory.Exists(Path.Combine(folder, "tests")):
			folder = Path.Combine(folder, "..")
			assert Directory.Exists(folder)
		return folder
		
	def normalizeWhiteSpace(s as string):
		return s.Trim().Replace("\r\n", "\n")
		
	def parse(fname as string):
		return BooParser.ParseFile(System.IO.Path.GetFullPath(fname))
		
	def moduleClassFor(module as Module):
		return module.FullName.Replace("-", "_") + "Module"
		
	def runJavaClass(className as string):
		p = shellp("java", "-cp .:${binFolder()}:${distFolder()} ${className}")
		p.WaitForExit()
		if p.ExitCode != 0: raise p.StandardError.ReadToEnd()
		return p.StandardOutput.ReadToEnd()

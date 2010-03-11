namespace Boojay.Compilation.Tests

import System.IO

import Boo.Lang.Compiler.Ast

import Boojay.Compilation

[TestFixture]
partial class IntegrationTest(CommonIntegrationTest):

	override def compileTest(unit as CompileUnit):
		compile(unit)
		
	override def runTest(main as Module):
		return runJavaClass(moduleClassFor(main))
				
	def runJavaClass(className as string):
		classPath = (binFolder(), distFolder() + "/boojay.lang.jar")
		
		p = shellp("java", "-cp ${join(classPath, Path.PathSeparator)} ${className}")
		p.WaitForExit()
		if p.ExitCode != 0: raise p.StandardError.ReadToEnd()
		return p.StandardOutput.ReadToEnd()

	def binFolder():
		return Path.GetFullPath(Path.Combine(testParentFolder(), "bin"))
		
	def distFolder():
		return Path.GetFullPath(Path.Combine(testParentFolder(), "dist"))

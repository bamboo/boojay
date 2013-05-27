namespace Boojay.Compilation.Tests

import System
import System.IO

import Boo.Lang.Compiler
import Boo.Lang.Compiler.Ast
import Boo.Lang.Compiler.TypeSystem

import Boojay.Compilation
import Boojay.Compilation.TypeSystem

static class JavaClassRunner:
	def run(className as string, *jars as (string)):
		classPath = (ProjectFolders.binFolder(), ProjectFolders.distFolder() + "/boojay.lang.jar") + jars

		exitCode as int, output, error as string = runp("java", "-cp ${quote(join(classPath, Path.PathSeparator))} ${className}")
		
		if exitCode != 0: raise output + "\n" + error
		return output
		
	def runp(filename as string, arguments as string):
		p = System.Diagnostics.Process()
		p.StartInfo.Arguments = arguments
		p.StartInfo.CreateNoWindow = true
		p.StartInfo.UseShellExecute = false
		p.StartInfo.RedirectStandardOutput = true
		p.StartInfo.RedirectStandardInput = true
		p.StartInfo.RedirectStandardError = true
		p.StartInfo.FileName = filename
		
		result = ""
		p.OutputDataReceived += def(sender, e as System.Diagnostics.DataReceivedEventArgs):
			result += e.Data + "\n"
		
		p.Start()
		p.BeginOutputReadLine()
		p.WaitForExit()
		
		exitCode = p.ExitCode
		error = p.StandardError.ReadToEnd()
		
		p.Close()
		
		return (exitCode, result, error)

static class ProjectFolders:
	def binFolder():
		return Path.GetFullPath(Path.Combine(testParentFolder(), "bin"))
		
	def distFolder():
		return Path.GetFullPath(Path.Combine(testParentFolder(), "dist"))

	def testParentFolder():
		folder = "."
		while not Directory.Exists(Path.Combine(folder, "tests")):
			folder = Path.Combine(folder, "..")
			assert Directory.Exists(folder)
		return folder

def generateTempJarWith(code as Module):
	boojayCompile(CompileUnit(code))
	entries = "${type.FullName.Replace('.', '/')}.class" for type in code.Members
	return generateTempJar(entries)

def booCompile(unit as CompileUnit, *refs as (ICompileUnit)):
	compiler = newBooCompiler()
	result = compiler.Run(unit)
	assert 0 == len(result.Errors), result.Errors.ToString(true) + unit.ToCodeString()

def newBooCompiler():
	return BooCompiler(
		CompilerParameters(true,
			OutputType: CompilerOutputType.Auto,
			Pipeline: Boo.Lang.Compiler.Pipelines.CompileToMemory()))

def runTestWithJar(test as Module, jar as Module):
	generatedJar = generateTempJarWith(jar)
	jarCompileUnit = JarTypeSystemProvider().ForJar(generatedJar)
	unit = CompileUnit(test)
	try:
		boojayCompile(unit, jarCompileUnit)
		className = moduleClassFor(test)
		print JavaClassRunner.run(className, Path.GetFullPath(generatedJar))
	except e:
		raise e.ToString() + unit.ToCodeString()

def moduleClassFor(module as Module):
	return module.FullName.Replace("-", "_").Replace("$", "_") + "Module"
	
def quote(arg as string):
	return '"' + arg + '"'


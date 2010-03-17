namespace Boojay.Compilation.Tests

import System
import System.IO
import System.Diagnostics

import Boo.Lang.Compiler
import Boo.Lang.Compiler.Ast
import Boo.Lang.Compiler.TypeSystem

import Boojay.Compilation
import Boojay.Compilation.TypeSystem

static class JavaClassRunner:
	def run(className as string):
		classPath = (ProjectFolders.binFolder(), ProjectFolders.distFolder() + "/boojay.lang.jar")

		exitCode as int, output, error as string = runp("java", "-cp ${join(classPath, Path.PathSeparator)} ${className}")
		
		if exitCode != 0: raise error
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
	jar = Path.GetTempFileName()
	boojayCompile(CompileUnit(code))
	generateJar(jar, "${type.FullName.Replace('.', '/')}.class" for type in code.Members)
	
	return jar

def booCompile(unit as CompileUnit):
	booCompile(unit, List[of ICompileUnit]())

def booCompile(unit as CompileUnit, *refs as (ICompileUnit)):
	compiler = newBooCompiler()
	result = compiler.Run(unit)
	assert 0 == len(result.Errors), result.Errors.ToString(true) + unit.ToCodeString()

def newBooCompiler():
	compiler = BooCompiler(CompilerParameters(true))
	compiler.Parameters.OutputType = CompilerOutputType.Auto
	compiler.Parameters.Pipeline = Boo.Lang.Compiler.Pipelines.CompileToMemory()

	return compiler

def runTestWithJar(test as Module, jar as Module):
	generatedJar = generateTempJarWith(jar)
	jarCompileUnit = JarTypeSystemProvider().ForJar(generatedJar)

	try:
		unit = CompileUnit(test)
		boojayCompile(unit, jarCompileUnit)
		className = moduleClassFor(test)
		print JavaClassRunner.run(className)
	except e:
		print e.ToString() + unit.ToCodeString()

def moduleClassFor(module as Module):
	return module.FullName.Replace("-", "_").Replace("$", "_") + "Module"


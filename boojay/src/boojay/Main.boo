namespace boojay

import System
import System.Reflection
import System.Diagnostics
import System.IO as SysIO
import Boo.Lang.Compiler
import Boo.Lang.Compiler.IO
import Boojay.Compilation from Boojay.Compilation
import Boojay.Compilation.TypeSystem from Boojay.Compilation

import java.io
import java.util.zip

def loadAssembly(name as string):
	if SysIO.File.Exists(name):
		return Assembly.LoadFrom(name)
	return Assembly.Load(name)

def loadJar(name as string):
	return JarTypeSystemProvider().ForJar(name) if SysIO.File.Exists(name)
	raise Exception("Can' load library ${name}")
	
def parseCommandLine(argv as (string)):
	try:
		cmdLine = CommandLine(argv)
		if (not cmdLine.IsValid) or cmdLine.DoHelp:
			cmdLine.PrintOptions()
			return null
		return cmdLine
	except x:
		print "BCE000: ", x.Message
		return null

def selectPipeline(cmdLine as CommandLine):
	return (BoojayPipelines.ProduceBoo() if cmdLine.Boo else BoojayPipelines.ProduceBytecode())
	
def configureParams(cmdLine as CommandLine, params as CompilerParameters):
	for fname in cmdLine.SourceFiles():
		if cmdLine.Verbose: print fname
		params.Input.Add(FileInput(fname))
		
	for reference in cmdLine.References:
		params.References.Add(loadAssembly(reference))
	
	for classpath in retrieveJars(cmdLine.Classpaths):
		params.References.Add(loadJar(classpath))

	params.OutputAssembly = getOutputDirectory(cmdLine)
	if cmdLine.DebugCompiler:
		params.EnableTraceSwitch()
		params.TraceLevel = System.Diagnostics.TraceLevel.Verbose
		Trace.Listeners.Add(TextWriterTraceListener(System.Console.Error))

def retrieveJars(classpaths as List[of string]):
	for classpath in classpaths:
		if classpath.EndsWith(".jar"):
			yield classpath
		else:
			if SysIO.Directory.Exists(classpath):
				for jar in SysIO.Directory.GetFiles(classpath, "*.jar"):
					yield SysIO.Path.Combine(classpath, jar)
			else:
				print "Can' locate classpath: ${classpath}"

def showErrorsWarnings(cmdLine as CommandLine, result as CompilerContext):
	for error in result.Errors:
		print error.ToString(cmdLine.Verbose)
	for warning in result.Warnings:
		print warning
	
def outputJarFile(cmdLine as CommandLine, temporaryDirectory as string, result as CompilerContext):
	if result.Errors.Count == 0 and isJar(cmdLine.OutputDirectory):
		generateJar(cmdLine.OutputDirectory, temporaryDirectory, result["GeneratedClassFiles"])

def getOutputDirectory(cmdLine as CommandLine):
	return (SysIO.Path.GetTempPath() if isJar(cmdLine.OutputDirectory) else cmdLine.OutputDirectory)

def isJar(path as string):
	return path.EndsWith(".jar")

def generateJar(outputJar as string, temporaryDir as string, files as List):
	return unless files
	manifest = createManifest(temporaryDir)
	
	zos = ZipOutputStream(fos = FileOutputStream(outputJar))

	for name as string in files + [manifest]:
		zos.putNextEntry(ZipEntry(name.RemoveStart(temporaryDir)))
		zos.write(System.IO.File.ReadAllBytes(name))
		zos.closeEntry()

	zos.close()
	fos.close()

def createManifest(baseDir as string):
	filename = SysIO.Path.Combine(baseDir, "META-INF/MANIFEST.MF")
	SysIO.Directory.CreateDirectory(SysIO.Path.GetDirectoryName(filename))
	using file = SysIO.File.CreateText(filename):
		file.WriteLine("Manifest-Version: 1.0")
	return filename

[extension]
def RemoveStart(value as string, start as string):
	return value unless value.StartsWith(start)
	return value[start.Length:]

print "boojay .0a"

cmdLine = parseCommandLine(argv)
if cmdLine is null: return

compiler = newBoojayCompiler(selectPipeline(cmdLine))
configureParams(cmdLine, compiler.Parameters)

result = compiler.Run()

showErrorsWarnings(cmdLine, result)
outputJarFile(cmdLine, compiler.Parameters.OutputAssembly, result)

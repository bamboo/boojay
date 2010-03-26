namespace boojay

import System
import System.Reflection
import System.Diagnostics
import System.IO
import Boo.Lang.Compiler.IO
import Boojay.Compilation from Boojay.Compilation
import Boojay.Compilation.TypeSystem from Boojay.Compilation

def loadAssembly(name as string):
	if File.Exists(name):
		return Assembly.LoadFrom(name)
	return Assembly.Load(name)

def loadJar(name as string):
	return JarTypeSystemProvider().ForJar(name) if File.Exists(name)
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
	return (BoojayPipelines.ProduceBoo() if cmdLine.Boo else BoojayPipelines.ProduceBytecode(cmdLine.JarPack))

print "boojay .0a"

cmdLine = parseCommandLine(argv)
if cmdLine is null: return

compiler = newBoojayCompiler(selectPipeline(cmdLine))
params = compiler.Parameters

for fname in cmdLine.SourceFiles():
	if cmdLine.Verbose: print fname
	params.Input.Add(FileInput(fname))
	
for reference in cmdLine.References:
	params.References.Add(loadAssembly(reference))
	
for classpath in cmdLine.Classpaths:
	params.References.Add(loadJar(classpath)) // what now ??
	
params.OutputAssembly = cmdLine.OutputDirectory
if cmdLine.DebugCompiler:
	params.EnableTraceSwitch()
	params.TraceLevel = System.Diagnostics.TraceLevel.Verbose
	Trace.Listeners.Add(TextWriterTraceListener(Console.Error))

result = compiler.Run()
for error in result.Errors:
	print error.ToString(cmdLine.Verbose)
for warning in result.Warnings:
	print warning

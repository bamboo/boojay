namespace Boojay.Compilation

import Boo.Lang.Environments
import Boo.Lang.Compiler
import Boo.Lang.Compiler.TypeSystem
import Boojay.Compilation.TypeSystem
import java

def newBoojayCompiler():
	return newBoojayCompiler(BoojayPipelines.ProduceBytecode())

def newBoojayCompiler(pipeline as CompilerPipeline):
	parameters = newBoojayCompilerParameters()
	parameters.Pipeline = pipeline
	return BooCompiler(parameters)

def newBoojayCompilerParameters():
	parameters = CompilerParameters(JavaReflectionTypeSystemProvider.SharedTypeSystemProvider, true)
	parameters.References.Add(typeof(lang.Object).Assembly)
	parameters.References.Add(typeof(Boojay.Macros.PrintMacro).Assembly)
	parameters.References.Add(typeof(Boojay.Lang.BuiltinsModule).Assembly)
	parameters.Environment = DeferredEnvironment() {
		TypeSystemServices: { JavaTypeSystem() }
	}
	return parameters

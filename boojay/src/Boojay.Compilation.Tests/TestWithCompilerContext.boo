namespace Boojay.Compilation.Tests

import Boo.Lang.Compiler
import Boojay.Compilation

class TestWithCompilerContext:
	
	context = CompilerContext(newBoojayCompilerParameters())

	def WithCompilerContext(block as callable()):
		context.Run(block)

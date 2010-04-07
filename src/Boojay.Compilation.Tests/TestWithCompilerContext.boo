namespace Boojay.Compilation.Tests

import Boo.Lang.Compiler
import Boojay.Compilation

import NUnit.Framework

class TestWithCompilerContext:
	
	context as CompilerContext
	
	[SetUp]
	virtual def SetUp():
		context = CompilerContext(newBoojayCompilerParameters())

	def WithCompilerContext(block as callable()):
		context.Run(block)

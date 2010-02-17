namespace Boojay.Compilation.Tests

import System
import Boojay.Compilation
import Boo.Lang.Compiler.Ast

def compile(unit as CompileUnit):
	compiler = newBoojayCompiler()
	result = compiler.Run(unit)
	assert 0 == len(result.Errors), result.Errors.ToString(true) + unit.ToCodeString()
		

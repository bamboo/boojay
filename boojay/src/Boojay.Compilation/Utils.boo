namespace Boojay.Compilation

import Boo.Lang.Compiler.Ast
import Boo.Lang.Compiler.TypeSystem

def boojayCompile(unit as CompileUnit):
	boojayCompile(unit, List[of ICompileUnit]())

def boojayCompile(unit as CompileUnit, jars as List[of ICompileUnit]):
	compiler = newBoojayCompiler()
	result = compiler.Run(unit)
	assert 0 == len(result.Errors), result.Errors.ToString(true) + unit.ToCodeString()

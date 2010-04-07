namespace Boojay.Compilation

import Boo.Lang.Compiler.Ast
import Boo.Lang.Compiler.TypeSystem

def boojayCompile(unit as CompileUnit, *jars as (ICompileUnit)):
	compiler = newBoojayCompiler()
	compiler.Parameters.References.AddAll(jars)
	result = compiler.Run(unit)
	assert 0 == len(result.Errors), result.Errors.ToString(true) + unit.ToCodeString()

def log(message as string):
	using f = System.IO.File.AppendText("/tmp/boojay.txt"):
		f.WriteLine(message)

namespace Boojay.Compilation.Tests

import System
import System.IO

import Boo.Lang.Compiler
import Boo.Lang.Compiler.Ast

import Boojay.Compilation

def generateTempJarWith(code as Module):
	jar = Path.GetTempFileName()
	boojayCompile(CompileUnit(code))
	generateJar(jar, "${type.FullName.Replace('.', '/')}.class" for type in code.Members)
	
	return jar

def boojayCompile(unit as CompileUnit):
	compile(unit, newBoojayCompiler)

def booCompile(unit as CompileUnit):
	compile(unit, newBooCompiler)

def compile(unit as CompileUnit, block as callable() as BooCompiler):
	compiler = block()
	result = compiler.Run(unit)
	assert 0 == len(result.Errors), result.Errors.ToString(true) + unit.ToCodeString()
	
def newBooCompiler():
	compiler = BooCompiler(CompilerParameters(true))
	compiler.Parameters.OutputType = CompilerOutputType.Auto
	compiler.Parameters.Pipeline = Boo.Lang.Compiler.Pipelines.CompileToMemory()
	
	return compiler

def runTestWithJar(test as Module, jar as Module):
	pass

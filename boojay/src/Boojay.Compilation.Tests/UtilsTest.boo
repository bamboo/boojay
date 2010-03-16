namespace Boojay.Compilation.Tests

import System.IO
import NUnit.Framework

import Boo.Lang.Compiler.Ast

import Boojay.Compilation
import Boojay.Compilation.TypeSystem

[TestFixture]
class UtilsTest(TestWithCompilerContext):
	
	[Test] def SimpleCompile():
		simpleCompileTest = [|
			import java.lang
			
			class Foo:
				pass
		|]
		
		RemoveClasses(simpleCompileTest)

		boojayCompile(CompileUnit(simpleCompileTest))
		
		Assert.AreEqual(1, len(simpleCompileTest.Members))
		
		AssertClassesGeneration(simpleCompileTest)
		
	[Test] def CompileWithJars():
		compileWithJarsTest = [|
			import java.lang
			
			class Foo:
				def getBarName():
					Bar().getName()
		|]
		
		library = [|
			import java.lang
			
			class Bar:
				def getName():
					return "Bar"
		|]
		
		generatedJar = generateTempJarWith(library)
		jarCompileUnit = JarTypeSystemProvider().ForJar(generatedJar)

		RemoveClasses(compileWithJarsTest)

		boojayCompile(CompileUnit(compileWithJarsTest), jarCompileUnit)
		
		Assert.AreEqual(1, len(compileWithJarsTest.Members))

		AssertClassesGeneration(compileWithJarsTest)
		
	private def RemoveClasses(unit as Module):
		for type in unit.Members:
			className = "${type.FullName.Replace('.', '/')}.class"
			File.Delete(className) if File.Exists(className)
		
	private def AssertClassesGeneration(unit as Module):
		for type in unit.Members:
			className = "${type.FullName.Replace('.', '/')}.class"
			Assert.IsTrue(File.Exists(className), "File does not exists: ${className}")
		
			
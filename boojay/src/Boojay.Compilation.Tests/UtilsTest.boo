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
		
		for type in simpleCompileTest.Members:
			className = "${type.FullName.Replace('.', '/')}.class"
			File.Delete(className) if File.Exists(className)

		boojayCompile(CompileUnit(simpleCompileTest))
		
		Assert.AreEqual(1, len(simpleCompileTest.Members))
		
		for type in simpleCompileTest.Members:
			className = "${type.FullName.Replace('.', '/')}.class"
			Assert.IsTrue(File.Exists(className), "File does not exists: ${className}")

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

		for type in compileWithJarsTest.Members:
			className = "${type.FullName.Replace('.', '/')}.class"
			File.Delete(className) if File.Exists(className)

		boojayCompile(CompileUnit(compileWithJarsTest), jarCompileUnit)
		
		Assert.AreEqual(1, len(compileWithJarsTest.Members))
		
		for type in compileWithJarsTest.Members:
			className = "${type.FullName.Replace('.', '/')}.class"
			Assert.IsTrue(File.Exists(className), "File does not exists: ${className}")
		
			
namespace Boojay.Compilation.Tests

import System
import System.IO
import NUnit.Framework

import Boo.Lang.Compiler
import Boo.Lang.Compiler.Ast
import Boo.Lang.Compiler.TypeSystem
import Boo.Lang.Compiler.TypeSystem.Services

import Boojay.Compilation.TypeSystem

[TestFixture]
class JarTypeSystemProviderTest(TestWithCompilerContext):
	
	_jar as string
	_subject as JarTypeSystemProvider
	
	[SetUp]
	override def SetUp():
		super()
		
		code = [|
			import java.lang
			
			class Foo:
				def getName():
					return "Bar"
		|]
		
		_jar = GenerateTempJarWith(code)
		_subject = JarTypeSystemProvider()
	
	[Test]
	def ClassName():
		
		WithCompilerContext:
			
			compileUnit = _subject.ForJar(_jar)
			foo = ResolveType(compileUnit, "Foo")
			assert "Foo" == foo.Name
			
	[Test]
	def ClassesAreCached():
		
		WithCompilerContext:
			
			compileUnit = _subject.ForJar(_jar)
			resolveFoo = { ResolveType(compileUnit, "Foo") }
			Assert.AreSame(resolveFoo(), resolveFoo())
			
	[Test]
	def ParameterlessInstanceMethod():
		
		WithCompilerContext:
			
			compileUnit = _subject.ForJar(_jar)
			getName as IMethod = ResolveQualifiedName(compileUnit, "Foo.getName")
			Assert.AreEqual(EntityType.Method, getName.EntityType)
			Assert.AreEqual("getName", getName.Name)
			Assert.AreEqual("Foo.getName", getName.FullName)
			Assert.AreSame(ResolveType(compileUnit, "Foo"), getName.DeclaringType)
			Assert.AreEqual(0, getName.GetParameters().Length)	
		
	def ResolveType(compileUnit as ICompileUnit, typeName as string) as IType:
		return ResolveQualifiedName(compileUnit, typeName)
		
	def ResolveQualifiedName(compileUnit as ICompileUnit, typeName as string):
		return my(NameResolutionService).ResolveQualifiedName(compileUnit.RootNamespace, typeName)
		
	def GenerateTempJarWith(code as Module):
		jar = Path.GetTempFileName()
		compile(CompileUnit(code))
		GenerateJar(jar, "${type.Name}.class" for type in code.Members)
		return jar
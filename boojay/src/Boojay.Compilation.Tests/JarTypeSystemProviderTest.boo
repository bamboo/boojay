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
	_jarWithNamespace as string
	_jarWithComplexNamespace as string
	
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
		
		codeWithNamespace = [|
			namespace Foo
			
			import java.lang
			
			class Bar:
				def getName():
					return "Baz"
		|]
		
		codeWithComplexNamespace = [|
			namespace Foo.More
			
			import java.lang
			
			class Bar:
				def getName():
					return "Baz"
		|]
		
		_jar = generateTempJarWith(code)
		_jarWithNamespace = generateTempJarWith(codeWithNamespace)
		_jarWithComplexNamespace = generateTempJarWith(codeWithComplexNamespace)
		
		_subject = JarTypeSystemProvider()
	
	[Test]
	def ClassName():
		
		WithCompilerContext:
			
			compileUnit = _subject.ForJar(_jar)
			foo = ResolveType(compileUnit, "Foo")
			Assert.AreEqual("Foo", foo.Name)
			
	[Test]
	def ClassNameInNamespace():
		
		WithCompilerContext:
			
			compileUnit = _subject.ForJar(_jarWithNamespace)
			bar = ResolveType(compileUnit, "Foo.Bar")
			Assert.AreEqual("Bar", bar.Name)
			Assert.AreEqual("Foo.Bar", bar.FullName)
			
	[Test]
	def ClassNameInComplexNamespace():
		
		WithCompilerContext:
			
			compileUnit = _subject.ForJar(_jarWithComplexNamespace)
			bar = ResolveType(compileUnit, "Foo.More.Bar")
			Assert.AreEqual("Bar", bar.Name)
			Assert.AreEqual("Foo.More.Bar", bar.FullName)

	[Test]
	def ClassesAreCached():
		
		WithCompilerContext:
			
			compileUnit = _subject.ForJar(_jar)
			resolveFoo = { ResolveType(compileUnit, "Foo") }
			Assert.AreSame(resolveFoo(), resolveFoo())
			
	[Test]
	def SimpleConstructor():
		WithCompilerContext:
			
			compileUnit = _subject.ForJar(_jar)
			foo = ResolveType(compileUnit, "Foo")
			Assert.AreEqual(1, len(foo.GetConstructors()))
			ctor = foo.GetConstructors()[0]
			Assert.AreEqual(0, len(ctor.GetParameters()))
			
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

namespace Boojay.Compilation.Tests

import System
import NUnit.Framework

import Environments
import Compiler.TypeSystem
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
			
			ctors = Boo.Lang.List[of IConstructor](foo.GetConstructors())
			Assert.AreEqual(1, len(ctors))
			ctor = ctors[0]
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
			
	[Test]
	def JarInterface():
		code = [|
			namespace Jar.Interfaces
			
			interface IFoo:
				pass
		|]
		jar = generateTempJarWith(code)
		WithCompilerContext:
			type = _subject.ForJar(jar).ResolveQualifiedName("Jar.Interfaces.IFoo") as IType
			assert type is not null
			assert type.IsInterface
		
	[Test]
	def JarConstructorWithParameters():
		code = [|
			namespace Jar.Constructors
			
			class Foo:
				def constructor(s as string):
					pass
		|]
		jar = generateTempJarWith(code)
		WithCompilerContext:
			type = _subject.ForJar(jar).ResolveQualifiedName("Jar.Constructors.Foo") as IType
			ctors = array(type.GetConstructors())
			Assert.AreEqual(1, len(ctors))
			parameters = ctors[0].CallableType.GetSignature().Parameters
			Assert.AreEqual(1, len(parameters))
			Assert.AreSame(my(TypeSystemServices).StringType, parameters[0].Type)
	
	def ResolveType(compileUnit as ICompileUnit, typeName as string) as IType:
		return compileUnit.ResolveQualifiedName(typeName)


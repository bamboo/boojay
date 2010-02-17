namespace Boojay.Compilation.Tests

import System
import System.IO
import NUnit.Framework

import Boo.Lang.Compiler
import Boo.Lang.Compiler.Ast
import Boo.Lang.Compiler.TypeSystem

import Boojay.Compilation.TypeSystem

[TestFixture]
class JarTypeSystemProviderTest(TestWithCompilerContext):
	
	[Test]
	def SingleClassJar():
		
		WithCompilerContext:
			
			code = [|
				import java.lang
				
				class Foo:
					pass
			|]
			
			jar = GenerateTempJarWith(code)
			compileUnit = JarTypeSystemProvider().ForJar(jar)
			
			result = List[of IEntity]()
			assert compileUnit.RootNamespace.Resolve(result, "Foo", EntityType.Type)
			assert len(result) == 1
			assert "Foo" == result[0].Name
		
	def GenerateTempJarWith(code as Module):
		jar = Path.GetTempFileName()
		compile(CompileUnit(code))
		GenerateJar(jar, "${type.Name}.class" for type in code.Members)
		return jar
namespace Boojay.Compilation.Tests

import Environments
import Compiler.TypeSystem
import Compiler.TypeSystem.Services

[Extension]		
def ResolveQualifiedName(compileUnit as ICompileUnit, typeName as string):
	return my(NameResolutionService).ResolveQualifiedName(compileUnit.RootNamespace, typeName)

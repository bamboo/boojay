namespace Boojay.Compilation.Steps

import Boo.Lang.Compiler.Steps
import Boo.Lang.Compiler.TypeSystem.Core

class IntroduceBoojayNamespaces(IntroduceGlobalNamespaces):
	override def Run():
		NameResolutionService.Reset()
		NameResolutionService.GlobalNamespace = NamespaceDelegator(
			NameResolutionService.GlobalNamespace,
			SafeGetNamespace("Boojay.Macros"),
			SafeGetNamespace("Boojay.Lang"))

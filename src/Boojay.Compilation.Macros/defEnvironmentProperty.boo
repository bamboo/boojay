namespace Boo.Lang.Environments

import Compiler.Ast

macro defEnvironmentProperty:
	
	case [| defEnvironmentProperty $(ReferenceExpression(Name: name)) |]:
		fieldName = ReferenceExpression("\$$name")
		yield [|
			private final $fieldName = EnvironmentProvision of $name()
		|]
		yield [|
			private $name:
				get: return $fieldName.Instance
		|]
	
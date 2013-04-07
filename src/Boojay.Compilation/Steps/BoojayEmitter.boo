namespace Boojay.Compilation.Steps

import System.IO

import Boo.Lang.Compiler
import Boo.Lang.Compiler.Ast
import Boo.Lang.Compiler.Steps
import Boo.Lang.Compiler.TypeSystem
import Boo.Lang.Compiler.TypeSystem.Internal

import Boo.Lang.PatternMatching

import org.objectweb.asm
import org.objectweb.asm.Type

import Boojay.Compilation.TypeSystem

class BoojayEmitter(AbstractVisitorCompilerStep):
		
	_classVisitor as ClassVisitor
	_code as MethodVisitor
	_currentMethod as Method
	_typeMappings as Hash
	_primitiveMappings as Hash
	
	override def Initialize(context as CompilerContext):
		super(context)		
		initializeTypeMappings()
		
	def Run():
		if len(Errors) > 0:
			return
		Visit(CompileUnit)
		
	def initializeTypeMappings():
		_typeMappings = {
			typeSystem.ObjectType: "java/lang/Object",
			Null.Default: "java/lang/Object",
			typeSystem.StringType: "java/lang/String",
			typeSystem.ICallableType: "Boojay/Lang/Callable",
			typeSystem.TypeType: "java/lang/Class",
			typeSystem.IEnumerableType: "Boojay/Lang/Enumerable",
			typeSystem.IEnumerableGenericType: "Boojay/Lang/Enumerable",
			typeSystem.IEnumeratorType: "Boojay/Lang/Enumerator",
			typeSystem.IEnumeratorGenericType: "Boojay/Lang/Enumerator",
			typeSystem.Map(typeof(Boo.Lang.GenericGenerator[of*])): "Boojay/Lang/Generator",
			typeSystem.Map(typeof(Boo.Lang.GenericGeneratorEnumerator[of*])): "Boojay/Lang/GeneratorEnumerator",
			typeSystem.RuntimeServicesType: "Boojay/Lang/RuntimeServices",
			typeSystem.Map(System.Exception): "java/lang/Exception",
			typeSystem.Map(System.IDisposable): "Boojay/Lang/Disposable",
			typeSystem.Map(System.ICloneable): "java/lang/Cloneable",
		}
		
		_primitiveMappings = {
			typeSystem.CharType: CHAR_TYPE.getDescriptor(),
			typeSystem.BoolType: BOOLEAN_TYPE.getDescriptor(),
			typeSystem.IntType: INT_TYPE.getDescriptor(),
			typeSystem.VoidType: VOID_TYPE.getDescriptor(),
		}
		
	override def OnInterfaceDefinition(node as InterfaceDefinition):
		emitTypeDefinition node
	
	override def OnClassDefinition(node as ClassDefinition):
		emitTypeDefinition node
		
	def emitTypeDefinition(node as TypeDefinition):
		classWriter = ClassWriter(ClassWriter.COMPUTE_MAXS)
		_classVisitor = classWriter
		_classVisitor.visit(
			Opcodes.V1_5,
			typeAttributes(node),
			javaType(bindingFor(node)), 
			null,
			javaType(baseType(node)),
			implementedInterfaces(node))
			
		if node.ParentNode isa ClassDefinition:
			_classVisitor.visitInnerClass(javaType(bindingFor(node)), javaType(bindingFor(node.ParentNode)), node.Name, Opcodes.ACC_STATIC)
		
		preservingClassWriter:
			emitSourceInformationFor node
			emitFieldsFrom node
			emitNonFieldsFrom node
		
		_classVisitor.visitEnd()
		
		writeClassFileFor node, classWriter.toByteArray()
		
	def emitSourceInformationFor(node as Node):
		sourceFile = node.LexicalInfo.FileName
		if string.IsNullOrEmpty(sourceFile):
			return
			
		_classVisitor.visitSource(sourceFile, null)
		
	def emitFieldsFrom(node as TypeDefinition):
		for member in node.Members:
			emit member if member.NodeType == NodeType.Field
			
	def emitNonFieldsFrom(node as TypeDefinition):
		for member in node.Members:
			emit member if member.NodeType != NodeType.Field
		
	def preservingClassWriter(code as callable()):
		previousClassWriter = _classVisitor
		code()
		_classVisitor = previousClassWriter
		
	def implementedInterfaces(node as TypeDefinition):
		interfaces = array(
				javaType(itf)
				for itf in node.BaseTypes
				if isInterface(itf))
		if len(interfaces) == 0: return null
		return interfaces
		
	def isInterface(typeRef as TypeReference):
		return typeBinding(typeRef).IsInterface
		
	def typeBinding(node as Node) as IType:
		return bindingFor(node)
		
	def typeAttributes(node as TypeDefinition):
		attrs = 0
		match node.NodeType:
			case NodeType.ClassDefinition:
				attrs += Opcodes.ACC_SUPER
				if node.IsAbstract: attrs += Opcodes.ACC_ABSTRACT
			case NodeType.InterfaceDefinition:
				attrs += (Opcodes.ACC_INTERFACE + Opcodes.ACC_ABSTRACT)
		attrs += Opcodes.ACC_PUBLIC
		return attrs
		
	def writeClassFileFor(node as TypeDefinition, bytecode as (byte)):
		fname = Path.Combine(outputDirectory(), classFullFileName(node))
		ensurePath(fname)
		File.WriteAllBytes(fname, bytecode)
		addFilenameToContext(fname)
#		verify bytecode

	private def addFilenameToContext(filename as string):
		key = "GeneratedClassFiles"
		Context[key] = [] unless Context[key]
		filenames = cast(List, Context[key])
		filenames.Add(filename)
		
	def verify(bytecode as (byte)):
		org.objectweb.asm.util.CheckClassAdapter.verify(ClassReader(bytecode), false, java.io.PrintWriter(java.lang.System.err))
		
	def outputDirectory():
		return Parameters.OutputAssembly
		
	override def OnLabelStatement(node as LabelStatement):
		
		emitDebuggingInfoFor node
		
		mark labelFor(node)
		
	override def OnGotoStatement(node as GotoStatement):
		
		emitDebuggingInfoFor node
		
		GOTO labelFor(node.Label)
		
	override def OnIfStatement(node as IfStatement):
		
		emitDebuggingInfoFor node
		
		elseLabel = Label()
		afterElseLabel = Label()
		
		emitBranchFalse node.Condition, elseLabel
		emit node.TrueBlock
		if node.FalseBlock is not null:
			GOTO afterElseLabel				
		mark elseLabel
		if node.FalseBlock is not null:		
			emit node.FalseBlock		
			mark afterElseLabel

	def emitBranchFalse(e as Expression, label as Label):
		match e:
			case [| not $condition |]:
				emitBranchTrue condition, label
			otherwise:
				emitCondition e
				IFEQ label
				
	def emitBranchTrue(e as Expression, label as Label):
		match e:
			case [| not $condition |]:
				emitBranchFalse condition, label
				
			case [| $l < $r |]:
				emit l
				emit r
				IF_ICMPLT label
				
			otherwise:
				emitCondition e
				IFNE label
				
	def emitCondition(e as Expression):
		emit e
		ensureBool typeOf(e)
		
	override def OnModule(node as Module):
		emit node.Members
	
	override def OnWhileStatement(node as WhileStatement):
		
		emitDebuggingInfoFor node
		
		testLabel = Label()
		bodyLabel = Label()
		GOTO testLabel
		mark bodyLabel
		emit node.Block
		mark testLabel
		emitBranchTrue node.Condition, bodyLabel
		
	override def OnField(node as Field):
		field = _classVisitor.visitField(
					memberAttributes(node),
					node.Name,
					typeDescriptor(bindingFor(node.Type)),
					null,
					null)
		field.visitEnd() 
		
	override def OnConstructor(node as Constructor):
		ctorName = ("<clinit>" if node.IsStatic else "<init>")
		emitMethod ctorName, node
		
	_methodMappings = {
		".ctor": "<init>",
		"constructor": "<init>",
		"Main": "main",
		"ToString": "toString",
		"Equals": "equals",
		"GetType": "getClass"
	}
	
	override def OnMethod(node as Method):
		emitMethod methodName(node.Name), node
	
	def methodName(name as string):
		return _methodMappings[name] or name
		
	def emitMethod(methodName as string, node as Method):
		_code = _classVisitor.visitMethod(
					memberAttributes(node),
					methodName,
					javaSignature(node),
					null,
					null)
					
		if not node.IsAbstract:
			_currentMethod = node
			emitMethodBody node
			
		_code.visitEnd()
		
	def emitMethodBody(node as Method):
		prepareLocalVariables node
		
		_code.visitCode()
		
		beginLabel = Label()
		mark beginLabel
		
		emitLocalVariableInitializationFor node
		
		emit node.Body
		if node.Body.Statements.Count == 0 or not node.Body.Statements[-1] isa ReturnStatement:
			emitEmptyReturn
		RETURN
		
		endLabel = Label()
		mark endLabel

		emitDebuggingInfoForLocalVariablesOf node, beginLabel, endLabel
		_code.visitMaxs(0, 0)
	
	def emitLocalVariableInitializationFor(node as Method):
		// TODO: Optimize using flow analysis
		for local in node.Locals:
			binding as ILocalEntity = bindingFor(local)
			if binding.Type.IsValueType:
				ICONST_0
			else:
				ACONST_NULL
			emitStore binding
		
	def emitDebuggingInfoForLocalVariablesOf(node as Method, beginLabel as Label, endLabel as Label):
		emitDebuggingInfoForImplicitSelfVariable node, beginLabel, endLabel
		for param in node.Parameters:
			paramBinding as InternalParameter = bindingFor(param)
			_code.visitLocalVariable(paramBinding.Name, typeDescriptor(paramBinding.Type), null, beginLabel, endLabel, paramBinding.Index)
		for local in node.Locals:
			binding as ILocalEntity = bindingFor(local)
			_code.visitLocalVariable(binding.Name, typeDescriptor(binding.Type), null, beginLabel, endLabel, index(binding))
		
	def emitDebuggingInfoForImplicitSelfVariable(node as Method, beginLabel, endLabel):
		if node.IsStatic: return
		_code.visitLocalVariable("self", typeDescriptor(bindingFor(node.DeclaringType)), null, beginLabel, endLabel, 0)
		
	def currentReturnType() as IType:
		returnType = _currentMethod.ReturnType
		if returnType is null: return typeSystem().VoidType
		return bindingFor(returnType)
		
	def emitEmptyReturn():
		returnType = currentReturnType()
		if returnType is typeSystem().VoidType:
			RETURN
			return
		
		if returnType.IsValueType:
			ICONST_0
			IRETURN
		else:
			ACONST_NULL
			ARETURN
		
	def memberAttributes(node as TypeMember):
		attributes = Opcodes.ACC_PUBLIC
		if node.IsStatic: attributes += Opcodes.ACC_STATIC
		if node.IsAbstract: attributes += Opcodes.ACC_ABSTRACT
		return attributes
		
	def prepareLocalVariables(node as Method):
		i = firstLocalIndex(node)
		for local in node.Locals:
			index(local, i)
			++i
			
	def firstLocalIndex(node as Method):
		if 0 == len(node.Parameters):
			if node.IsStatic: return 0
			return 1
		return lastParameterIndex(node) + 1
		
	def lastParameterIndex(node as Method):
		param as InternalParameter = bindingFor(node.Parameters[-1])
		return param.Index
		
	def newTemp(type as IType):
		localIndex = nextLocalIndex()
		local = CodeBuilder.DeclareTempLocal(self._currentMethod, type)
		index local.Local, localIndex
		return local
		
	def nextLocalIndex():
		locals = _currentMethod.Locals
		if len(locals) == 0: return firstLocalIndex(_currentMethod)
		return index(bindingFor(locals[-1])) + 1
			
	def index(node as Local, index as int):
		node["index"] = index
		
	def index(bindingFor as InternalLocal) as int:
		return bindingFor.Local["index"]
		
	override def EnterExpressionStatement(node as ExpressionStatement):
		emitDebuggingInfoFor node
		return true
		
	override def LeaveExpressionStatement(node as ExpressionStatement):
		discardValueOnStack node.Expression
		
	def emitDebuggingInfoFor(node as Node):
		if not node.LexicalInfo.IsValid:
			return
			
		label = Label()
		mark label
		_code.visitLineNumber(node.LexicalInfo.Line, label)
		
	def discardValueOnStack(node as Expression):
		mie = node as MethodInvocationExpression
		if mie is null: return
		
		m = bindingFor(mie.Target) as IMethod
		if m is null: return
		
		if hasReturnValue(m): POP
		
	def hasReturnValue(m as IMethod):
		return m.ReturnType is not TypeSystemServices.VoidType
		
	override def OnNullLiteralExpression(node as NullLiteralExpression):
		ACONST_NULL
		
	override def OnReturnStatement(node as ReturnStatement):

		emitDebuggingInfoFor node
		
		if node.Expression is null:
			emitEmptyReturn
		else:
			emit node.Expression
			if isReferenceType(node.Expression):
				ARETURN
			else:
				IRETURN
				
	def isReferenceType(e as Expression):
		return not typeOf(e).IsValueType
		
	override def OnMethodInvocationExpression(node as MethodInvocationExpression):
		match bindingFor(node.Target):
			case ctor = IConstructor():
				emitConstructorInvocation ctor, node
			case method = IMethod():
				emitMethodInvocation method, node
			case builtin = BuiltinFunction():
				emitBuiltinInvocation builtin, node
				
	def emitSuperMethodInvocation(method as IMethod, node as MethodInvocationExpression):
		ALOAD 0
		emit node.Arguments
		INVOKESPECIAL method
				
	def emitConstructorInvocation(ctor as IConstructor, node as MethodInvocationExpression):
		match node.Target:
			case SuperLiteralExpression():
				ALOAD 0
				emit node.Arguments
				INVOKESPECIAL ctor
			otherwise:
				emitObjectCreation ctor, node
				
	def emitBuiltinInvocation(builtin as BuiltinFunction, node as MethodInvocationExpression):
		match builtin.FunctionType:
			case BuiltinFunctionType.Eval:
				emitEval node
			case BuiltinFunctionType.Switch:
				emitSwitch node
				
	def emitSwitch(node as MethodInvocationExpression):
		targetLabels = array(labelFor(arg) for arg in node.Arguments.ToArray()[1:])
		defaultLabel = Label()
		
		emit node.Arguments[0]
		TABLESWITCH 0, len(targetLabels)-1, defaultLabel, targetLabels
		
		mark defaultLabel
		emitObjectCreation defaultConstructorFor(java.lang.IllegalStateException), MethodInvocationExpression()
		ATHROW
		
	def labelFor(e as Expression):
		labelBinding as InternalLabel = bindingFor(e)
		return labelFor(labelBinding.LabelStatement)
		
	def labelFor(stmt as LabelStatement):
		label as Label = stmt["label"]
		if label is null:
			label = Label()
			stmt["label"] = label
		return label
		
	def defaultConstructorFor(type as System.Type):
		return typeSystem().GetDefaultConstructor(typeSystem().Map(type))
				
	def emitEval(node as MethodInvocationExpression):
		for e in node.Arguments.ToArray()[:-1]:
			match e:
				case [| $l = $r |]:
					assert l is not null and r is not null
					emitAssignmentStatement e
				otherwise:
					emit e
					discardValueOnStack e
		emit node.Arguments[-1]
				
	def emitMethodInvocation(method as IMethod, node as MethodInvocationExpression):
		match node.Target:
			case SuperLiteralExpression():
				emitSuperMethodInvocation method, node
			otherwise:
				emitMethodInvocationHandlingSpecialCases method, node
				
	def emitMethodInvocationHandlingSpecialCases(method as IMethod, node as MethodInvocationExpression):
		if isSpecialIkvmGetter(method):
			emitSpecialIkvmGetter(method)
			return
			
		if isArrayLength(method):
			emit node.Target
			ARRAYLENGTH
			return
			
		if handleSpecialStringMethod(method, node):
			return
			
		emitRegularMethodInvocation method, node
		
	def emitRegularMethodInvocation(method as IMethod, node as MethodInvocationExpression):
		emit node.Target
		emit node.Arguments
		emitInvokeMethodInstructionFor method
		
	def emitInvokeMethodInstructionFor(method as IMethod):
		if method.IsStatic:
			INVOKESTATIC method
		elif method.DeclaringType.IsInterface:
			INVOKEINTERFACE method
		else:
			INVOKEVIRTUAL method 	
			
	def handleSpecialStringMethod(method as IMethod, node as MethodInvocationExpression):
		if method.DeclaringType is not typeSystem.StringType:
			return false
			
		match method.Name:
			case "get_Item":
				emit node.Target
				emit node.Arguments
				invokeWithName Opcodes.INVOKEVIRTUAL, method, "charAt"
			case "get_Length":
				emit node.Target
				invokeWithName Opcodes.INVOKEVIRTUAL, method, "length"
			case "IsNullOrEmpty":
				assert len(node.Arguments) == 1
				emit node.Arguments[0]
				ensureBool typeSystem.StringType
			otherwise:
				return false
				
		return true			
			
	def isArrayLength(method as IMethod):
		return method.FullName == "System.Array.get_Length"
		
	def emitObjectCreation(ctor as IConstructor, node as MethodInvocationExpression):
		NEW ctor.DeclaringType
		DUP
		emit node.Arguments
		INVOKESPECIAL ctor
				
	def emitSpecialIkvmGetter(method as IMethod):
	"""
	in the ikvm version of GNU.ClassPath the
	console streams are mapped to properties
	where in java they should be treated as static fields
	"""
		emitLoadStaticField(
			method.DeclaringType,
			stripGetterPrefix(method.Name),
			method.ReturnType)
				
	def isSpecialIkvmGetter(method as IMethod):
		return (method.IsStatic
			and method.DeclaringType.FullName == "java.lang.System"
			and method.Name in ("get_out", "get_in", "get_err"))
			
	override def OnRaiseStatement(node as RaiseStatement):
		if node.Exception is not null:
			emit node.Exception
			ATHROW
		else:
			ALOAD index(bindingFor(enclosingHandler(node).Declaration))
			ATHROW
			
	def enclosingHandler(node as Node) as ExceptionHandler:
		return node.GetAncestor(NodeType.ExceptionHandler)
			
	override def OnTryStatement(node as TryStatement):
		if node.FailureBlock is not null:
			emitTryFailure node
		else:
			emitTryExceptEnsure node
			
	def emitTryFailure(node as TryStatement):
		assert node.EnsureBlock is null
		assert len(node.ExceptionHandlers) == 0
		
		tryBegin = Label()
		tryEnd = Label()
		exceptEnd = Label()
		
		mark tryBegin
		emit node.ProtectedBlock
		GOTO exceptEnd
		mark tryEnd
		
		exceptBegin = Label()
		mark exceptBegin
		
		exceptionType = bindingFor(java.lang.Throwable)
		TRYCATCHBLOCK tryBegin, tryEnd, exceptBegin, javaType(exceptionType)
		exceptionVariable = newTemp(exceptionType)
		emitStore exceptionVariable
		emit node.FailureBlock
		emitLoad exceptionVariable
		ATHROW
		
		mark exceptEnd
		
	def bindingFor(type as System.Type):
		return typeSystem().Map(type)
		
	def emitTryExceptEnsure(node as TryStatement):
	
		L1 = Label()
		L2 = Label()
		L3 = Label()
		
		mark L1
		emit node.ProtectedBlock
		GOTO L3
		mark L2
		
		for handler in node.ExceptionHandlers:
			L4 = Label()
			mark L4
			decl = handler.Declaration
			TRYCATCHBLOCK L1, L2, L4, javaType(decl.Type)
			if decl.Name is null:
				POP
			else:
				ASTORE index(bindingFor(decl))
			emit handler.Block
			GOTO L3
			
		if node.EnsureBlock is null:
			mark L3
		else:
			
			L4 = Label()
			mark L4
			TRYCATCHBLOCK L1, L4, L4, null
			temp = newTemp(typeSystem.ObjectType)
			ASTORE index(temp)
			emit node.EnsureBlock
			ALOAD index(temp)
			ATHROW
			
			mark L3
			emit node.EnsureBlock
		
	override def OnCastExpression(node as CastExpression):
		emit node.Target
		if typeOf(node).IsValueType:
			pass
		else:
			CHECKCAST javaType(node.Type)
			
	override def OnTryCastExpression(node as TryCastExpression):
		emit node.Target
		DUP
		INSTANCEOF javaType(node.Type)
		L1 = Label()
		L2 = Label()
		IFNE L1
		POP
		ACONST_NULL
		GOTO L2
		mark L1
		CHECKCAST javaType(node.Type)
		mark L2
			
	override def OnBinaryExpression(node as BinaryExpression):
		match node.Operator:
			case BinaryOperatorType.Or:
				emitOr node
			
			case BinaryOperatorType.And:
				emitAnd node
				
			case BinaryOperatorType.Assign:
				emitAssignment node
				
			case BinaryOperatorType.Subtraction:
				emitSubtraction node
			case BinaryOperatorType.Addition:
				emitAddition node
			case BinaryOperatorType.Multiply:
				emitMultiply node
			case BinaryOperatorType.Division:
				emitDivision node
			case BinaryOperatorType.Modulus:
				emitModulus node
				
			case BinaryOperatorType.TypeTest:
				emitTypeTest node
				
			case BinaryOperatorType.Equality:
				emitEquality node
			case BinaryOperatorType.Inequality:
				emitInequality node
				
			case BinaryOperatorType.ReferenceEquality:
				emitReferenceEquality node
			case BinaryOperatorType.ReferenceInequality:
				emitReferenceInequality node
			
			case BinaryOperatorType.GreaterThanOrEqual:
				emitComparison node, Opcodes.IF_ICMPLT
				
			case BinaryOperatorType.LessThan:
				emitComparison node, Opcodes.IF_ICMPGE
				
			case BinaryOperatorType.GreaterThan:
				emitComparison node, Opcodes.IF_ICMPLE
				
	def emitComparison(node as BinaryExpression, branchIfFalseOpcode as int):
		L1 = Label()
		L2 = Label()
		
		emit node.Left
		emit node.Right
		emitJumpInsn branchIfFalseOpcode, L1
		ICONST_1
		GOTO L2
		mark L1
		ICONST_0
		mark L2
		
	def emitAnd(node as BinaryExpression):
		
		L1 = Label()
		L2 = Label()
		
		left = ensureLocal(node.Left)
		emitLoad left
		ensureBool left.Type
		IFEQ L1
		emit node.Right
		GOTO L2
		mark L1
		emitLoad left
		mark L2 
		
	def emitOr(node as BinaryExpression):
		
		L1 = Label()
		L2 = Label()
		
		left = ensureLocal(node.Left)
		emitLoad left
		ensureBool left.Type
		IFNE L1
		emit node.Right
		GOTO L2
		mark L1
		emitLoad left
		mark L2
		
	def ensureBool(topOfStack as IType):
		if topOfStack.IsValueType: return
		INVOKESTATIC resolveRuntimeMethod("ToBool")
				
	def emitReferenceInequality(node as BinaryExpression):
		emitComparison node, Opcodes.IF_ACMPEQ
	    				
	def emitReferenceEquality(node as BinaryExpression):
		emitComparison node, Opcodes.IF_ACMPNE	
		
	def emitInequality(node as BinaryExpression):
		assert isInteger(node.Left) and isInteger(node.Right)
		emitComparison node, Opcodes.IF_ICMPEQ
	    				
	def emitEquality(node as BinaryExpression):
		assert isInteger(node.Left) and isInteger(node.Right)
		emitComparison node, Opcodes.IF_ICMPNE	
		
	def isInteger(e as Expression):
		return typeSystem.IsIntegerOrBool(typeOf(e))
					
	def emitTypeTest(node as BinaryExpression):
		match node.Right:
			case TypeofExpression(Type: t):
				emit node.Left
				INSTANCEOF javaType(t)
				
	def emitMultiply(node as BinaryExpression):
		emitArithmeticExpression node, Opcodes.IMUL
				
	def emitAddition(node as BinaryExpression):
		emitArithmeticExpression node, Opcodes.IADD

	def emitSubtraction(node as BinaryExpression):
		emitArithmeticExpression node, Opcodes.ISUB
		
	def emitDivision(node as BinaryExpression):
		emitArithmeticExpression node, Opcodes.IDIV
		
	def emitModulus(node as BinaryExpression):
		emitArithmeticExpression node, Opcodes.IREM
		
	def emitArithmeticExpression(node as BinaryExpression, opcode as int):
		emit node.Left
		emit node.Right
		emitInstruction opcode
				
	def emitAssignment(node as BinaryExpression):
		if shouldLeaveValueOnStack(node):
			emitAssignmentExpression node
		else:
			emitAssignmentStatement node
			
	def emitAssignmentExpression(node as BinaryExpression):
		rvalue as InternalLocal
		emitAssignment node.Left:
			rvalue = ensureLocal(node.Right)
			emitLoad rvalue
		emitLoad rvalue
			
	def emitAssignmentStatement(node as BinaryExpression):
		emitAssignment node.Left:
			emit node.Right
			
	def emitAssignment(lvalue as Expression, emitRValue as callable()):
		match lvalue:
			case memberRef = MemberReferenceExpression():
				match bindingFor(memberRef):
					case field = IField(IsStatic: false):
						emit memberRef.Target
						emitRValue()
						PUTFIELD field
					case field = IField(IsStatic: true):
						emitRValue()
						PUTSTATIC field
					case p = IProperty():
						unless p.IsStatic:
							emit memberRef.Target
						emitRValue()
						emitInvokeMethodInstructionFor p.GetSetMethod()
			case reference = ReferenceExpression():
				emitRValue()
				match bindingFor(reference):
					case local = ILocalEntity():
						emitStore local
			
	def shouldLeaveValueOnStack(node as BinaryExpression):
		return node.ParentNode.NodeType != NodeType.ExpressionStatement
	
	override def OnMemberReferenceExpression(node as MemberReferenceExpression):
		match bindingFor(node):
			case field = IField(IsStatic: true):
				GETSTATIC field
			case field = IField(IsStatic: false):
				emit node.Target
				GETFIELD field
			case IMethod(IsStatic: false):
				emit node.Target
			case IMethod(IsStatic: true):
				pass
				
	override def OnSelfLiteralExpression(node as SelfLiteralExpression):
		ALOAD 0
				
	override def OnReferenceExpression(node as ReferenceExpression):
		match bindingFor(node):
			case param = InternalParameter():
				emitLoad param.Type, param.Index
			case local = ILocalEntity():
				emitLoad local
			case type = IType():
				LDC type
				
	def emitLoad(local as ILocalEntity):
#		print "emitLoad", local, index(local)
		emitLoad local.Type, index(local)
		
	def emitStore(local as ILocalEntity):
#		print "emitStore", local, index(local)
		emitStore local.Type, index(local)
		
	def emitStore(type as IType, index as int):
		if not type.IsValueType:
			ASTORE index
		else:
			ISTORE index
				
	def emitLoad(type as IType, index as int):
		if not type.IsValueType:
			ALOAD index
		else:
			ILOAD index
			
	def isChar(type as IType):
		return type is typeSystem.CharType
			
	def isIntegerOrBool(type as IType):
		return typeSystem.IsIntegerOrBool(type)
				
	def stripGetterPrefix(name as string):
		return name[len("get_"):]				
		
	override def OnArrayLiteralExpression(node as ArrayLiteralExpression):
		
		elementType = typeOf(node).ElementType
		
		ICONST len(node.Items)
		emitNewArrayOpcodeFor elementType
		i = 0
		for item in node.Items:
			DUP
			ICONST i++
			emit item
			emitArrayStoreOpcodeFor elementType
			
	def emitNewArrayOpcodeFor(elementType as IType):
		if elementType.IsValueType:
			NEWARRAY elementType
		else:
			ANEWARRAY elementType
			
	def NEWARRAY(elementType as IType):
		emitIntInsn Opcodes.NEWARRAY, primitiveTypeIdFor(elementType)
		
	def primitiveTypeIdFor(type as IType):
		if isInt(type): return Opcodes.T_INT
		if isBool(type): return Opcodes.T_BOOLEAN
		if isChar(type): return Opcodes.T_CHAR
		raise type.ToString()
		
	def isInt(type as IType):
		return type is typeSystem().IntType
		
	def isBool(type as IType):
		return type is typeSystem().BoolType
			
	def ANEWARRAY(elementType as IType):
		emitTypeInsn Opcodes.ANEWARRAY, javaType(elementType)
		
	def emitArrayStoreOpcodeFor(elementType as IType):
		emitInstruction arrayStoreOpcodeFor(elementType)
		
	def arrayStoreOpcodeFor(type as IType):
		if type.IsValueType:
			if isChar(type): return Opcodes.CASTORE
			if isBool(type): return Opcodes.BASTORE
			return Opcodes.IASTORE
		return Opcodes.AASTORE
		
	def arrayLoadOpcodeFor(type as IType):
		if type.IsValueType:
			if isChar(type): return Opcodes.CALOAD
			if isBool(type): return Opcodes.BALOAD
			return Opcodes.IALOAD
		return Opcodes.AALOAD
			
	override def OnSlicingExpression(node as SlicingExpression):
		assert 1 == len(node.Indices)
		match node.Indices[0].Begin:
			case IntegerLiteralExpression(Value: value):
				if value < 0:
					emitNormalizedArraySlicing node
				else:
					emitRawArraySlicing node
			otherwise:
				emitNormalizedArraySlicing node
				
	def emitRawArraySlicing(node as SlicingExpression):
		emit node.Target
		emit node.Indices[0].Begin
		emitArrayLoadOpcodeFor node
		
	def emitArrayLoadOpcodeFor(node as SlicingExpression):
		emitArrayLoadOpcodeFor typeOf(node.Target).ElementType
		
	def emitArrayLoadOpcodeFor(elementType as IType):
		emitInstruction arrayLoadOpcodeFor(elementType)
				
	def emitNormalizedArraySlicing(node as SlicingExpression):
		L1 = Label()
		local = ensureLocal(node.Target)
		ALOAD index(local)
		emit node.Indices[0].Begin
		DUP
		ICONST_0
		IF_ICMPGE L1
		ALOAD index(local)
		ARRAYLENGTH
		IADD
		mark L1
		emitArrayLoadOpcodeFor node
		
	def ensureLocal(e as Expression):
		local = e.Entity as InternalLocal
		if local is not null: return local
		
		local = newTemp(typeOf(e))
		emit e
		emitStore local
		return local
		
	override def OnStringLiteralExpression(node as StringLiteralExpression):
		LDC node.Value
		
	override def OnCharLiteralExpression(node as CharLiteralExpression):
		ICONST cast(int, node.Value[0])
		
	override def OnIntegerLiteralExpression(node as IntegerLiteralExpression):
		ICONST node.Value
		
	override def OnBoolLiteralExpression(node as BoolLiteralExpression):
		if node.Value:
			ICONST_1
		else:
			ICONST_0 
		
	def baseType(node as TypeDefinition):
		if node isa InterfaceDefinition: return TypeSystemServices.ObjectType
		return self.GetType(node).BaseType
		
	typeSystem as JavaTypeSystem:
		get: return self.TypeSystemServices
		
	def javaSignature(method as IMethodBase):
		return javaSignature(method as IMethod)
		
	def javaSignature(method as IMethod) as string:
		genericTypeInfo = method.DeclaringType.ConstructedInfo
		if genericTypeInfo is not null:
			return javaSignatureFromMethodOfGenericType(method)
		return ("("
			+ join(typeDescriptor(p.Type) for p in method.GetParameters(), "")
			+ ")"
			+ typeDescriptor(method.ReturnType))
			
	def javaSignatureFromMethodOfGenericType(method as IMethod) as string:
		return javaSignature(definitionFor(method))	
		
	def javaSignature(node as Method):
		return javaSignature(bindingFor(node) as IMethod)
		
	def ensurePath(fname as string):
		path = Path.GetDirectoryName(fname)
		if not string.IsNullOrEmpty(path):
			Directory.CreateDirectory(path)
		
	def classFullFileName(node as TypeDefinition):
		return javaType(bindingFor(node)) + ".class"
		
	def emit(node as Node):
		Visit(node)
		
	def emit(nodes as System.Collections.IEnumerable):
		VisitCollection(nodes)
		
	def LDC(value):
		emitLdcInsn value
		
	def LDC(type as IType):
		emitLdcInsn org.objectweb.asm.Type.getType(typeDescriptor(type))
		
	def IFEQ(label as Label):
		emitJumpInsn Opcodes.IFEQ, label
		
	def IF_ACMPEQ(label as Label):
		emitJumpInsn Opcodes.IF_ACMPEQ, label
		
	def IF_ICMPGE(label as Label):
		emitJumpInsn Opcodes.IF_ICMPGE, label
		
	def IF_ICMPGT(label as Label):
		emitJumpInsn Opcodes.IF_ICMPGT, label
		
	def IF_ICMPLE(label as Label):
		emitJumpInsn Opcodes.IF_ICMPLE, label
		
	def IF_ICMPLT(label as Label):
		emitJumpInsn Opcodes.IF_ICMPLT, label
	
	def IFNE(label as Label):
		emitJumpInsn Opcodes.IFNE, label
		
	def IFNONNULL(label as Label):
		emitJumpInsn Opcodes.IFNONNULL, label
	
	def IF_ACMPNE(label as Label):
		emitJumpInsn Opcodes.IF_ACMPNE, label
		
	def GOTO(label as Label):
		emitJumpInsn Opcodes.GOTO, label
		
	def INSTANCEOF(typeName as string):
		emitTypeInsn Opcodes.INSTANCEOF, typeName
		
	def CHECKCAST(typeName as string):
		emitTypeInsn Opcodes.CHECKCAST, typeName
	
	def ILOAD(index as int):
		emitVarInsn Opcodes.ILOAD, index
		
	def ICONST(value as int):
		if value >= -1 and value <= 5:
			emitInstruction iconstOpcodeFor(value)
		elif value >= -127 and value <= 127:
			emitIntInsn Opcodes.BIPUSH, value
		elif value >= short.MinValue and value <= short.MaxValue:
			emitIntInsn Opcodes.SIPUSH, value
		else:
			LDC java.lang.Integer(value)
			
	def ICONST_0():
		emitInstruction Opcodes.ICONST_0
		
	def ICONST_1():
		emitInstruction Opcodes.ICONST_1
		
	def iconstOpcodeFor(value as int):
		if value == 0: return Opcodes.ICONST_0
		if value == 1: return Opcodes.ICONST_1
		if value == 2: return Opcodes.ICONST_2
		if value == 3: return Opcodes.ICONST_3
		if value == 4: return Opcodes.ICONST_4
		if value == 5: return Opcodes.ICONST_5
		if value == -1: return Opcodes.ICONST_M1
		raise System.ArgumentException("value")
	
	def ISTORE(index as int):
		emitVarInsn(Opcodes.ISTORE, index)
		
	def ACONST_NULL():
		emitInstruction Opcodes.ACONST_NULL
		
	def ALOAD(index as int):
		emitVarInsn(Opcodes.ALOAD, index)
		
	def ARRAYLENGTH():
		emitInstruction Opcodes.ARRAYLENGTH
		
	def ASTORE(index as int):
		emitVarInsn(Opcodes.ASTORE, index)
		
	def GETSTATIC(field as IField):
		emitLoadStaticField(field.DeclaringType, field.Name, field.Type)
		
	def PUTSTATIC(field as IField):
		emitField Opcodes.PUTSTATIC, field
		
	def GETFIELD(field as IField):
		emitField Opcodes.GETFIELD, field
		
	def PUTFIELD(field as IField):
		emitField Opcodes.PUTFIELD, field
		
	def INVOKESTATIC(method as IMethod):
		invoke(Opcodes.INVOKESTATIC, method)
		
	def INVOKEVIRTUAL(method as IMethod):
		invoke(Opcodes.INVOKEVIRTUAL, method)
		
	def INVOKESPECIAL(method as IMethod):
		invoke(Opcodes.INVOKESPECIAL, method)
		
	def INVOKEINTERFACE(method as IMethod):
		invoke(Opcodes.INVOKEINTERFACE, method)
		
	def TRYCATCHBLOCK(begin as Label, end as Label, target as Label, type as string):
		_code.visitTryCatchBlock(begin, end, target, type)
		
	def TABLESWITCH(min as int, max as int, defaultLabel as Label, targets as (Label)):
		_code.visitTableSwitchInsn(min, max, defaultLabel, targets)
		
	def ATHROW():
		emitInstruction(Opcodes.ATHROW)
		
	def RETURN():
	   emitInstruction(Opcodes.RETURN)
		
	def ARETURN():
	   emitInstruction(Opcodes.ARETURN)
	   
	def IRETURN():
	   emitInstruction(Opcodes.IRETURN)
		
	def POP():
		emitInstruction(Opcodes.POP)
		
	def NEW(type as IType):
		emitTypeInsn(Opcodes.NEW, javaType(type))
		
	def DUP():
		emitInstruction(Opcodes.DUP)
		
	def ISUB():
		emitInstruction(Opcodes.ISUB)
		
	def IADD():
		emitInstruction(Opcodes.IADD)
		
	def IMUL():
		emitInstruction(Opcodes.IMUL)
		
	def emitVarInsn(opcode as int, index as int):
		_code.visitVarInsn(opcode, index)
		
	def emitInstruction(i as int):
		_code.visitInsn(i)
		
	def emitIntInsn(opcode as int, value as int):
		_code.visitIntInsn(opcode, value)
		
	def emitJumpInsn(i as int, label as Label):
		_code.visitJumpInsn(i, label)
		
	def emitLdcInsn(value):
		_code.visitLdcInsn(value)
	
	def emitTypeInsn(opcode as int, name as string):
		_code.visitTypeInsn(opcode, name)
		
	def mark(label as Label):
		_code.visitLabel(label)
		
	def invoke(opcode as int, method as IMethod):
		invokeWithName opcode, method, methodName(method.Name)
				
	def invokeWithName(opcode as int, method as IMethod, methodName as string):
		_code.visitMethodInsn(
				opcode,
				javaType(method.DeclaringType),
				methodName,
				javaSignature(method))
		
	def emitLoadStaticField(declaringType as IType, fieldName as string, fieldType as IType):
		emitField Opcodes.GETSTATIC, declaringType, fieldName, fieldType
		
	def emitField(opcode as int, field as IField):
		emitField opcode, field.DeclaringType, field.Name, field.Type
		
	def emitField(opcode as int, declaringType as IType, fieldName as string, fieldType as IType):
		_code.visitFieldInsn(
				opcode,
				javaType(declaringType),
				fieldName,
				typeDescriptor(fieldType))
				
	def bindingFor(node as Node):
		return GetEntity(node)

	def javaType(typeRef as TypeReference):
		return javaType(bindingFor(typeRef) as IType)
		
	def typeDescriptor(type as IType) as string:
		if type in _primitiveMappings: return _primitiveMappings[type]
		if type.IsArray: return arrayDescriptor(type)
		return "L" + javaType(erasureFor(type)) + ";"
		
	def arrayDescriptor(type as IType):
		return "[" + typeDescriptor(type.ElementType)
		
	def javaType(entity as IEntity):
		return javaType(entity as IType)
	
	def javaType(type as IType) as string:
		if type.IsArray: return arrayDescriptor(type)
		if type in _typeMappings: return _typeMappings[type]
		if type.ConstructedInfo is not null: return javaType(type.ConstructedInfo.GenericDefinition)
		if type.DeclaringEntity is not null: return innerClassName(type)
		return javaType(type.FullName)
		
	def innerClassName(type as IType):
		return javaType(type.DeclaringEntity) + "$" + type.Name
		
	def javaType(typeName as string):
		return typeName.Replace('.', '/')
		
		
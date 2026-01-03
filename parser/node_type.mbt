///|
pub(all) enum NodeType {
  Expression(Expression)
  Statement(Statement)
  Pattern(Pattern)
  Declaration(Declaration)
} derive(Show, Eq, ToJson, FromJson)

///|
pub(all) enum Statement {
  BlockStatement(BlockStatement)
  BreakStatement(BreakStatement)
  ContinueStatement(ContinueStatement)
  DebuggerStatement(DebuggerStatement)
  DoWhileStatement(DoWhileStatement)
  EmptyStatement(EmptyStatement)
  ExpressionStatement(ExpressionStatement)
  ForInStatement(ForInStatement)
  ForStatement(ForStatement)
  FunctionDeclaration(FunctionDeclaration)
  IfStatement(IfStatement)
  LabeledStatement(LabeledStatement)
  ReturnStatement(ReturnStatement)
  SwitchStatement(SwitchStatement)
  ThrowStatement(ThrowStatement)
  TryStatement(TryStatement)
  VariableDeclaration(VariableDeclaration)
  WhileStatement(WhileStatement)
  WithStatement(WithStatement)
  ClassDeclaration(ClassDeclaration)
  ExportAllDeclaration(ExportAllDeclaration)
  ExportDefaultDeclaration(ExportDefaultDeclaration)
  ExportNamedDeclaration(ExportNamedDeclaration)
  ForOfStatement(ForOfStatement)
  ImportDeclaration(ImportDeclaration)
  FlowDeclareClass(FlowDeclareClass)
  FlowDeclareFunction(FlowDeclareFunction)
  FlowDeclareInterface(FlowDeclareInterface)
  FlowDeclareModule(FlowDeclareModule)
  FlowDeclareModuleExports(FlowDeclareModuleExports)
  FlowDeclareTypeAlias(FlowDeclareTypeAlias)
  FlowDeclareOpaqueType(FlowDeclareOpaqueType)
  FlowDeclareVariable(FlowDeclareVariable)
  FlowDeclareExportDeclaration(FlowDeclareExportDeclaration)
  FlowEnumDeclaration(FlowEnumDeclaration)
  FlowInterface(FlowInterface)
  FlowOpaqueType(FlowOpaqueType)
  FlowTypeAlias(FlowTypeAlias)
  TSDeclareFunction(TSDeclareFunction)
  TsInterfaceDeclaration(TsInterfaceDeclaration)
  TsTypeAliasDeclaration(TsTypeAliasDeclaration)
  TsEnumDeclaration(TsEnumDeclaration)
  TsModuleDeclaration(TsModuleDeclaration)
  TsImportEqualsDeclaration(TsImportEqualsDeclaration)
  TsExportAssignment(TsExportAssignment)
  TsNamespaceExportDeclaration(TsNamespaceExportDeclaration)
} derive(Show, Eq, ToJson, FromJson)

///|
pub struct Identifier {
  name : String
  optional : Bool
  typeAnnotation : TypeAnnotation?
} derive(Show, Eq, ToJson, FromJson)

///|
pub(all) enum RegExpFlag {
  G
  I
  M
  S
  U
  Y
  V
} derive(Show, Eq, ToJson, FromJson)

///|
pub(all) enum ArrayElement {
  Expression(Expression)
  SpreadElement(argument~ : Expression)
  OmittedExpression
} derive(Show, Eq, ToJson, FromJson)

///|
pub struct ArrayExpression {
  elements : Array[ArrayElement]
} derive(Show, Eq, ToJson, FromJson)

///|
pub(all) enum Expression {
  ArrayLiteralExpression(ArrayExpression)
  AssignmentExpression(AssignmentExpression)
  BinaryExpression(BinaryExpression)
  CallExpression(CallExpression)
  ConditionalExpression(ConditionalExpression)
  FunctionExpression(FunctionExpression)
  Identifier(Identifier)
  StringLiteral(StringLiteral)
  NumericLiteral(NumericLiteral)
  NullLiteral
  BooleanLiteral(BooleanLiteral)
  RegExpLiteral(RegExpLiteral)
  LogicalExpression(LogicalExpression)
  MemberExpression(MemberExpression)
  NewExpression(NewExpression)
  ObjectExpression(ObjectExpression)
  SequenceExpression(SequenceExpression)
  ParenthesizedExpression(ParenthesizedExpression)
  ThisExpression
  PrefixUnaryExpression(PrefixUnaryExpression)
  UpdateExpression(UpdateExpression)
  ArrowFunctionExpression(ArrowFunctionExpression)
  ClassExpression(ClassExpression)
  ImportExpression(ImportExpression)
  MetaProperty(MetaProperty)
  Super
  TaggedTemplateExpression(TaggedTemplateExpression)
  TemplateLiteral(TemplateLiteral)
  YieldExpression(YieldExpression)
  AwaitExpression(AwaitExpression)
  Import
  BigIntLiteral(BigIntLiteral)
  OptionalMemberExpression(OptionalMemberExpression)
  OptionalCallExpression(OptionalCallExpression)
  TypeCastExpression(TypeCastExpression)
  JSXElement(JSXElement)
  JSXFragment(JSXFragment)
  BindExpression(BindExpression)
  DoExpression(DoExpression)
  ModuleExpression(ModuleExpression)
  TopicReference(TopicReference)
  TsInstantiationExpression(TsInstantiationExpression)
  TsAsExpression(TsAsExpression)
  TsSatisfiesExpression(TsSatisfiesExpression)
  TsTypeAssertion(TsTypeAssertion)
  TsTypeCastExpression(TsTypeCastExpression)
  TsNonNullExpression(TsNonNullExpression)
  EstreeChainExpression(EstreeChainExpression)
  EstreeLiteral(EstreeLiteral)
} derive(Show, Eq, ToJson, FromJson)

///|
pub(all) enum Pattern {
  Identifier(Identifier)
  ObjectPattern(ObjectPattern)
  ArrayPattern(ArrayPattern)
  RestElement(RestElement)
  AssignmentPattern(AssignmentPattern)
  MemberExpression(MemberExpression)
  VoidPattern(VoidPattern)
  OmittedExpression
} derive(Show, Eq, ToJson, FromJson)

///|
pub(all) enum Declaration {
  VariableDeclaration(VariableDeclaration)
  ClassDeclaration(ClassDeclaration)
  FunctionDeclaration(FunctionDeclaration)
  TsImportEqualsDeclaration(TsImportEqualsDeclaration)
  TsInterfaceDeclaration(TsInterfaceDeclaration)
  TsTypeAliasDeclaration(TsTypeAliasDeclaration)
  TsEnumDeclaration(TsEnumDeclaration)
  TsModuleDeclaration(TsModuleDeclaration)
} derive(Show, Eq, ToJson, FromJson)

///|
pub(all) enum Literal {
  RegExpLiteral(RegExpLiteral)
  NullLiteral
  StringLiteral(StringLiteral)
  BooleanLiteral(BooleanLiteral)
  NumericLiteral(NumericLiteral)
  BigIntLiteral(BigIntLiteral)
} derive(Show, Eq, ToJson, FromJson)

///|
pub(all) struct RegExpLiteral {
  pattern : String
  flags : Array[RegExpFlag]
} derive(Show, Eq, ToJson, FromJson)

///|
pub struct StringLiteral {
  value : StringView
} derive(Show, Eq, ToJson, FromJson)

///|
pub struct BooleanLiteral {
  value : Bool
} derive(Show, Eq, ToJson, FromJson)

///|
pub struct NumericLiteral {
  value : Double
} derive(Show, Eq, ToJson, FromJson)

///|
pub struct BigIntLiteral {
  value : BigInt
} derive(Show, Eq, ToJson, FromJson)

///|
pub(all) enum Function {
  NormalFunction(NormalFunction)
  ArrowFunctionExpression(ArrowFunctionExpression)
  ObjectMethod(ObjectMethod)
  ClassMethod(ClassMethod)
} derive(Show, Eq, ToJson, FromJson)

///|
pub(all) enum FunctionBody {
  BlockStatement(BlockStatement)
  Expression(Expression)
} derive(Show, Eq, ToJson, FromJson)

///|
pub(all) struct BlockStatement {
  body : Array[Statement]
  directives : Array[Directive]
} derive(Show, Eq, ToJson, FromJson)

///|
pub struct Directive {
  value : DirectiveLiteral
} derive(Show, Eq, ToJson, FromJson)

///|
pub struct DirectiveLiteral {
  value : String
} derive(Show, Eq, ToJson, FromJson)

///|
/// 基础节点信息
pub struct NodeBase {
  start : Int
  end : Int
  loc : SourceLocation
  range : Array[Int]?
  leadingComments : Array[Comment]?
  trailingComments : Array[Comment]?
  innerComments : Array[Comment]?
  extra : Map[String, Json]?
} derive(Show, Eq, ToJson, FromJson)

///|
/// 源代码位置信息
pub struct SourceLocation {
  start : Position
  end : Position
  filename : String?
} derive(Show, Eq, ToJson, FromJson)

///|
/// 位置信息
pub struct Position {
  line : Int
  column : Int
} derive(Show, Eq, ToJson, FromJson)

///|
/// 注释类型
pub(all) enum Comment {
  CommentBlock(CommentBlock)
  CommentLine(CommentLine)
} derive(Show, Eq, ToJson, FromJson)

///|
/// 块注释
pub struct CommentBlock {
  value : String
  start : Int
  end : Int
  loc : SourceLocation
} derive(Show, Eq, ToJson, FromJson)

///|
/// 行注释
pub struct CommentLine {
  value : String
  start : Int
  end : Int
  loc : SourceLocation
} derive(Show, Eq, ToJson, FromJson)

///|
/// 文件节点
pub struct File {
  program : Program
  comments : Array[Comment]
  errors : Array[ParseError]
  tokens : Array[Token]?
} derive(Show, Eq, ToJson, FromJson)

///|
/// 程序节点
pub struct Program {
  sourceType : SourceType
  body : Array[Statement]
  directives : Array[Directive]
  interpreter : InterpreterDirective?
} derive(Show, Eq, ToJson, FromJson)

///|
/// 源类型
pub(all) enum SourceType {
  Script
  Module
} derive(Show, Eq, ToJson, FromJson)

///|
/// 解释器指令
pub struct InterpreterDirective {
  value : String
} derive(Show, Eq, ToJson, FromJson)

///|
/// 解析错误
pub struct ParseError {
  message : String
  loc : SourceLocation
} derive(Show, Eq, ToJson, FromJson)

///|
/// 令牌
pub struct Token {
  tokenType : TokenType
  value : StringView
  start : Int
  end : Int
  loc : SourceLocation
} derive(Show, Eq, ToJson, FromJson)

///|
/// 令牌类型
pub(all) enum TokenType {
  Identifier
  StringLiteral
  NumericLiteral
} derive(Show, Eq, ToJson, FromJson)

///|
/// 表达式语句
pub struct ExpressionStatement {
  expression : Expression
  directive : Directive?
} derive(Show, Eq, ToJson, FromJson)

///|
/// If语句
pub struct IfStatement {
  test_ : Expression
  consequent : Statement
  alternate : Statement?
} derive(Show, Eq, ToJson, FromJson)

///|
/// While语句
pub struct WhileStatement {
  test_ : Expression
  body : Statement
} derive(Show, Eq, ToJson, FromJson)

///|
/// DoWhile语句
pub struct DoWhileStatement {
  body : Statement
  test_ : Expression
} derive(Show, Eq, ToJson, FromJson)

///|
/// For语句
pub struct ForStatement {
  init : VariableDeclaration?
  test_ : Expression?
  update : Expression?
  body : Statement
} derive(Show, Eq, ToJson, FromJson)

///|
/// ForIn语句
pub struct ForInStatement {
  left : VariableDeclaration
  right : Expression
  body : Statement
  await_ : Bool
} derive(Show, Eq, ToJson, FromJson)

///|
/// ForOf语句
pub struct ForOfStatement {
  left : VariableDeclaration
  right : Expression
  body : Statement
  await_ : Bool
} derive(Show, Eq, ToJson, FromJson)

///|
/// Switch语句
pub struct SwitchStatement {
  discriminant : Expression
  cases : Array[SwitchCase]
} derive(Show, Eq, ToJson, FromJson)

///|
/// Switch分支
pub struct SwitchCase {
  test_ : Expression?
  consequent : Array[Statement]
} derive(Show, Eq, ToJson, FromJson)

///|
/// Break语句
pub struct BreakStatement {
  label : Identifier?
} derive(Show, Eq, ToJson, FromJson)

///|
/// Continue语句
pub struct ContinueStatement {
  label : Identifier?
} derive(Show, Eq, ToJson, FromJson)

///|
/// Return语句
pub(all) struct ReturnStatement {
  argument : Expression?
} derive(Show, Eq, ToJson, FromJson)

///|
/// Throw语句
pub struct ThrowStatement {
  argument : Expression
} derive(Show, Eq, ToJson, FromJson)

///|
/// Try语句
pub struct TryStatement {
  block : BlockStatement
  handler : CatchClause?
  finalizer : BlockStatement?
} derive(Show, Eq, ToJson, FromJson)

///|
/// Catch子句
pub struct CatchClause {
  param : Pattern?
  body : BlockStatement
} derive(Show, Eq, ToJson, FromJson)

///|
/// With语句
pub struct WithStatement {
  object : Expression
  body : Statement
} derive(Show, Eq, ToJson, FromJson)

///|
/// 标签语句
pub struct LabeledStatement {
  label : Identifier
  body : Statement
} derive(Show, Eq, ToJson, FromJson)

///|
/// 变量声明
pub struct VariableDeclaration {
  declarations : Array[VariableDeclarator]
  kind : VariableKind
  declare_ : Bool
} derive(Show, Eq, ToJson, FromJson)

///|
/// 变量种类
pub(all) enum VariableKind {
  Var
  Let
  Const
  Using
  AwaitUsing
} derive(Show, Eq, ToJson, FromJson)

///|
/// 变量声明符
pub struct VariableDeclarator {
  id : Pattern
  init : Expression?
  definite : Bool
} derive(Show, Eq, ToJson, FromJson)

///|
/// 函数声明
pub struct FunctionDeclaration {
  id : Identifier
  params : Array[Pattern]
  body : BlockStatement
  generator : Bool
  async_ : Bool
  expression : Bool
  typeParameters : TypeParameterDeclaration?
  returnType : TypeAnnotation?
  declare_ : Bool
} derive(Show, Eq, ToJson, FromJson)

///|
/// 类声明
pub struct ClassDeclaration {
  id : Identifier
  superClass : Expression?
  body : ClassBody
  decorators : Array[Decorator]
  typeParameters : TypeParameterDeclaration?
  superTypeArguments : TypeParameterInstantiation?
  abstract_ : Bool
  implements : Array[TSClassImplements]?
  declare_ : Bool
} derive(Show, Eq, ToJson, FromJson)

///|
/// 类主体
pub struct ClassBody {
  body : Array[ClassMember]
} derive(Show, Eq, ToJson, FromJson)

///|
/// 类成员
pub(all) enum ClassMember {
  ClassMethod(ClassMethod)
  ClassPrivateMethod(ClassPrivateMethod)
  ClassProperty(ClassProperty)
  ClassPrivateProperty(ClassPrivateProperty)
  ClassAccessorProperty(ClassAccessorProperty)
  StaticBlock(StaticBlock)
} derive(Show, Eq, ToJson, FromJson)

///|
/// 类方法
pub struct ClassMethod {
  key : Expression
  kind : MethodKind
  static_ : Bool
  computed : Bool
  params : Array[Pattern]
  body : BlockStatement
  generator : Bool
  async_ : Bool
  accessibility : Accessibility?
  override_ : Bool?
  abstract_ : Bool?
  optional : Bool?
  decorators : Array[Decorator]
  variance : FlowVariance?
} derive(Show, Eq, ToJson, FromJson)

///|
/// 类私有方法
pub struct ClassPrivateMethod {
  key : PrivateName
  kind : MethodKind
  static_ : Bool
  computed : Bool
  params : Array[Pattern]
  body : BlockStatement
  generator : Bool
  async_ : Bool
  decorators : Array[Decorator]
  variance : FlowVariance?
} derive(Show, Eq, ToJson, FromJson)

///|
/// 类属性
pub struct ClassProperty {
  key : Expression
  value : Expression?
  static_ : Bool
  computed : Bool
  accessibility : Accessibility?
  override_ : Bool?
  abstract_ : Bool?
  optional : Bool?
  typeAnnotation : TypeAnnotation?
  readonly_ : Bool?
  definite : Bool?
  decorators : Array[Decorator]
  variance : FlowVariance?
} derive(Show, Eq, ToJson, FromJson)

///|
/// 类私有属性
pub struct ClassPrivateProperty {
  key : PrivateName
  value : Expression?
  static_ : Bool
  computed : Bool
  typeAnnotation : TypeAnnotation?
  optional : Bool?
  definite : Bool?
  readonly_ : Bool?
  override_ : Bool?
  decorators : Array[Decorator]
  variance : FlowVariance?
} derive(Show, Eq, ToJson, FromJson)

///|
/// 类访问器属性
pub struct ClassAccessorProperty {
  key : Expression
  value : Expression?
  static_ : Bool
  computed : Bool
  accessibility : Accessibility?
  override_ : Bool?
  abstract_ : Bool?
  optional : Bool?
  typeAnnotation : TypeAnnotation?
  readonly_ : Bool?
  definite : Bool?
  decorators : Array[Decorator]
  variance : FlowVariance?
} derive(Show, Eq, ToJson, FromJson)

///|
/// 静态块
pub struct StaticBlock {
  body : Array[Statement]
} derive(Show, Eq, ToJson, FromJson)

///|
/// 方法种类
pub(all) enum MethodKind {
  Constructor
  Method
  Get
  Set
} derive(Show, Eq, ToJson, FromJson)

///|
/// 访问修饰符
pub(all) enum Accessibility {
  Public
  Protected
  Private
} derive(Show, Eq, ToJson, FromJson)

///|
/// 私有名称
pub struct PrivateName {
  id : Identifier
} derive(Show, Eq, ToJson, FromJson)

///|
/// 装饰器
pub struct Decorator {
  expression : Expression
} derive(Show, Eq, ToJson, FromJson)

///|
/// 一元表达式
pub struct PrefixUnaryExpression {
  operator : UnaryOperator
  prefix : Bool
  argument : Expression
} derive(Show, Eq, ToJson, FromJson)

///|
/// 一元操作符
pub(all) enum UnaryOperator {
  /// -
  Minus
  /// +
  Plus
  /// *
  Star
  /// /
  Slash
  /// %
  Percent
  /// !
  Not
  /// ~
  BitwiseNot
  /// typeof
  Typeof
  /// void
  Void
  /// delete
  Delete
  /// throw
  Throw
} derive(Show, Eq, ToJson, FromJson)

///|
/// 更新表达式
pub struct UpdateExpression {
  operator : UpdateOperator
  prefix : Bool
  argument : Expression
} derive(Show, Eq, ToJson, FromJson)

///|
/// 更新操作符
pub(all) enum UpdateOperator {
  /// ++
  Increment
  /// --  
  Decrement
} derive(Show, Eq, ToJson, FromJson)

///|
/// 二元表达式
pub struct BinaryExpression {
  operator : BinaryOperator
  left : Expression
  right : Expression
} derive(Show, Eq, ToJson, FromJson)

///|
/// 二元操作符
pub(all) enum BinaryOperator {
  Equal
  NotEqual
  StrictEqual
  StrictNotEqual
  LessThan
  LessThanOrEqual
  GreaterThan
  GreaterThanOrEqual
  LeftShift
  RightShift
  UnsignedRightShift
  Plus
  Star
  Slash
  Percent
  Minus
  Multiply
  Divide
  BitwiseOr
  BitwiseXor
  BitwiseAnd
  In
  Instanceof
} derive(Show, Eq, ToJson, FromJson)

///|
/// 赋值表达式
pub struct AssignmentExpression {
  operator : AssignmentOperator
  left : Pattern
  right : Expression
} derive(Show, Eq, ToJson, FromJson)

///|
/// 赋值操作符
pub(all) enum AssignmentOperator {
  Assign
  Plus
  Star
  Slash
  PercentAssign
  MinusAssign
  MultiplyAssign
  DivideAssign
  ModuloAssign
  LeftShiftAssign
  RightShiftAssign
  UnsignedRightShiftAssign
  BitwiseOrAssign
  BitwiseXorAssign
  BitwiseAndAssign
  LogicalAndAssign
  LogicalOrAssign
  NullishAssign
} derive(Show, Eq, ToJson, FromJson)

///|
/// 逻辑表达式
pub struct LogicalExpression {
  operator : LogicalOperator
  left : Expression
  right : Expression
} derive(Show, Eq, ToJson, FromJson)

///|
/// 逻辑操作符
pub(all) enum LogicalOperator {
  LogicalOr
  LogicalAnd
} derive(Show, Eq, ToJson, FromJson)

///|
/// 成员表达式
pub struct MemberExpression {
  object : Expression
  property : Expression
  computed : Bool
  optional : Bool?
} derive(Show, Eq, ToJson, FromJson)

///|
/// 可选成员表达式
pub struct OptionalMemberExpression {
  object : Expression
  property : Expression
  computed : Bool
  optional : Bool
} derive(Show, Eq, ToJson, FromJson)

///|
/// 调用表达式
pub struct CallExpression {
  callee : Expression
  arguments : Array[Expression]
  optional : Bool
  typeArguments : TypeParameterInstantiation?
} derive(Show, Eq, ToJson, FromJson)

///|
/// 可选调用表达式
pub struct OptionalCallExpression {
  callee : Expression
  arguments : Array[Expression]
  optional : Bool
  typeArguments : TypeParameterInstantiation?
} derive(Show, Eq, ToJson, FromJson)

///|
/// New表达式
pub struct NewExpression {
  callee : Expression
  arguments : Array[Expression]
  optional : Bool
  typeArguments : TypeParameterInstantiation?
} derive(Show, Eq, ToJson, FromJson)

///|
/// 导入表达式
pub struct ImportExpression {
  source : Expression
  phase : ImportPhase?
  options : Expression?
} derive(Show, Eq, ToJson, FromJson)

///|
/// 导入阶段
pub(all) enum ImportPhase {
  Source
  Defer
} derive(Show, Eq, ToJson, FromJson)

///|
/// 序列表达式
pub struct SequenceExpression {
  expressions : Array[Expression]
} derive(Show, Eq, ToJson, FromJson)

///|
/// 条件表达式
pub struct ConditionalExpression {
  test_ : Expression
  alternate : Expression
  consequent : Expression
} derive(Show, Eq, ToJson, FromJson)

///|
/// 绑定表达式
pub struct BindExpression {
  object : Expression?
  callee : Expression
} derive(Show, Eq, ToJson, FromJson)

///|
/// Yield表达式
pub struct YieldExpression {
  argument : Expression?
  delegate : Bool
} derive(Show, Eq, ToJson, FromJson)

///|
/// Await表达式
pub struct AwaitExpression {
  argument : Expression
} derive(Show, Eq, ToJson, FromJson)

///|
/// 主题引用
pub struct TopicReference {} derive(Show, Eq, ToJson, FromJson)

///|
/// Do表达式
pub struct DoExpression {
  body : BlockStatement?
  async_ : Bool
} derive(Show, Eq, ToJson, FromJson)

///|
/// 模块表达式
pub struct ModuleExpression {
  body : Program
} derive(Show, Eq, ToJson, FromJson)

///|
/// 数组模式
pub struct ArrayPattern {
  elements : Array[Pattern]
  optional : Bool?
  typeAnnotation : TypeAnnotation?
} derive(Show, Eq, ToJson, FromJson)

///|
/// 对象模式
pub struct ObjectPattern {
  properties : Array[AssignmentProperty]
  optional : Bool?
  typeAnnotation : TypeAnnotation?
} derive(Show, Eq, ToJson, FromJson)

///|
/// 赋值属性
pub struct AssignmentProperty {
  key : Expression
  value : Pattern
  shorthand : Bool
  computed : Bool
  decorators : Array[Decorator]
} derive(Show, Eq, ToJson, FromJson)

///|
/// 剩余元素
pub struct RestElement {
  argument : Pattern
  optional : Bool?
  typeAnnotation : TypeAnnotation?
} derive(Show, Eq, ToJson, FromJson)

///|
/// 赋值模式
pub struct AssignmentPattern {
  left : Pattern
  right : Expression
  optional : Bool?
  typeAnnotation : TypeAnnotation?
} derive(Show, Eq, ToJson, FromJson)

///|
/// 空模式
pub struct VoidPattern {
  optional : Bool?
  typeAnnotation : TypeAnnotation?
} derive(Show, Eq, ToJson, FromJson)

///|
/// 展开元素
pub struct SpreadElement {
  argument : Expression
} derive(Show, Eq, ToJson, FromJson)

///|
/// 模板字面量
pub struct TemplateLiteral {
  quasis : Array[TemplateElement]
  expressions : Array[Expression]
} derive(Show, Eq, ToJson, FromJson)

///|
/// 模板元素
pub struct TemplateElement {
  tail : Bool
  value : TemplateElementValue
} derive(Show, Eq, ToJson, FromJson)

///|
/// 模板元素值
pub struct TemplateElementValue {
  cooked : String
  raw : String
} derive(Show, Eq, ToJson, FromJson)

///|
/// 标签模板表达式
pub struct TaggedTemplateExpression {
  tag : Expression
  quasi : TemplateLiteral
  typeArguments : TypeParameterInstantiation?
} derive(Show, Eq, ToJson, FromJson)

///|
/// 元属性
pub struct MetaProperty {
  meta : Identifier
  property : Identifier
} derive(Show, Eq, ToJson, FromJson)

///|
/// 导入声明
pub struct ImportDeclaration {
  specifiers : Array[ImportSpecifier]
  source : Literal
  importKind : ImportKind?
  phase : ImportPhase?
  attributes : Array[ImportAttribute]
  module_ : Bool
} derive(Show, Eq, ToJson, FromJson)

///|
/// 导入说明符
pub(all) enum ImportSpecifier {
  ImportSpecifier(ImportSpecifierData)
  ImportDefaultSpecifier(ImportDefaultSpecifierData)
  ImportNamespaceSpecifier(ImportNamespaceSpecifierData)
} derive(Show, Eq, ToJson, FromJson)

///|
/// 导入说明符数据
pub struct ImportSpecifierData {
  imported : Expression
  local_ : Identifier
  importKind : ImportKind?
} derive(Show, Eq, ToJson, FromJson)

///|
/// 导入默认说明符数据
pub struct ImportDefaultSpecifierData {
  local_ : Identifier
} derive(Show, Eq, ToJson, FromJson)

///|
/// 导入命名空间说明符数据
pub struct ImportNamespaceSpecifierData {
  local_ : Identifier
} derive(Show, Eq, ToJson, FromJson)

///|
/// 导入种类
pub(all) enum ImportKind {
  Type
  Typeof
  Value
} derive(Show, Eq, ToJson, FromJson)

///|
/// 导入属性
pub struct ImportAttribute {
  key : Expression
  value : String
} derive(Show, Eq, ToJson, FromJson)

///|
/// 导出命名声明
pub struct ExportNamedDeclaration {
  declaration : Declaration?
  specifiers : Array[ExportSpecifier]
  source : Literal?
  exportKind : ExportKind?
  attributes : Array[ImportAttribute]
} derive(Show, Eq, ToJson, FromJson)

///|
/// 导出默认声明
pub struct ExportDefaultDeclaration {
  declaration : ExportDefaultDeclarationType
} derive(Show, Eq, ToJson, FromJson)

///|
/// 导出默认声明类型
pub(all) enum ExportDefaultDeclarationType {
  FunctionDeclaration(FunctionDeclaration)
  ClassDeclaration(ClassDeclaration)
  Expression(Expression)
  TsInterfaceDeclaration
  FlowEnumDeclaration
} derive(Show, Eq, ToJson, FromJson)

///|
/// 导出全部声明
pub struct ExportAllDeclaration {
  source : Literal
  exportKind : ExportKind?
  attributes : Array[ImportAttribute]
} derive(Show, Eq, ToJson, FromJson)

///|
/// 导出说明符
pub struct ExportSpecifier {
  exported : Expression
  local_ : Identifier
  exportKind : ExportKind?
} derive(Show, Eq, ToJson, FromJson)

///|
/// 导出种类
pub(all) enum ExportKind {
  Type
  Value
} derive(Show, Eq, ToJson, FromJson)

///|
/// 参数占位符
pub struct ArgumentPlaceholder {} derive (
  Show,
  Eq,
  ToJson,
  FromJson,
  Compare,
  Hash,
)

///|
/// 类型注解基础
pub struct TypeAnnotationBase {
  typeAnnotation : String
} derive(Show, Eq, ToJson, FromJson)

///|
/// 类型注解
pub struct TypeAnnotation {
  typeAnnotation : FlowType
} derive(Show, Eq, ToJson, FromJson)

///|
/// TypeScript类型注解
pub struct TsTypeAnnotation {
  typeAnnotation : TsType
} derive(Show, Eq, ToJson, FromJson)

///|
/// 类型参数声明基础
pub struct TypeParameterDeclarationBase {
  params : Array[TypeParameter]
} derive(Show, Eq, ToJson, FromJson)

///|
/// 类型参数声明
pub struct TypeParameterDeclaration {
  params : Array[TypeParameter]
} derive(Show, Eq, ToJson, FromJson)

///|
/// TypeScript类型参数声明
pub struct TsTypeParameterDeclaration {
  params : Array[TsTypeParameter]
} derive(Show, Eq, ToJson, FromJson)

///|
/// 类型参数
pub struct TypeParameter {
  name : String
  default : TypeAnnotation?
} derive(Show, Eq, ToJson, FromJson)

///|
/// TypeScript类型参数
pub struct TsTypeParameter {
  name : Identifier
  in_ : Bool?
  out : Bool?
  const_ : Bool?
  constraint : TsType?
  default : TsType?
} derive(Show, Eq, ToJson, FromJson)

///|
/// 类型参数实例化基础
pub struct TypeParameterInstantiationBase {
  params : Array[Json]
} derive(Show, Eq, ToJson, FromJson)

///|
/// 类型参数实例化
pub struct TypeParameterInstantiation {
  params : Array[FlowType]
} derive(Show, Eq, ToJson, FromJson)

///|
/// TypeScript类型参数实例化
pub struct TsTypeParameterInstantiation {
  params : Array[TsType]
} derive(Show, Eq, ToJson, FromJson)

///|
/// 类型转换表达式基础
pub struct TypeCastExpressionBase {
  expression : Expression
  typeAnnotation : TypeAnnotationBase
} derive(Show, Eq, ToJson, FromJson)

///|
/// 类型转换表达式
pub struct TypeCastExpression {
  expression : Expression
  typeAnnotation : TypeAnnotation
} derive(Show, Eq, ToJson, FromJson)

///|
/// TypeScript类型转换表达式
pub struct TsTypeCastExpression {
  expression : Expression
  typeAnnotation : TsTypeAnnotation
} derive(Show, Eq, ToJson, FromJson)

///|
/// Flow类型
pub(all) enum FlowType {
  AnyTypeAnnotation
  StringTypeAnnotation
  NumberTypeAnnotation
} derive(Show, Eq, ToJson, FromJson)

///|
/// TypeScript类型
pub(all) enum TsType {
  TsKeywordType(TsKeywordType)
  TsThisType
  TsFunctionType(TsFunctionType)
  TsTypeReference(TsTypeReference)
  TsTypeQuery(TsTypeQuery)
  TsTypeLiteral(TsTypeLiteral)
  TsArrayType(TsArrayType)
  TsTupleType(TsTupleType)
  TsOptionalType(TsOptionalType)
  TsRestType(TsRestType)
  TsUnionType(TsUnionType)
  TsIntersectionType(TsIntersectionType)
  TsConditionalType(TsConditionalType)
  TsInferType(TsInferType)
  TsParenthesizedType(TsParenthesizedType)
  TsTypeOperator(TsTypeOperator)
  TsIndexedAccessType(TsIndexedAccessType)
  TsMappedType(TsMappedType)
  TsLiteralType(TsLiteralType)
  TsTemplateLiteralType(TsTemplateLiteralType)
  TsImportType(TsImportType)
  TsTypePredicate(TsTypePredicate)
} derive(Show, Eq, ToJson, FromJson)

///|
/// TypeScript关键字类型
pub(all) enum TsKeywordType {
  TSAnyKeyword
  TSUnknownKeyword
  TSNumberKeyword
  TSObjectKeyword
  TSBooleanKeyword
  TSBigIntKeyword
  TSStringKeyword
  TSSymbolKeyword
  TSVoidKeyword
  TSUndefinedKeyword
  TSNullKeyword
  TSNeverKeyword
  TSIntrinsicKeyword
} derive(Show, Eq, ToJson, FromJson)

///|
/// TypeScript函数类型
pub struct TsFunctionType {
  params : Array[TsFunctionParam]
  returnType : TsTypeAnnotation
  typeParameters : TsTypeParameterDeclaration?
} derive(Show, Eq, ToJson, FromJson)

///|
/// TypeScript函数参数
pub(all) enum TsFunctionParam {
  Identifier(Identifier)
  RestElement(RestElement)
  ObjectPattern(ObjectPattern)
  ArrayPattern(ArrayPattern)
  VoidPattern(VoidPattern)
} derive(Show, Eq, ToJson, FromJson)

///|
/// TypeScript类型引用
pub struct TsTypeReference {
  typeName : TsEntityName
  typeArguments : TsTypeParameterInstantiation?
} derive(Show, Eq, ToJson, FromJson)

///|
/// TypeScript实体名称
pub(all) enum TsEntityName {
  Identifier(Identifier)
  ThisExpression
  TsQualifiedName(TsQualifiedName)
} derive(Show, Eq, ToJson, FromJson)

///|
/// TypeScript限定名称
pub struct TsQualifiedName {
  left : TsEntityName
  right : Identifier
} derive(Show, Eq, ToJson, FromJson)

///|
/// TypeScript类型查询
pub struct TsTypeQuery {
  exprName : TsEntityName
  typeArguments : TsTypeParameterInstantiation?
} derive(Show, Eq, ToJson, FromJson)

///|
/// TypeScript类型字面量
pub struct TsTypeLiteral {
  members : Array[TsTypeElement]
} derive(Show, Eq, ToJson, FromJson)

///|
/// TypeScript类型元素
pub(all) enum TsTypeElement {
  TsCallSignatureDeclaration(TsCallSignatureDeclaration)
  TsConstructSignatureDeclaration(TsConstructSignatureDeclaration)
  TsPropertySignature(TsPropertySignature)
  TsMethodSignature(TsMethodSignature)
  TsIndexSignature(TsIndexSignature)
} derive(Show, Eq, ToJson, FromJson)

///|
/// TypeScript调用签名声明
pub struct TsCallSignatureDeclaration {
  params : Array[TsFunctionParam]
  returnType : TsTypeAnnotation?
  typeParameters : TsTypeParameterDeclaration?
} derive(Show, Eq, ToJson, FromJson)

///|
/// TypeScript构造签名声明
pub struct TsConstructSignatureDeclaration {
  params : Array[TsFunctionParam]
  returnType : TsTypeAnnotation?
  typeParameters : TsTypeParameterDeclaration?
} derive(Show, Eq, ToJson, FromJson)

///|
/// TypeScript属性签名
pub struct TsPropertySignature {
  key : Expression
  computed : Bool
  optional : Bool?
  typeAnnotation : TsTypeAnnotation?
  accessibility : Accessibility?
  readonly_ : Bool?
  static_ : Bool?
} derive(Show, Eq, ToJson, FromJson)

///|
/// TypeScript方法签名
pub struct TsMethodSignature {
  key : Expression
  computed : Bool
  optional : Bool?
  kind : MethodKind
  params : Array[TsFunctionParam]
  returnType : TsTypeAnnotation?
  typeParameters : TsTypeParameterDeclaration?
  accessibility : Accessibility?
  readonly_ : Bool?
  static_ : Bool?
} derive(Show, Eq, ToJson, FromJson)

///|
/// TypeScript索引签名
pub struct TsIndexSignature {
  parameters : Array[TsFunctionParam]
  readonly_ : Bool?
  static_ : Bool?
  typeAnnotation : TsTypeAnnotation?
  accessibility : Accessibility?
} derive(Show, Eq, ToJson, FromJson)

///|
/// TypeScript数组类型
pub struct TsArrayType {
  elementType : TsType
} derive(Show, Eq, ToJson, FromJson)

///|
/// TypeScript元组类型
pub struct TsTupleType {
  elementTypes : Array[TsTupleElement]
} derive(Show, Eq, ToJson, FromJson)

///|
/// TypeScript元组元素
pub(all) enum TsTupleElement {
  TsType(TsType)
  TsNamedTupleMember(TsNamedTupleMember)
} derive(Show, Eq, ToJson, FromJson)

///|
/// TypeScript命名元组成员
pub struct TsNamedTupleMember {
  label : Identifier
  optional : Bool
  elementType : TsType
} derive(Show, Eq, ToJson, FromJson)

///|
/// TypeScript可选类型
pub struct TsOptionalType {
  typeAnnotation : TsType
} derive(Show, Eq, ToJson, FromJson)

///|
/// TypeScript剩余类型
pub struct TsRestType {
  typeAnnotation : TsType
} derive(Show, Eq, ToJson, FromJson)

///|
/// TypeScript联合类型
pub struct TsUnionType {
  types : Array[TsType]
} derive(Show, Eq, ToJson, FromJson)

///|
/// TypeScript交集类型
pub struct TsIntersectionType {
  types : Array[TsType]
} derive(Show, Eq, ToJson, FromJson)

///|
/// TypeScript条件类型
pub struct TsConditionalType {
  checkType : TsType
  extendsType : TsType
  trueType : TsType
  falseType : TsType
} derive(Show, Eq, ToJson, FromJson)

///|
/// TypeScript推断类型
pub struct TsInferType {
  typeParameter : TsTypeParameter
} derive(Show, Eq, ToJson, FromJson)

///|
/// TypeScript括号类型
pub struct TsParenthesizedType {
  typeAnnotation : TsType
} derive(Show, Eq, ToJson, FromJson)

///|
/// TypeScript类型操作符
pub struct TsTypeOperator {
  operator : TsTypeOperatorType
  typeAnnotation : TsType
} derive(Show, Eq, ToJson, FromJson)

///|
/// TypeScript类型操作符类型
pub(all) enum TsTypeOperatorType {
  Keyof
  Unique
  Readonly
} derive(Show, Eq, ToJson, FromJson)

///|
/// TypeScript索引访问类型
pub struct TsIndexedAccessType {
  objectType : TsType
  indexType : TsType
} derive(Show, Eq, ToJson, FromJson)

///|
/// TypeScript映射类型
pub struct TsMappedType {
  key : Identifier
  constraint : TsType
  readonly_ : TsReadonlyModifier?
  optional : TsOptionalModifier?
  typeAnnotation : TsType?
  nameType : TsType?
} derive(Show, Eq, ToJson, FromJson)

///|
/// TypeScript只读修饰符
pub(all) enum TsReadonlyModifier {
  True
  Plus
  Star
  Slash
  Percent
  Minus
} derive(Show, Eq, ToJson, FromJson)

///|
/// TypeScript可选修饰符
pub(all) enum TsOptionalModifier {
  True
  Plus
  Star
  Slash
  Percent
  Minus
} derive(Show, Eq, ToJson, FromJson)

///|
/// TypeScript字面量类型
pub struct TsLiteralType {
  literal : TsLiteral
} derive(Show, Eq, ToJson, FromJson)

///|
/// TypeScript字面量
pub(all) enum TsLiteral {
  NumericLiteral(Double)
  StringLiteral(String)
  BooleanLiteral(Bool)
  TemplateLiteral(TemplateLiteral)
  UnaryExpression(PrefixUnaryExpression)
} derive(Show, Eq, ToJson, FromJson)

///|
/// TypeScript模板字面量类型
pub struct TsTemplateLiteralType {
  quasis : Array[TemplateElement]
  types : Array[TsType]
} derive(Show, Eq, ToJson, FromJson)

///|
/// TypeScript导入类型
pub struct TsImportType {
  source : String
  qualifier : TsEntityName?
  typeArguments : TsTypeParameterInstantiation?
  options : Expression?
} derive(Show, Eq, ToJson, FromJson)

///|
/// TypeScript类型谓词
pub struct TsTypePredicate {
  parameterName : TsParameterName
  typeAnnotation : TsTypeAnnotation?
  asserts : Bool
} derive(Show, Eq, ToJson, FromJson)

///|
/// TypeScript参数名称
pub(all) enum TsParameterName {
  Identifier(Identifier)
  TsThisType(TsThisType)
} derive(Show, Eq, ToJson, FromJson)

///|
/// TypeScriptThis类型
pub struct TsThisType {} derive(Show, Eq, ToJson, FromJson)

///|
/// TypeScript参数属性
pub struct TSParameterProperty {
  accessibility : Accessibility?
  readonly_ : Bool?
  override_ : Bool?
  parameter : TSParameter
  static_ : Bool
} derive(Show, Eq, ToJson, FromJson)

///|
/// TypeScript参数
pub(all) enum TSParameter {
  Identifier(Identifier)
  AssignmentPattern(AssignmentPattern)
} derive(Show, Eq, ToJson, FromJson)

///|
/// TypeScript声明函数
pub struct TSDeclareFunction {
  id : Identifier
  params : Array[Pattern]
  returnType : TypeAnnotation?
  generator : Bool
  async_ : Bool
  typeParameters : TypeParameterDeclaration?
  declare_ : Bool
} derive(Show, Eq, ToJson, FromJson)

///|
/// TypeScript声明方法
pub struct TSDeclareMethod {
  key : Expression
  kind : MethodKind
  static_ : Bool
  computed : Bool
  params : Array[Pattern]
  returnType : TypeAnnotation?
  generator : Bool
  async_ : Bool
  typeParameters : TypeParameterDeclaration?
  accessibility : Accessibility?
  override_ : Bool?
  optional : Bool?
  abstract_ : Bool?
  decorators : Array[Decorator]
} derive(Show, Eq, ToJson, FromJson)

///|
/// TypeScript接口声明
pub struct TsInterfaceDeclaration {
  id : Identifier?
  typeParameters : TsTypeParameterDeclaration?
  extends_ : Array[TSInterfaceHeritage]?
  body : TSInterfaceBody
  declare_ : Bool
} derive(Show, Eq, ToJson, FromJson)

///|
/// TypeScript接口主体
pub struct TSInterfaceBody {
  body : Array[TsTypeElement]
} derive(Show, Eq, ToJson, FromJson)

///|
/// TypeScript接口继承
pub struct TSInterfaceHeritage {
  expression : Expression
  typeArguments : TsTypeParameterInstantiation?
} derive(Show, Eq, ToJson, FromJson)

///|
/// TypeScript类实现
pub struct TSClassImplements {
  expression : Expression
  typeArguments : TsTypeParameterInstantiation?
} derive(Show, Eq, ToJson, FromJson)

///|
/// TypeScript类型别名声明
pub struct TsTypeAliasDeclaration {
  id : Identifier
  typeParameters : TsTypeParameterDeclaration?
  typeAnnotation : TsType
  declare_ : Bool
} derive(Show, Eq, ToJson, FromJson)

///|
/// TypeScript枚举声明
pub struct TsEnumDeclaration {
  const_ : Bool?
  id : Identifier
  body : TsEnumBody
  declare_ : Bool
} derive(Show, Eq, ToJson, FromJson)

///|
/// TypeScript枚举主体
pub struct TsEnumBody {
  members : Array[TsEnumMember]
} derive(Show, Eq, ToJson, FromJson)

///|
/// TypeScript枚举成员
pub struct TsEnumMember {
  id : Expression
  initializer : Expression?
  computed : Bool
} derive(Show, Eq, ToJson, FromJson)

///|
/// TypeScript模块声明
pub struct TsModuleDeclaration {
  kind : TsModuleKind
  global : Bool?
  id : TsModuleName
  body : TsNamespaceBody
  declare_ : Bool
} derive(Show, Eq, ToJson, FromJson)

///|
/// TypeScript模块种类
pub(all) enum TsModuleKind {
  Global
  Module
  Namespace
} derive(Show, Eq, ToJson, FromJson)

///|
/// TypeScript模块名称
pub(all) enum TsModuleName {
  TsEntityName(TsEntityName)
  StringLiteral(String)
} derive(Show, Eq, ToJson, FromJson)

///|
/// TypeScript命名空间主体
pub(all) enum TsNamespaceBody {
  TsModuleBlock(TsModuleBlock)
  TsNamespaceDeclaration(TsNamespaceDeclaration)
} derive(Show, Eq, ToJson, FromJson)

///|
/// TypeScript模块块
pub struct TsModuleBlock {
  body : Array[Statement]
} derive(Show, Eq, ToJson, FromJson)

///|
/// TypeScript命名空间声明
pub struct TsNamespaceDeclaration {
  id : Identifier
  body : TsNamespaceBody
  kind : TsModuleKind
  global : Bool?
  declare_ : Bool
} derive(Show, Eq, ToJson, FromJson)

///|
/// TypeScript导入等于声明
pub struct TsImportEqualsDeclaration {
  id : Identifier
  importKind : ImportKind
  moduleReference : TsModuleReference
} derive(Show, Eq, ToJson, FromJson)

///|
/// TypeScript模块引用
pub(all) enum TsModuleReference {
  TsEntityName(TsEntityName)
  TsExternalModuleReference(TsExternalModuleReference)
} derive(Show, Eq, ToJson, FromJson)

///|
/// TypeScript外部模块引用
pub struct TsExternalModuleReference {
  expression : String
} derive(Show, Eq, ToJson, FromJson)

///|
/// TypeScript导出赋值
pub struct TsExportAssignment {
  expression : Expression
} derive(Show, Eq, ToJson, FromJson)

///|
/// TypeScript命名空间导出声明
pub struct TsNamespaceExportDeclaration {
  id : Identifier
} derive(Show, Eq, ToJson, FromJson)

///|
/// TypeScript作为表达式
pub struct TsAsExpression {
  expression : Expression
  typeAnnotation : TsType
} derive(Show, Eq, ToJson, FromJson)

///|
/// TypeScript类型断言
pub struct TsTypeAssertion {
  expression : Expression
  typeAnnotation : TsType
} derive(Show, Eq, ToJson, FromJson)

///|
/// TypeScript满足表达式
pub struct TsSatisfiesExpression {
  expression : Expression
  typeAnnotation : TsType
} derive(Show, Eq, ToJson, FromJson)

///|
/// TypeScript非空表达式
pub struct TsNonNullExpression {
  expression : Expression
} derive(Show, Eq, ToJson, FromJson)

///|
/// TypeScript实例化表达式
pub struct TsInstantiationExpression {
  expression : Expression
  typeArguments : TsTypeParameterInstantiation?
} derive(Show, Eq, ToJson, FromJson)

///|
/// ESTree字面量
pub struct EstreeLiteral {
  value : Json
  raw : Json
} derive(Show, Eq, ToJson, FromJson)

///|
/// ESTree正则表达式字面量
pub struct EstreeRegExpLiteral {
  value : Json?
  raw : Json?
  regex : EstreeRegExpLiteralRegex
} derive(Show, Eq, ToJson, FromJson)

///|
/// ESTree正则表达式字面量正则表达式
pub struct EstreeRegExpLiteralRegex {
  pattern : String
  flags : String
} derive(Show, Eq, ToJson, FromJson)

///|
/// ESTree大整数字面量
pub struct EstreeBigIntLiteral {
  value : Int?
  raw : Json?
  bigint : String
} derive(Show, Eq, ToJson, FromJson)

///|
/// ESTree属性
pub struct EstreeProperty {
  key : Expression
  value : Expression
  kind : EstreePropertyKind?
  method_ : Bool
  shorthand : Bool
  computed : Bool
  decorators : Array[Decorator]
  variance : FlowVariance?
  optional : Bool?
} derive(Show, Eq, ToJson, FromJson)

///|
/// ESTree属性种类
pub(all) enum EstreePropertyKind {
  Init
  Get
  Set
} derive(Show, Eq, ToJson, FromJson)

///|
/// ESTree方法定义
pub struct EstreeMethodDefinition {
  key : Expression
  value : FunctionExpression
  kind : MethodKind
  static_ : Bool
  computed : Bool
  decorators : Array[Decorator]
  accessibility : Accessibility?
  override_ : Bool?
  optional : Bool?
} derive(Show, Eq, ToJson, FromJson)

///|
/// ESTree导入表达式
pub struct EstreeImportExpression {
  source : Expression
  options : Expression?
} derive(Show, Eq, ToJson, FromJson)

///|
/// ESTree私有标识符
pub struct EstreePrivateIdentifier {
  name : String
} derive(Show, Eq, ToJson, FromJson)

///|
/// ESTree属性定义
pub struct EstreePropertyDefinition {
  key : Expression
  value : Expression
  static_ : Bool
  computed : Bool
  accessibility : Accessibility?
  override_ : Bool?
  optional : Bool?
  declare_ : Bool?
  decorators : Array[Decorator]
  definite : Bool?
  readonly_ : Bool?
  typeAnnotation : TsTypeAnnotation?
} derive(Show, Eq, ToJson, FromJson)

///|
/// ESTree访问器属性
pub struct EstreeAccessorProperty {
  key : Expression
  value : Expression
  static_ : Bool
  computed : Bool
  accessibility : Accessibility?
  override_ : Bool?
  optional : Bool?
  declare_ : Bool?
  decorators : Array[Decorator]
  definite : Bool?
  readonly_ : Bool?
  typeAnnotation : TsTypeAnnotation?
} derive(Show, Eq, ToJson, FromJson)

///|
/// ESTree链表达式
pub struct EstreeChainExpression {
  expression : Expression
} derive(Show, Eq, ToJson, FromJson)

///|
/// ESTreeTypeScript空体函数表达式
pub struct EstreeTSEmptyBodyFunctionExpression {
  params : Array[Pattern]
  generator : Bool
  async_ : Bool
  typeParameters : TypeParameterDeclaration?
  returnType : TypeAnnotation?
} derive(Show, Eq, ToJson, FromJson)

///|
/// ESTreeTypeScript抽象方法定义
pub struct EstreeTSAbstractMethodDefinition {
  key : Expression
  value : EstreeTSEmptyBodyFunctionExpression
  kind : MethodKind
  static_ : Bool
  computed : Bool
  decorators : Array[Decorator]
  accessibility : Accessibility?
  override_ : Bool?
  optional : Bool?
} derive(Show, Eq, ToJson, FromJson)

///|
/// ESTreeTypeScript抽象属性定义
pub struct EstreeTSAbstractPropertyDefinition {
  key : Expression
  value : Json?
  static_ : Bool
  computed : Bool
  accessibility : Accessibility?
  override_ : Bool?
  optional : Bool?
  declare_ : Bool?
  decorators : Array[Decorator]
  definite : Bool?
  readonly_ : Bool?
  typeAnnotation : TsTypeAnnotation?
} derive(Show, Eq, ToJson, FromJson)

///|
/// ESTreeTypeScript抽象访问器属性
pub struct EstreeTSAbstractAccessorProperty {
  key : Expression
  value : Json?
  static_ : Bool
  computed : Bool
  accessibility : Accessibility?
  override_ : Bool?
  optional : Bool?
  declare_ : Bool?
  decorators : Array[Decorator]
  definite : Bool?
  readonly_ : Bool?
  typeAnnotation : TsTypeAnnotation?
} derive(Show, Eq, ToJson, FromJson)

///|
/// 占位符
pub struct Placeholder {
  name : Identifier
  expectedNode : String
} derive(Show, Eq, ToJson, FromJson)

///|
/// Flow方差
pub struct FlowVariance {
  kind : FlowVarianceKind
} derive(Show, Eq, ToJson, FromJson)

///|
/// Flow方差种类
pub(all) enum FlowVarianceKind {
  In
  Out
} derive(Show, Eq, ToJson, FromJson)

///|
/// 对象表达式
pub struct ObjectExpression {
  properties : Array[ObjectMember]
} derive(Show, Eq, ToJson, FromJson)

///|
/// 对象成员
pub(all) enum ObjectMember {
  ObjectProperty(ObjectProperty)
  ObjectMethod(ObjectMethod)
  SpreadElement(SpreadElement)
} derive(Show, Eq, ToJson, FromJson)

///|
/// 对象属性
pub struct ObjectProperty {
  key : Expression
  value : Expression
  shorthand : Bool
  computed : Bool
  decorators : Array[Decorator]
} derive(Show, Eq, ToJson, FromJson)

///|
/// 对象方法
pub struct ObjectMethod {
  key : Expression
  kind : MethodKind
  static_ : Bool
  computed : Bool
  params : Array[Pattern]
  body : BlockStatement
  generator : Bool
  async_ : Bool
  value : Expression
  decorators : Array[Decorator]
  typeParameters : TypeParameterDeclaration?
  variance : FlowVariance?
} derive(Show, Eq, ToJson, FromJson)

///|
/// 函数表达式
pub struct FunctionExpression {
  id : Identifier?
  params : Array[Pattern]
  body : BlockStatement
  generator : Bool
  async_ : Bool
  expression : Bool
  typeParameters : TypeParameterDeclaration?
  returnType : TypeAnnotation?
} derive(Show, Eq, ToJson, FromJson)

///|
/// 箭头函数表达式
pub struct ArrowFunctionExpression {
  params : Array[Pattern]
  body : FunctionBody
  generator : Bool
  async_ : Bool
  expression : Bool
  typeParameters : TypeParameterDeclaration?
  returnType : TypeAnnotation?
} derive(Show, Eq, ToJson, FromJson)

///|
/// V8内建标识符
pub struct V8IntrinsicIdentifier {
  name : String
} derive(Show, Eq, ToJson, FromJson)

///|
/// 空语句
pub struct EmptyStatement {} derive(Show, Eq, ToJson, FromJson)

///|
/// 调试器语句
pub struct DebuggerStatement {} derive(Show, Eq, ToJson, FromJson)

///|
/// 注释空白
pub struct CommentWhitespace {
  start : Int
  end : Int
  comments : Array[Comment]
  leadingNode : Json?
  trailingNode : Json?
  containerNode : Json?
} derive(Show, Eq, ToJson, FromJson)

///|
/// 声明基础
pub struct DeclarationBase {
  declare_ : Bool
} derive(Show, Eq, ToJson, FromJson)

///|
/// 有装饰器
pub struct HasDecorators {
  decorators : Array[Decorator]
} derive(Show, Eq, ToJson, FromJson)

///|
/// 模式基础
pub struct PatternBase {
  optional : Bool?
  typeAnnotation : TypeAnnotation?
} derive(Show, Eq, ToJson, FromJson)

///|
/// 无体函数或方法基础
pub struct BodilessFunctionOrMethodBase {
  id : Identifier?
  params : Array[Pattern]
  generator : Bool
  async_ : Bool
  expression : Bool
  typeParameters : TypeParameterDeclaration?
  returnType : TypeAnnotation?
  decorators : Array[Decorator]
} derive(Show, Eq, ToJson, FromJson)

///|
/// 函数基础
pub struct FunctionBase {
  body : BlockStatement
} derive(Show, Eq, ToJson, FromJson)

///|
/// 调用或New基础
pub struct CallOrNewBase {
  callee : Expression
  arguments : Array[Expression]
  optional : Bool
  typeArguments : TypeParameterInstantiation?
} derive(Show, Eq, ToJson, FromJson)

///|
/// 类基础
pub struct ClassBase {
  id : Identifier?
  superClass : Expression?
  body : ClassBody
  decorators : Array[Decorator]
  typeParameters : TypeParameterDeclaration?
  superTypeArguments : TypeParameterInstantiation?
  abstract_ : Bool
  implements : Array[TSClassImplements]?
} derive(Show, Eq, ToJson, FromJson)

///|
/// 类成员基础
pub struct ClassMemberBase {
  static_ : Bool
  computed : Bool
  accessibility : Accessibility?
  override_ : Bool?
  abstract_ : Bool?
  optional : Bool?
  decorators : Array[Decorator]
} derive(Show, Eq, ToJson, FromJson)

///|
/// 方法基础
pub struct MethodBase {
  kind : MethodKind
  params : Array[Pattern]
  body : BlockStatement
  generator : Bool
  async_ : Bool
} derive(Show, Eq, ToJson, FromJson)

///|
/// 类方法或声明方法通用
pub struct ClassMethodOrDeclareMethodCommon {
  key : Expression
  kind : MethodKind
  static_ : Bool
  computed : Bool
  declare_ : Bool?
  decorators : Array[Decorator]
  accessibility : Accessibility?
  override_ : Bool?
  optional : Bool?
  abstract_ : Bool?
} derive(Show, Eq, ToJson, FromJson)

///|
/// 模块说明符
pub struct ModuleSpecifier {
  local_ : Identifier
} derive(Show, Eq, ToJson, FromJson)

///|
/// 任意导入
pub(all) enum AnyImport {
  ImportDeclaration(ImportDeclaration)
  TsImportEqualsDeclaration(TsImportEqualsDeclaration)
} derive(Show, Eq, ToJson, FromJson)

///|
/// 任意导出
pub(all) enum AnyExport {
  ExportNamedDeclaration(ExportNamedDeclaration)
  ExportDefaultDeclaration(ExportDefaultDeclaration)
  ExportAllDeclaration(ExportAllDeclaration)
  TsExportAssignment(TsExportAssignment)
  TsImportEqualsDeclaration(TsImportEqualsDeclaration)
  TsNamespaceExportDeclaration(TsNamespaceExportDeclaration)
} derive(Show, Eq, ToJson, FromJson)

///|
/// 模块声明
pub(all) enum ModuleDeclaration {
  AnyImport(AnyImport)
  AnyExport(AnyExport)
} derive(Show, Eq, ToJson, FromJson)

///|
/// 可分配
pub(all) enum Assignable {
  Pattern(Pattern)
  MemberExpression(MemberExpression)
  TsTypeCastExpression(TsTypeCastExpression)
  TypeCastExpression(TypeCastExpression)
} derive(Show, Eq, ToJson, FromJson)

///|
/// 类
pub(all) enum Class {
  ClassDeclaration(ClassDeclaration)
  ClassExpression(ClassExpression)
} derive(Show, Eq, ToJson, FromJson)

///|
/// 类表达式
pub struct ClassExpression {
  id : Identifier?
  superClass : Expression?
  body : ClassBody
  decorators : Array[Decorator]
  typeParameters : TypeParameterDeclaration?
  superTypeArguments : TypeParameterInstantiation?
  abstract_ : Bool
  implements : Array[TSClassImplements]?
} derive(Show, Eq, ToJson, FromJson)

///|
/// 普通函数
pub(all) enum NormalFunction {
  FunctionDeclaration(FunctionDeclaration)
  FunctionExpression(FunctionExpression)
} derive(Show, Eq, ToJson, FromJson)

///|
/// ForLike
pub(all) enum ForLike {
  ForStatement(ForStatement)
  ForInOf(ForInOf)
} derive(Show, Eq, ToJson, FromJson)

///|
/// ForInOf
pub(all) enum ForInOf {
  ForInStatement(ForInStatement)
  ForOfStatement(ForOfStatement)
} derive(Show, Eq, ToJson, FromJson)

///|
/// BlockStatementLike
pub(all) enum BlockStatementLike {
  Program(Program)
  BlockStatement(BlockStatement)
} derive(Show, Eq, ToJson, FromJson)

///|
/// 对象或类成员
pub(all) enum ObjectOrClassMember {
  ClassMethod(ClassMethod)
  ClassProperty(ClassProperty)
  ObjectMember(ObjectMember)
} derive(Show, Eq, ToJson, FromJson)

///|
/// 方法Like
pub(all) enum MethodLike {
  ObjectMethod(ObjectMethod)
  ClassMethod(ClassMethod)
  ClassPrivateMethod(ClassPrivateMethod)
  TSDeclareMethod(TSDeclareMethod)
} derive(Show, Eq, ToJson, FromJson)

///|
/// 签名声明
pub(all) enum TsSignatureDeclaration {
  TsCallSignatureDeclaration(TsCallSignatureDeclaration)
  TsConstructSignatureDeclaration(TsConstructSignatureDeclaration)
  TsMethodSignature(TsMethodSignature)
  TsFunctionType(TsFunctionType)
  TsConstructorType(TsConstructorType)
} derive(Show, Eq, ToJson, FromJson)

///|
/// 签名声明或索引签名基础
pub struct TsSignatureDeclarationOrIndexSignatureBase {
  returnType : TsTypeAnnotation?
  typeAnnotation : TsTypeAnnotation?
} derive(Show, Eq, ToJson, FromJson)

///|
/// 签名声明基础
pub struct TsSignatureDeclarationBase {
  params : Array[TsFunctionParam]
  returnType : TsTypeAnnotation?
  typeParameters : TsTypeParameterDeclaration?
  typeAnnotation : TsTypeAnnotation?
} derive(Show, Eq, ToJson, FromJson)

///|
/// 索引签名基础
pub struct TsIndexSignatureBase {
  parameters : Array[TsFunctionParam]
  returnType : TsTypeAnnotation?
  typeAnnotation : TsTypeAnnotation?
} derive(Show, Eq, ToJson, FromJson)

///|
/// 命名类型元素基础
pub struct TsNamedTypeElementBase {
  key : Expression
  computed : Bool
  optional : Bool?
  accessibility : Accessibility?
  readonly_ : Bool?
  static_ : Bool?
} derive(Show, Eq, ToJson, FromJson)

///|
/// 可选函数声明
pub struct OptFunctionDeclaration {
  id : Identifier?
  params : Array[Pattern]
  body : BlockStatement
  generator : Bool
  async_ : Bool
  expression : Bool
  typeParameters : TypeParameterDeclaration?
  returnType : TypeAnnotation?
  declare_ : Bool
} derive(Show, Eq, ToJson, FromJson)

///|
/// 可选TypeScript声明函数
pub struct OptTSDeclareFunction {
  id : Identifier?
  params : Array[Pattern]
  returnType : TypeAnnotation?
  generator : Bool
  async_ : Bool
  typeParameters : TypeParameterDeclaration?
  declare_ : Bool
} derive(Show, Eq, ToJson, FromJson)

///|
/// 可选类声明
pub struct OptClassDeclaration {
  id : Identifier?
  superClass : Expression?
  body : ClassBody
  decorators : Array[Decorator]
  typeParameters : TypeParameterDeclaration?
  superTypeArguments : TypeParameterInstantiation?
  abstract_ : Bool
  implements : Array[TSClassImplements]?
  declare_ : Bool
} derive(Show, Eq, ToJson, FromJson)

///|
/// 解析子脚本状态
pub struct ParseSubscriptState {
  optionalChainMember : Bool
  maybeAsyncArrow : Bool
  stop : Bool
} derive(Show, Eq, ToJson, FromJson)

///|
/// 解析类成员状态
pub struct ParseClassMemberState {
  hadConstructor : Bool
  hadSuperClass : Bool
} derive(Show, Eq, ToJson, FromJson)

///|
pub struct TsConstructorType {
  params : Array[TsFunctionParam]
  returnType : TsTypeAnnotation
  typeParameters : TsTypeParameterDeclaration?
  abstract_ : Bool?
} derive(Show, Eq, ToJson, FromJson)

///|
pub struct FlowDeclareClass {} derive(Show, Eq, ToJson, FromJson)

///|
pub struct FlowDeclareFunction {} derive (
  Show,
  Eq,
  ToJson,
  FromJson,
  Compare,
  Hash,
)

///|
pub struct FlowDeclareInterface {} derive (
  Show,
  Eq,
  ToJson,
  FromJson,
  Compare,
  Hash,
)

///|
pub struct FlowDeclareModule {} derive(Show, Eq, ToJson, FromJson)

///|
pub struct FlowDeclareModuleExports {} derive (
  Show,
  Eq,
  ToJson,
  FromJson,
  Compare,
  Hash,
)

///|
pub struct FlowDeclareTypeAlias {} derive (
  Show,
  Eq,
  ToJson,
  FromJson,
  Compare,
  Hash,
)

///|
pub struct FlowDeclareOpaqueType {} derive (
  Show,
  Eq,
  ToJson,
  FromJson,
  Compare,
  Hash,
)

///|
pub struct FlowDeclareVariable {} derive (
  Show,
  Eq,
  ToJson,
  FromJson,
  Compare,
  Hash,
)

///|
pub struct FlowDeclareExportDeclaration {} derive (
  Show,
  Eq,
  ToJson,
  FromJson,
  Compare,
  Hash,
)

///|
pub struct FlowEnumDeclaration {} derive (
  Show,
  Eq,
  ToJson,
  FromJson,
  Compare,
  Hash,
)

///|
pub struct FlowInterface {} derive(Show, Eq, ToJson, FromJson)

///|
pub struct FlowOpaqueType {} derive(Show, Eq, ToJson, FromJson)

///|
pub struct FlowTypeAlias {} derive(Show, Eq, ToJson, FromJson)

///|
pub struct ParenthesizedExpression {} derive (
  Show,
  Eq,
  ToJson,
  FromJson,
  Compare,
  Hash,
)

///|
pub struct JSXElement {} derive(Show, Eq, ToJson, FromJson)

///|
pub struct JSXFragment {} derive(Show, Eq, ToJson, FromJson)

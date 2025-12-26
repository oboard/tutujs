///|
pub(all) enum NodeType {
  Expression(Expression)
  Statement(Statement)
  Pattern(Pattern)
  Declaration(Declaration)
} derive(Show, Eq, ToJson, FromJson, Compare, Hash)

///|
pub(all) enum Statement {
  BlockStatement
  BreakStatement
  ContinueStatement
  DebuggerStatement
  DoWhileStatement
  EmptyStatement
  ExpressionStatement
  ForInStatement
  ForStatement
  FunctionDeclaration
  IfStatement
  LabeledStatement
  ReturnStatement
  SwitchStatement
  ThrowStatement
  TryStatement
  VariableDeclaration
  WhileStatement
  WithStatement
  ClassDeclaration
  ExportAllDeclaration
  ExportDefaultDeclaration
  ExportNamedDeclaration
  ForOfStatement
  ImportDeclaration
  FlowDeclareClass
  FlowDeclareFunction
  FlowDeclareInterface
  FlowDeclareModule
  FlowDeclareModuleExports
  FlowDeclareTypeAlias
  FlowDeclareOpaqueType
  FlowDeclareVariable
  FlowDeclareExportDeclaration
  FlowEnumDeclaration
  FlowInterface
  FlowOpaqueType
  FlowTypeAlias
  TSDeclareFunction
  TsInterfaceDeclaration
  TsTypeAliasDeclaration
  TsEnumDeclaration
  TsModuleDeclaration
  TsImportEqualsDeclaration
  TsExportAssignment
  TsNamespaceExportDeclaration
} derive(Show, Eq, ToJson, FromJson, Compare, Hash)

///|
pub struct Identifier {
  name : String
  optional : Bool
} derive(Show, Eq, ToJson, FromJson, Compare, Hash)

///|
pub enum ArrowFunctionExpression {
  BlockStatement
  Expression
} derive(Show, Eq, ToJson, FromJson, Compare, Hash)

///|
pub(all) enum RegExpFlag {
  G
  I
  M
  S
  U
  Y
  V
} derive(Show, Eq, ToJson, FromJson, Compare, Hash)

///|
pub enum ArrayExpression {
  Expression(Expression)
  SpreadElement(argument~ : Expression)
  None
} derive(Show, Eq, ToJson, FromJson, Compare, Hash)

///|
pub(all) enum Expression {
  ArrayExpression(ArrayExpression)
  AssignmentExpression
  BinaryExpression
  CallExpression
  ConditionalExpression
  FunctionExpression
  Identifier
  StringLiteral
  NumericLiteral
  NullLiteral
  BooleanLiteral
  RegExpLiteral(RegExpLiteral)
  LogicalExpression
  MemberExpression
  NewExpression
  ObjectExpression
  SequenceExpression
  ParenthesizedExpression
  ThisExpression
  UnaryExpression
  UpdateExpression
  ArrowFunctionExpression
  ClassExpression
  ImportExpression
  MetaProperty
  Super
  TaggedTemplateExpression
  TemplateLiteral
  YieldExpression(argument~ : Expression?, delegate~ : Bool)
  AwaitExpression(argument~ : Expression)
  Import
  BigIntLiteral
  OptionalMemberExpression
  OptionalCallExpression
  TypeCastExpression
  JSXElement
  JSXFragment
  BindExpression
  DoExpression
  ModuleExpression
  TopicReference
  TsInstantiationExpression
  TsAsExpression
  TsSatisfiesExpression
  TsTypeAssertion
  TsTypeCastExpression
  TsNonNullExpression
  EstreeChainExpression
  EstreeLiteral
} derive(Show, Eq, ToJson, FromJson, Compare, Hash)

///|
pub(all) enum Pattern {
  Identifier
  ObjectPattern
  ArrayPattern
  RestElement
  AssignmentPattern
  VoidPattern
} derive(Show, Eq, ToJson, FromJson, Compare, Hash)

///|
pub(all) enum Declaration {
  VariableDeclaration
  ClassDeclaration
  FunctionDeclaration
  TsImportEqualsDeclaration
  TsInterfaceDeclaration
  TsTypeAliasDeclaration
  TsEnumDeclaration
  TsModuleDeclaration
} derive(Show, Eq, ToJson, FromJson, Compare, Hash)

///|
pub(all) enum Literal {
  RegExpLiteral(RegExpLiteral)
  NullLiteral
  StringLiteral(String)
  BooleanLiteral(Bool)
  NumericLiteral(Double)
  BigIntLiteral(BigInt)
} derive(Show, Eq, ToJson, FromJson, Compare, Hash)

///|
pub(all) struct RegExpLiteral {
  pattern : String
  flags : Array[RegExpFlag]
} derive(Show, Eq, ToJson, FromJson, Compare, Hash)

///|
pub(all) enum NormalFunction {
  FunctionDeclaration
  FunctionExpression
} derive(Show, Eq, ToJson, FromJson, Compare, Hash)

///|
pub(all) enum Function {
  NormalFunction(NormalFunction)
  ArrowFunctionExpression
  ObjectMethod
  ClassMethod
} derive(Show, Eq, ToJson, FromJson, Compare, Hash)

///|
pub(all) enum FunctionBody {
  BlockStatement(BlockStatement)
  Expression(Expression)
} derive(Show, Eq, ToJson, FromJson, Compare, Hash)

///|
pub struct BlockStatement {
  body : Array[Statement]
  directives : Array[Directive]
} derive(Show, Eq, ToJson, FromJson, Compare, Hash)

///|
pub struct Directive {
  value : DirectiveLiteral
} derive(Show, Eq, ToJson, FromJson, Compare, Hash)

///|
pub struct DirectiveLiteral {
  value : String
} derive(Show, Eq, ToJson, FromJson, Compare, Hash)

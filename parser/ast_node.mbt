///|
pub struct ASTNode {
  node_type : NodeType
  loc : SourceLocation?
  // Common fields
  body : Array[ASTNode]
  // Expression fields
  operator : String?
  left : ASTNode?
  right : ASTNode?
  argument : ASTNode?
  // Declaration fields
  declarations : Array[ASTNode]
  kind : VariableKind?
  id : ASTNode?
  init : ASTNode?
  // Function fields
  params : Array[ASTNode]
  callee : ASTNode?
  // Identifier and Literal
  name : String?
  value : String?
  raw : String?
  // Statement fields
  condition : ASTNode?
  consequent : ASTNode?
  alternate : ASTNode?
  // Object/Array
  properties : Array[ASTNode]
  elements : Array[ASTNode]
  key : ASTNode?
  node_method : Bool?
  shorthand : Bool?
} derive(Show, ToJson, FromJson, Compare, Eq, Hash)

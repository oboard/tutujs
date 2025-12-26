///|
pub(all) enum JSValue {
  String(String)
  Number(Double)
  Boolean(Bool)
  BigInt(BigInt)
  Symbol(JSValue)
  Function(JSFunction)
  Object(JSObject)
  Null
  Undefined
} derive(Eq, ToJson, Compare, FromJson, Hash)

///|
pub impl Show for JSValue with output(self, logger) -> Unit {
  match self {
    String(s) => logger.write_string(s)
    Number(n) => logger.write_string(n.to_string())
    Boolean(b) => logger.write_string(b.to_string())
    BigInt(n) => logger.write_string(n.to_string())
    Symbol(s) => logger.write_string(s.to_string())
    Function(f) => logger.write_string(f.to_string())
    Object(o) => logger.write_string(o.to_string())
    Null => logger.write_string("null")
    Undefined => logger.write_string("undefined")
  }
}

///|
pub(all) struct JSObject {
  mut properties : Map[String, JSValue]
  mut prototype : JSValue
  class_name : String
  mut extensible : Bool
} derive(Show, ToJson, FromJson, Eq)

///|
pub fn JSObject::new(class_name : String, prototype : JSValue) -> JSObject {
  { properties: Map::new(), prototype, class_name, extensible: true }
}

///|
pub struct JSFunction {
  name : String
  params : Array[String]
  body : @parser.ASTNode
} derive(Show, Eq, ToJson, Compare, FromJson, Hash)

///|
pub fn JSFunction::new(
  name : String,
  params : Array[String],
  body : @parser.ASTNode,
) -> JSFunction {
  { name, params, body }
}

///|
pub impl Hash for JSObject with hash(self) -> Int {
  self.class_name.hash()
}

///|
pub impl Hash for JSObject with hash_combine(self, hash) -> Unit {
  self.class_name.hash_combine(hash)
}

///|
pub impl Compare for JSObject with compare(_, _) -> Int {
  0
}

///|
pub(all) enum JSValue {
  String(StringView)
  Number(Double)
  Boolean(Bool)
  BigInt(BigInt)
  Symbol(String)
  Function(JSFunction)
  Object(JSObject)
  Null
  Undefined
} derive(Eq, ToJson, Compare, FromJson, Hash)

///|
pub impl Show for JSValue with output(self, logger) {
  match self {
    String(s) => logger.write_view(s)
    Number(n) => n.output(logger)
    Boolean(b) => b.output(logger)
    BigInt(i) => i.output(logger)
    Symbol(s) => logger.write_string("Symbol(" + s + ")")
    Function(f) =>
      logger.write_string("Function: " + f.name.unwrap_or("anonymous"))
    Object(_) => logger.write_string("[object Object]")
    Null => logger.write_string("null")
    Undefined => logger.write_string("undefined")
  }
}

///|
pub(all) struct JSFunction {
  name : String?
  params : Array[String]
  body : @parser.BlockStatement
  context : Context
} derive(Show, Eq, ToJson, FromJson)

///|
pub(all) struct JSObject {
  properties : @hashmap.HashMap[String, JSValue]
  prototype : JSValue? // Optional prototype? Or just JSValue
} derive(Show, Eq)

///|
pub impl ToJson for JSObject with to_json(_) {
  JSValue::Null.to_json()
}

///|
pub impl FromJson for JSObject with from_json(_, _) {
  { properties: @hashmap.new(), prototype: None }
}

///|
pub impl Compare for JSObject with compare(_, _) -> Int {
  0
}

///|
pub impl Hash for JSObject with hash_combine(self, hasher) -> Unit {
  self.properties.each(fn(k, v) {
    hasher.combine(k)
    hasher.combine(v)
  })
}

///|
pub impl Compare for JSFunction with compare(_, _) -> Int {
  0
}

///|
pub impl Hash for JSFunction with hash_combine(self, hasher) -> Unit {
  hasher.combine(self.name)
  hasher.combine(self.params)
  hasher.combine(self.context)
  hasher.combine(self.body.to_json().stringify())
}

///|
pub fn JSValue::is_truthy(self : JSValue) -> Bool {
  match self {
    String(s) => s.length() > 0
    Number(n) => n != 0.0 && not(n.is_nan())
    Boolean(b) => b
    BigInt(i) => i != 0
    Symbol(_) => true
    Function(_) => true
    Object(_) => true
    Null => false
    Undefined => false
  }
}

///|
pub fn JSValue::to_int32(self : JSValue) -> Int {
  match self {
    Number(n) => n.to_int()
    Boolean(true) => 1
    Boolean(false) => 0
    String(s) => @strconv.parse_int(s.to_string()) catch { _ => 0 }
    _ => 0
  }
}

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
  Internal(JSInternal)
} derive(Eq, ToJson, Compare, FromJson, Hash)

///|
pub(all) enum JSInternal {
  Date(@time.ZonedDateTime)
  RegExp(@regexp.Regexp, String)
  Accessor(JSFunction?, JSFunction?) // Getter, Setter
}

///|
pub impl Eq for JSInternal with equal(self, other) {
  match (self, other) {
    (Date(d1), Date(d2)) => d1.to_string() == d2.to_string()
    (RegExp(_, s1), RegExp(_, s2)) => s1 == s2
    (Accessor(g1, s1), Accessor(g2, s2)) => g1 == g2 && s1 == s2
    _ => false
  }
}

///|
pub impl Compare for JSInternal with compare(_self, _other) {
  0
}

///|
pub impl ToJson for JSInternal with to_json(_self) {
  JSValue::Null.to_json()
}

///|
pub impl FromJson for JSInternal with from_json(_v, _path) {
  abort("Cannot deserialize internal value")
}

///|
pub impl Hash for JSInternal with hash_combine(self, hasher) {
  match self {
    Date(d) => hasher.combine(d.to_string())
    RegExp(_, s) => hasher.combine(s)
    Accessor(g, s) => {
      hasher.combine(g)
      hasher.combine(s)
    }
  }
}

///|
pub impl Show for JSInternal with output(self, logger) {
  match self {
    Date(d) => logger.write_string("Date(" + d.to_string() + ")")
    RegExp(_, s) => logger.write_string("RegExp(/" + s + "/)")
    Accessor(_, _) => logger.write_string("[Accessor]")
  }
}

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
    Internal(i) => i.output(logger)
  }
}

///|
pub fn JSValue::bitwise_not(self : JSValue) -> JSValue {
  let n = self.to_int32()
  JSValue::Number(n.lxor(-1).to_double())
}

///|
pub(all) enum FunctionBody {
  User(@parser.BlockStatement)
  Native((Context, JSValue, Array[JSValue]) -> JSValue)
} derive(Show)

///|
pub impl Eq for FunctionBody with equal(_, _) {
  false // Functions are not structurally equal usually
}

///|
pub impl ToJson for FunctionBody with to_json(_) {
  JSValue::Null.to_json()
}

///|
pub impl FromJson for FunctionBody with from_json(_, _) {
  User(@parser.BlockStatement::{ body: [], directives: [] }) // Dummy
}

///|
pub(all) struct JSFunction {
  name : String?
  params : Array[String]
  body : FunctionBody
  context : Context
  properties : @hashmap.HashMap[String, JSValue]
  prototype : JSValue? // [[Prototype]]
  strict : Bool
} derive(Show, Eq, ToJson)

///|
pub fn JSFunction::new(
  name? : String,
  params? : Array[String],
  body~ : FunctionBody,
  context? : Context,
  properties? : @hashmap.HashMap[String, JSValue],
  prototype? : JSValue,
  strict? : Bool,
) -> JSFunction {
  {
    name,
    params: params.unwrap_or([]),
    body,
    context: context.unwrap_or(Context::new()),
    properties: properties.unwrap_or(@hashmap.new()),
    prototype,
    strict: strict.unwrap_or(false),
  }
}

///|
pub impl FromJson for JSFunction with from_json(_, _) {
  // Dummy implementation
  let ctx = Context::{
    scope: @hashmap.new(),
    parent: None,
    pending_labels: [],
    strict: false,
  }
  {
    name: None,
    params: [],
    body: User(@parser.BlockStatement::{ body: [], directives: [] }),
    context: ctx,
    properties: @hashmap.new(),
    prototype: None,
    strict: false,
  }
}

///|
pub(all) struct JSObject {
  properties : @hashmap.HashMap[String, JSValue]
  /// prototype 需要是 Optional（JSValue?），原因：JavaScript 中确实存在“没有原型”的对象。
  prototype : JSValue?
} derive(Show, Eq)

///|
pub fn JSObject::op_set(self : JSObject, key : String, value : JSValue) -> Unit {
  self.properties.set(key, value)
}

///|
pub fn JSObject::op_get(self : JSObject, key : String) -> JSValue {
  match self.properties.get(key) {
    Some(v) => v
    None => Undefined
  }
}

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
  match self.body {
    User(_) => hasher.combine("user")
    Native(_) => hasher.combine("native")
  }
}

///|
#alias("_[_]=_")
pub fn JSFunction::set(
  self : JSFunction,
  key : String,
  value : JSValue,
) -> Unit {
  self.properties.set(key, value)
}

///|
#alias("_[_]")
pub fn JSFunction::get(self : JSFunction, key : String) -> JSValue {
  match self.properties.get(key) {
    Some(v) => v
    None => Undefined
  }
}

///|
#alias("_[_]")
pub fn JSValue::get_property(self : JSValue, name : String) -> JSValue {
  match self {
    Object(obj) =>
      match obj.properties.get(name) {
        Some(v) =>
          match v {
            Internal(Accessor(Some(getter), _)) =>
              getter.context.invoke(getter, self, []) catch {
                _ => Undefined
              }
            Internal(Accessor(None, _)) => Undefined
            _ => v
          }
        None =>
          match obj.prototype {
            Some(proto) => proto.get_property(name)
            None => Undefined
          }
      }
    Function(func) =>
      match func.properties.get(name) {
        Some(v) => v
        None =>
          match func.prototype {
            Some(proto) => proto.get_property(name)
            None => Undefined
          }
      }
    _ => Undefined // TODO: Primitives wrapping
  }
}

///|
pub fn JSValue::set_property(
  self : JSValue,
  name : String,
  value : JSValue,
  strict? : Bool = false,
) -> Unit raise EvalError {
  match self {
    Object({ properties, .. }) =>
      match properties.get(name) {
        Some(Internal(Accessor(_, Some(setter)))) => {
          let _ = setter.context.invoke(setter, self, [value]) catch {
            _ => Undefined
          }

        }
        Some(Internal(Accessor(_, None))) =>
          if strict {
            raise EvalError::Throw(
              JSValue::String("TypeError: Cannot assign to read only property"),
            )
          }
        _ => properties.set(name, value)
      }
    Function(func) => func.properties.set(name, value)
    _ =>
      if strict {
        raise EvalError::Throw(
          JSValue::String("TypeError: Cannot set property on non-object"),
        )
      }
  }
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
    Internal(_) => true
  }
}

///|
pub fn JSValue::to_int32(self : JSValue) -> Int {
  let n = self.to_number()
  if n.is_nan() || n.is_inf() {
    0
  } else {
    n.to_int()
  }
}

///|
pub fn JSValue::to_number(self : JSValue) -> Double {
  match self {
    Number(n) => n
    Boolean(true) => 1.0
    Boolean(false) => 0.0
    String(s) =>
      @strconv.parse_double(s.to_string()) catch {
        _ => @double.not_a_number
      }
    Null => 0.0
    Undefined => @double.not_a_number
    Object(_) => @double.not_a_number // Simplified
    Function(_) => @double.not_a_number
    Internal(_) => @double.not_a_number
    BigInt(i) =>
      @strconv.parse_double(i.to_string()) catch {
        _ => @double.not_a_number
      }
    Symbol(_) => @double.not_a_number // TypeError in JS usually
  }
}

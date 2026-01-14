///|
let object_id_counter : Ref[Int] = Ref::new(0)

///|
fn next_object_id() -> Int {
  object_id_counter.val = object_id_counter.val + 1
  object_id_counter.val
}

///|
pub(all) enum JSValue {
  String(StringView)
  Number(Double)
  Boolean(Bool)
  BigInt(BigInt)
  Symbol(Int, String)
  Function(JSFunction)
  Object(JSObject)
  Null
  Undefined
  Internal(JSInternal)
} derive(ToJson, Compare, FromJson)

///|
pub impl Eq for JSValue with equal(self, other) {
  match (self, other) {
    (Undefined, Undefined) => true
    (Null, Null) => true
    (Boolean(a), Boolean(b)) => a == b
    (Number(a), Number(b)) =>
      if a.is_nan() && b.is_nan() {
        true
      } else {
        a == b
      }
    (String(a), String(b)) => a == b
    (BigInt(a), BigInt(b)) => a == b
    (Symbol(id1, _), Symbol(id2, _)) => id1 == id2
    (Object(a), Object(b))
    | (Function({ base: a, .. }), Function({ base: b, .. })) => a._id == b._id
    (Internal(a), Internal(b)) => a == b
    _ => false
  }
}

///|
pub impl Hash for JSValue with hash_combine(self, hasher) {
  match self {
    Undefined => hasher.combine(0)
    Null => hasher.combine(1)
    Boolean(b) => hasher.combine(if b { 2 } else { 3 })
    Number(n) =>
      if n.is_nan() {
        hasher.combine("NaN") // Stable hash for NaN
      } else if n == 0.0 { // Handle -0.0
        hasher.combine(0.0)
      } else {
        hasher.combine(n)
      }
    String(s) => hasher.combine(s)
    BigInt(i) => hasher.combine(i)
    Symbol(id, _) => hasher.combine(id)
    Object(o) | Function({ base: o, .. }) => hasher.combine(o._id)
    Internal(i) => hasher.combine(i)
  }
}

///|
pub(all) enum JSInternal {
  Date(@time.ZonedDateTime)
  RegExp(@regexp.Regexp, String)
  Map(LinkedMap)
  MapIterator(LinkedMap, Ref[LinkedEntry?], String) // map, next_entry, kind
  Set(LinkedMap)
  SetIterator(LinkedMap, Ref[LinkedEntry?], String) // map, next_entry, kind
  Accessor(JSFunction?, JSFunction?) // Getter, Setter
}

///|
pub impl Eq for JSInternal with equal(self, other) {
  match (self, other) {
    (Date(d1), Date(d2)) => d1.to_string() == d2.to_string()
    (RegExp(_, s1), RegExp(_, s2)) => s1 == s2
    (Accessor(g1, s1), Accessor(g2, s2)) => g1 == g2 && s1 == s2
    (Map(m1), Map(m2)) => physical_equal(m1, m2)
    (MapIterator(m1, n1, k1), MapIterator(m2, n2, k2)) =>
      physical_equal(m1, m2) && n1.val == n2.val && k1 == k2
    (Set(m1), Set(m2)) => physical_equal(m1, m2)
    (SetIterator(m1, n1, k1), SetIterator(m2, n2, k2)) =>
      physical_equal(m1, m2) && n1.val == n2.val && k1 == k2
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
    Map(_) => hasher.combine("Map")
    MapIterator(_, _, k) => hasher.combine("MapIterator" + k)
    Set(_) => hasher.combine("Set")
    SetIterator(_, _, k) => hasher.combine("SetIterator" + k)
  }
}

///|
pub impl Show for JSInternal with output(self, logger) {
  match self {
    Date(d) => logger.write_string("Date(" + d.to_string() + ")")
    RegExp(_, s) => logger.write_string("RegExp(/" + s + "/)")
    Accessor(_, _) => logger.write_string("[Accessor]")
    Map(_) => logger.write_string("[Map]")
    MapIterator(_, _, k) => logger.write_string("[Map Iterator] " + k)
    Set(_) => logger.write_string("[Set]")
    SetIterator(_, _, k) => logger.write_string("[Set Iterator] " + k)
  }
}

///|
pub impl Show for JSValue with output(self, logger) {
  match self {
    String(s) => logger.write_view(s)
    Number(n) => n.output(logger)
    Boolean(b) => b.output(logger)
    BigInt(i) => i.output(logger)
    Symbol(id, s) => {
      logger.write_string("Symbol(")
      id.output(logger)
      logger.write_string(",")
      logger.write_string(s)
      logger.write_string(")")
    }
    Function(f) =>
      logger.write_string("Function: " + f.name.unwrap_or("anonymous"))
    Object(_) => logger.write_string("[object Object]")
    Null => logger.write_string("null")
    Undefined => logger.write_string("undefined")
    Internal(i) => i.output(logger)
  }
}

///|
pub fn JSValue::to_property_key(self : JSValue) -> String {
  match self {
    String(s) => s.to_string()
    Symbol(id, s) =>
      if id >= 1001 &&
        id <= 1011 &&
        s.has_prefix("Symbol.") {
        "Symbol(" + s + ")"
      } else {
        "Symbol(" + id.to_string() + "," + s + ")"
      }
    _ => self.to_string()
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
  Native((Context, JSValue, Array[JSValue]) -> JSValue raise EvalError)
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
pub(all) struct JSObject {
  _id : Int
  properties : @hashmap.HashMap[String, JSValue]
  /// prototype 需要是 Optional（JSValue?），原因：JavaScript 中确实存在“没有原型”的对象。
  mut prototype : JSValue?
  mut extensible : Bool
  mut is_sealed : Bool
  mut is_frozen : Bool
  mut proxy_target : JSValue?
  mut proxy_handler : JSValue?
} derive(Show, Eq)

///|
pub(all) struct JSFunction {
  mut name : String?
  params : Array[String]
  body : FunctionBody
  context : Context
  strict : Bool
  is_constructor : Bool
  is_arrow : Bool
  base : JSObject
  // _id : Int
  // properties : @hashmap.HashMap[String, JSValue]
  // mut prototype : JSValue? // [[Prototype]]
  // mut extensible : Bool
  // mut is_sealed : Bool
  // mut is_frozen : Bool
  // mut proxy_target : JSValue?
  // mut proxy_handler : JSValue?
} derive(Show, Eq, ToJson)

// ///|
// pub(open) trait JSObjectLike {
//   set_extensible(self : Self, val : Bool) -> Unit
//   get_extensible(self : Self) -> Bool
//   set_prototype_of(self : Self, proto : JSValue) -> Bool
//   get_prototype_of(self : Self) -> JSValue
//   get_is_sealed(self : Self) -> Bool
//   set_is_sealed(self : Self, val : Bool) -> Bool

// }

///|
pub fn JSFunction::new(
  name? : String,
  params? : Array[String],
  body~ : FunctionBody,
  context? : Context,
  properties? : @hashmap.HashMap[String, JSValue],
  prototype? : JSValue,
  strict? : Bool,
  is_constructor? : Bool,
  is_arrow? : Bool,
) -> JSFunction {
  let params = params.unwrap_or([])
  let properties = properties.unwrap_or(@hashmap.new())
  if not(properties.contains("length")) {
    properties.set("length", JSValue::Number(params.length().to_double()))
  }
  match name {
    Some(n) =>
      if not(properties.contains("name")) {
        properties.set("name", JSValue::String(n))
      }
    None => ()
  }
  let is_ctor = match is_constructor {
    Some(b) => b
    None =>
      match body {
        User(_) => true // User functions are constructors by default (except arrow/methods, handled by parser/eval)
        Native(_) => false // Native functions are NOT constructors by default
      }
  }
  {
    name,
    params,
    body,
    context: context.unwrap_or(Context::new()),
    strict: strict.unwrap_or(false),
    is_constructor: is_ctor,
    is_arrow: is_arrow.unwrap_or(false),
    base: {
      _id: next_object_id(),
      properties,
      prototype,
      extensible: true,
      is_sealed: false,
      is_frozen: false,
      proxy_target: None,
      proxy_handler: None,
    },
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
    strict: false,
    is_constructor: true,
    is_arrow: false,
    base: {
      _id: next_object_id(),
      properties: @hashmap.new(),
      prototype: None,
      extensible: true,
      is_sealed: false,
      is_frozen: false,
      proxy_target: None,
      proxy_handler: None,
    },
  }
}

///|
pub fn JSObject::new(
  properties? : @hashmap.HashMap[String, JSValue],
  prototype? : JSValue,
) -> JSObject {
  {
    _id: next_object_id(),
    properties: properties.unwrap_or(@hashmap.new()),
    prototype,
    extensible: true,
    is_sealed: false,
    is_frozen: false,
    proxy_target: None,
    proxy_handler: None,
  }
}

///|
#alias("_[_]=_")
pub fn JSObject::set(self : JSObject, key : String, value : JSValue) -> Unit {
  self.properties[key] = value
}

///|
#alias("_[_]")
pub fn JSObject::get(self : JSObject, key : String) -> JSValue {
  JSValue::Object(self).get_property(key)
}

///|
pub impl ToJson for JSObject with to_json(_) {
  JSValue::Null.to_json()
}

///|
pub impl FromJson for JSObject with from_json(_, _) {
  {
    _id: next_object_id(),
    properties: @hashmap.new(),
    prototype: None,
    extensible: true,
    is_sealed: false,
    is_frozen: false,
    proxy_target: None,
    proxy_handler: None,
  }
}

///|
pub impl Compare for JSObject with compare(_, _) -> Int {
  0
}

///|
pub impl Hash for JSObject with hash_combine(self, hasher) -> Unit {
  hasher.combine(self._id)
}

///|
pub impl Compare for JSFunction with compare(_, _) -> Int {
  0
}

///|
pub impl Hash for JSFunction with hash_combine(self, hasher) -> Unit {
  hasher.combine(self.base._id)
}

///|
#alias("_[_]=_")
pub fn JSFunction::set(
  self : JSFunction,
  key : String,
  value : JSValue,
) -> Unit {
  self.base[key] = value
}

///|
#alias("_[_]")
pub fn JSFunction::get(self : JSFunction, key : String) -> JSValue {
  match self.base.properties.get(key) {
    Some(v) => v
    None => Undefined
  }
}

///|
#alias("_[_]")
pub fn JSValue::get_property(self : JSValue, name : String) -> JSValue {
  self.get_property_internal(name, self)
}

///|
pub fn JSValue::get_property_internal(
  self : JSValue,
  name : String,
  receiver : JSValue,
) -> JSValue {
  match self {
    Object(obj) => {
      match (obj.proxy_target, obj.proxy_handler) {
        (Some(target), Some(handler)) => {
          let trap = handler.get_property("get")
          match trap {
            Function(f) =>
              return f.context.invoke(f, handler, [
                target,
                JSValue::String(name),
                receiver,
              ]) catch {
                _ => Undefined
              }
            _ => return target.get_property_internal(name, receiver)
          }
        }
        _ => ()
      }
      let is_string_obj = obj.properties.contains("PrimitiveValue") &&
        (match obj.properties.get("PrimitiveValue") {
          Some(String(_)) => true
          _ => false
        })
      if is_string_obj {
        let idx = @strconv.parse_int(name) catch { _ => -1 }
        if idx >= 0 {
          let len = match obj.properties.get("length") {
            Some(Number(n)) => n.to_int()
            _ => 0
          }
          if idx < len {
            let str_val = match obj.properties.get("PrimitiveValue") {
              Some(String(s)) => s
              _ => ""
            }
            let char_code = str_val[idx].to_int()
            let c = match char_code.to_char() {
              Some(c) => c
              None => ' '
            }
            return JSValue::String(String::make(1, c))
          }
        }
      }
      match obj.properties.get(name) {
        Some(v) =>
          match v {
            Internal(Accessor(Some(getter), _)) =>
              getter.context.invoke(getter, receiver, []) catch {
                _ => Undefined
              }
            Internal(Accessor(None, _)) => Undefined
            _ => v
          }
        None =>
          match obj.prototype {
            Some(proto) => proto.get_property_internal(name, receiver)
            None => Undefined
          }
      }
    }
    Function(func) => {
      match (func.base.proxy_target, func.base.proxy_handler) {
        (Some(target), Some(handler)) => {
          let trap = handler.get_property("get")
          match trap {
            Function(f) =>
              return f.context.invoke(f, handler, [
                target,
                JSValue::String(name),
                receiver,
              ]) catch {
                _ => Undefined
              }
            _ => return target.get_property_internal(name, receiver)
          }
        }
        _ => ()
      }
      match func.base.properties.get(name) {
        Some(v) => v
        None =>
          match func.base.prototype {
            Some(proto) => proto.get_property_internal(name, receiver)
            None => Undefined
          }
      }
    }
    Internal(internal) => {
      let proto = match internal {
        Date(_) =>
          match receiver.resolve_in_ctx("Date") {
            Function(f) => f.get("prototype")
            _ => Undefined
          }
        RegExp(_, _) =>
          match receiver.resolve_in_ctx("RegExp") {
            Function(f) => f.get("prototype")
            _ => Undefined
          }
        Map(_) =>
          match receiver.resolve_in_ctx("Map") {
            Function(f) => f.get("prototype")
            _ => Undefined
          }
        Set(_) =>
          match receiver.resolve_in_ctx("Set") {
            Function(f) => f.get("prototype")
            _ => Undefined
          }
        _ => Undefined
      }
      match proto {
        Object(_) | Function(_) => proto.get_property_internal(name, receiver)
        _ => Undefined
      }
    }
    _ => Undefined
  }
}

///|
fn JSValue::resolve_in_ctx(_self : JSValue, _name : String) -> JSValue {
  // This is a hack because we don't have easy access to context here.
  // But wait, many internal objects were created with a context? No.
  // Actually, we can't easily resolve without a context.
  // Let's assume the global object has these.
  Undefined // TODO: implement correctly
}

///|
pub fn JSValue::get_property_throw(
  self : JSValue,
  name : String,
) -> JSValue raise EvalError {
  self.get_property_internal_throw(name, self)
}

///|
pub fn JSValue::get_property_internal_throw(
  self : JSValue,
  name : String,
  receiver : JSValue,
) -> JSValue raise EvalError {
  match self {
    Object(obj) => {
      match (obj.proxy_target, obj.proxy_handler) {
        (Some(target), Some(handler)) => {
          let trap = handler.get_property("get")
          match trap {
            Function(f) =>
              return f.context.invoke(f, handler, [
                target,
                JSValue::String(name),
                receiver,
              ])
            _ => return target.get_property_internal_throw(name, receiver)
          }
        }
        _ => ()
      }
      let is_string_obj = obj.properties.contains("PrimitiveValue") &&
        (match obj.properties.get("PrimitiveValue") {
          Some(String(_)) => true
          _ => false
        })
      if is_string_obj {
        let idx = @strconv.parse_int(name) catch { _ => -1 }
        if idx >= 0 {
          let len = match obj.properties.get("length") {
            Some(Number(n)) => n.to_int()
            _ => 0
          }
          if idx < len {
            let str_val = match obj.properties.get("PrimitiveValue") {
              Some(String(s)) => s
              _ => ""
            }
            let char_code = str_val[idx].to_int()
            let c = match char_code.to_char() {
              Some(c) => c
              None => ' '
            }
            return JSValue::String(String::make(1, c))
          }
        }
      }
      match obj.properties.get(name) {
        Some(v) =>
          match v {
            Internal(Accessor(Some(getter), _)) =>
              getter.context.invoke(getter, receiver, [])
            Internal(Accessor(None, _)) => Undefined
            _ => v
          }
        None =>
          match obj.prototype {
            Some(proto) => proto.get_property_internal_throw(name, receiver)
            None => Undefined
          }
      }
    }
    Function(func) => {
      match (func.base.proxy_target, func.base.proxy_handler) {
        (Some(target), Some(handler)) => {
          let trap = handler.get_property("get")
          match trap {
            Function(f) =>
              return f.context.invoke(f, handler, [
                target,
                JSValue::String(name),
                receiver,
              ])
            _ => return target.get_property_internal_throw(name, receiver)
          }
        }
        _ => ()
      }
      match func.base.properties.get(name) {
        Some(v) => v
        None =>
          match func.base.prototype {
            Some(proto) => proto.get_property_internal_throw(name, receiver)
            None => Undefined
          }
      }
    }
    _ => Undefined
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
    Object({ properties, .. } as obj) => {
      match (obj.proxy_target, obj.proxy_handler) {
        (Some(target), Some(handler)) => {
          let trap = handler.get_property("set")
          match trap {
            Function(f) => {
              let res = f.context.invoke(f, handler, [
                target,
                JSValue::String(name),
                value,
                self,
              ])
              if not(res.is_truthy()) && strict {
                raise EvalError::Throw(
                  JSValue::String("TypeError: Proxy set trap returned false"),
                )
              }
              return
            }
            _ => return target.set_property(name, value, strict~)
          }
        }
        _ => ()
      }
      // Check for accessor
      match properties.get(name) {
        Some(Internal(Accessor(_, Some(setter)))) => {
          let _ = setter.context.invoke(setter, self, [value]) catch {
            e => raise e
          }
          return
        }
        Some(Internal(Accessor(_, None))) => {
          if strict {
            raise EvalError::Throw(
              JSValue::String("TypeError: Cannot assign to read-only accessor"),
            )
          }
          return
        }
        _ => ()
      }
      if obj.is_frozen {
        if strict {
          raise EvalError::Throw(
            JSValue::String("TypeError: Cannot assign to read only property"),
          )
        }
        return
      }
      if not(properties.contains(name)) {
        if not(obj.extensible) || obj.is_sealed {
          if strict {
            raise EvalError::Throw(
              JSValue::String(
                "TypeError: Cannot add property to non-extensible object",
              ),
            )
          }
          return
        }
      }
      // Check for String object length
      let is_string_obj = properties.contains("PrimitiveValue") &&
        (match properties.get("PrimitiveValue") {
          Some(String(_)) => true
          _ => false
        })
      if is_string_obj && name == "length" {
        if strict {
          raise EvalError::Throw(
            JSValue::String(
              "TypeError: Cannot assign to read only property 'length' of String object",
            ),
          )
        }
        return
      }
      if name == "Symbol(Symbol.toStringTag)" ||
        name == "Symbol(Symbol.iterator)" {
        // Heuristic: toStringTag is usually non-writable, iterator is usually writable but let's check spec.
        // Actually, let's just handle toStringTag for now.
        if name == "Symbol(Symbol.toStringTag)" {
          if strict {
            raise EvalError::Throw(
              JSValue::String("TypeError: Cannot assign to read only property"),
            )
          }
          return
        }
      }
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
    }
    Function(func) => {
      match (func.base.proxy_target, func.base.proxy_handler) {
        (Some(target), Some(handler)) => {
          let trap = handler.get_property("set")
          match trap {
            Function(f) => {
              let res = f.context.invoke(f, handler, [
                target,
                JSValue::String(name),
                value,
                self,
              ])
              if not(res.is_truthy()) && strict {
                raise EvalError::Throw(
                  JSValue::String("TypeError: Proxy set trap returned false"),
                )
              }
              return
            }
            _ => return target.set_property(name, value, strict~)
          }
        }
        _ => ()
      }
      // Check for accessor
      match func.base.properties.get(name) {
        Some(Internal(Accessor(_, Some(setter)))) => {
          let _ = setter.context.invoke(setter, self, [value]) catch {
            e => raise e
          }
          return
        }
        Some(Internal(Accessor(_, None))) => {
          if strict {
            raise EvalError::Throw(
              JSValue::String("TypeError: Cannot assign to read-only accessor"),
            )
          }
          return
        }
        _ => ()
      }
      if func.base.is_frozen {
        if strict {
          raise EvalError::Throw(
            JSValue::String("TypeError: Cannot assign to read only property"),
          )
        }
        return
      }
      if not(func.base.properties.contains(name)) {
        if not(func.base.extensible) || func.base.is_sealed {
          if strict {
            raise EvalError::Throw(
              JSValue::String(
                "TypeError: Cannot add property to non-extensible object",
              ),
            )
          }
          return
        }
      }
      if name == "length" || name == "name" {
        if strict {
          raise EvalError::Throw(
            JSValue::String("TypeError: Cannot assign to read only property"),
          )
        }
        return
      }
      // Check if it is a built-in constructor for prototype property
      // Heuristic: if name is String, Number, Boolean, Array, Object, Function, Error...
      // Ideally we should flag this in JSFunction struct.
      // But for now let's check name.
      if name == "prototype" {
        let func_name = func.name.unwrap_or("")
        if func_name == "String" ||
          func_name == "Number" ||
          func_name == "Boolean" ||
          func_name == "Array" ||
          func_name == "Object" ||
          func_name == "Function" ||
          func_name == "Error" ||
          func_name == "Date" ||
          func_name == "RegExp" ||
          func_name == "Map" ||
          func_name == "Set" ||
          func_name == "WeakMap" ||
          func_name == "WeakSet" ||
          func_name == "Promise" {
          if strict {
            raise EvalError::Throw(
              JSValue::String(
                "TypeError: Cannot assign to read only property 'prototype' of built-in constructor",
              ),
            )
          }
          return
        }
      }
      func.base[name] = value
    }
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
    Symbol(_, _) => true
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
    Symbol(_, _) => @double.not_a_number // TypeError in JS usually
  }
}

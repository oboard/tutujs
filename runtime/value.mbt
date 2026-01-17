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
    (Object(a), Object(b)) => a._id == b._id
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
    Object(o) => hasher.combine(o._id)
    Internal(i) => hasher.combine(i)
  }
}

///|
pub(all) enum JSInternal {
  Date(Double)
  RegExp(@regexp.Regexp, String)
  Map(LinkedMap)
  MapIterator(LinkedMap, Ref[LinkedEntry?], String) // map, next_entry, kind
  Set(LinkedMap)
  SetIterator(LinkedMap, Ref[LinkedEntry?], String) // map, next_entry, kind
  Accessor(JSObject?, JSObject?) // Getter, Setter
}

///|
pub impl Eq for JSInternal with equal(self, other) {
  match (self, other) {
    (Date(d1), Date(d2)) => d1 == d2
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
    Date(d) => hasher.combine(d)
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
    Object(o) =>
      if o.is_callable {
        let name = o.call_info.unwrap().name.unwrap_or("anonymous")
        logger.write_string("Function: " + name)
      } else {
        logger.write_string("[object Object]")
      }
    Null => logger.write_string("null")
    Undefined => logger.write_string("undefined")
    Internal(i) => i.output(logger)
  }
}

///|
pub fn JSValue::get_prototype(self : JSValue) -> JSValue? {
  match self {
    Object(o) => o.prototype
    _ => None
  }
}

///|
pub fn JSObject::own_keys(
  self : JSObject,
  ctx : Context,
) -> Array[String] raise EvalError {
  match (self.proxy_target, self.proxy_handler) {
    (Some(target), Some(handler)) => {
      let trap = handler.get_property("ownKeys")
      match trap {
        Object({ is_callable: true, .. } as f) => {
          let keys_list = ctx.invoke(f, handler, [target])
          let len = keys_list.get_property("length").to_number().to_int()
          let keys = []
          for i = 0; i < len; i = i + 1 {
            keys.push(keys_list.get_property(i.to_string()).to_string())
          }
          return keys
        }
        _ =>
          match target {
            Object(t) => return t.own_keys(ctx)
            _ => return []
          }
      }
    }
    _ => ()
  }
  let keys = []
  // String indices
  match self.properties.get("PrimitiveValue") {
    Some(String(s)) =>
      for i = 0; i < s.length(); i = i + 1 {
        keys.push(i.to_string())
      }
    _ => ()
  }
  let integer_keys : Array[Int] = []
  let other_keys : Array[String] = []
  for k, _ in self.properties {
    if not(k.has_prefix("__")) && k != "PrimitiveValue" {
      let idx = @strconv.parse_int(k) catch { _ => -1 }
      if idx >= 0 && idx.to_string() == k {
        integer_keys.push(idx)
      } else {
        other_keys.push(k)
      }
    }
  }
  integer_keys.sort()
  // other_keys.sort() // Keep original order (random/insertion) for strings
  for idx in integer_keys {
    keys.push(idx.to_string())
  }
  for k in other_keys {
    keys.push(k)
  }
  keys
}

///|
pub fn JSValue::to_property_key(self : JSValue) -> String {
  match self {
    String(s) => s.to_string()
    Symbol(id, s) =>
      if id >= 1001 && id <= 1011 && s.has_prefix("Symbol.") {
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
pub(all) struct CallInfo {
  mut name : String?
  params : Array[String]
  body : FunctionBody
  context : Context
  strict : Bool
  is_constructor : Bool
  is_arrow : Bool
} derive(Show, Eq, ToJson)

///|
pub(all) struct JSObject {
  _id : Int
  properties : Map[String, JSValue]
  /// prototype 需要是 Optional（JSValue?），原因：JavaScript 中确实存在“没有原型”的对象。
  mut prototype : JSValue?
  mut extensible : Bool
  mut is_sealed : Bool
  mut is_frozen : Bool
  mut is_proxy : Bool
  mut proxy_target : JSValue?
  mut proxy_handler : JSValue?
  is_callable : Bool
  mut call_info : CallInfo?
} derive(Show, Eq)

///|
pub fn JSObject::new_function(
  name? : String,
  params? : Array[String],
  body~ : FunctionBody,
  context? : Context,
  properties? : Map[String, JSValue],
  prototype? : JSValue,
  strict? : Bool,
  is_constructor? : Bool,
  is_arrow? : Bool,
) -> JSObject {
  let params = params.unwrap_or([])
  let properties = properties.unwrap_or({})
  if not(properties.contains("length")) {
    let len = JSValue::Number(params.length().to_double())
    properties.set("length", len)
    // 设置描述符
    let descriptors = match properties.get("__descriptors") {
      Some(Object(d)) => d
      _ => {
        let d = JSObject::new()
        properties.set("__descriptors", JSValue::Object(d))
        d
      }
    }
    let desc = JSObject::new(properties={
      "enumerable": JSValue::Boolean(false),
      "configurable": JSValue::Boolean(true),
      "writable": JSValue::Boolean(false),
      "value": len,
    })
    descriptors["length"] = JSValue::Object(desc)
  }
  match name {
    Some(n) =>
      if not(properties.contains("name")) {
        let name_val = JSValue::String(n)
        properties["name"] = name_val
        // 设置描述符
        let descriptors = match properties.get("__descriptors") {
          Some(Object(d)) => d
          _ => {
            let d = JSObject::new()
            properties.set("__descriptors", JSValue::Object(d))
            d
          }
        }
        let desc = JSObject::new(properties={
          "enumerable": JSValue::Boolean(false),
          "configurable": JSValue::Boolean(true),
          "writable": JSValue::Boolean(false),
          "value": name_val,
        })
        descriptors["name"] = JSValue::Object(desc)
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
  let is_strict = match strict {
    Some(s) => s
    None =>
      match body {
        User(b) =>
          b.directives.iter().any(fn(d) { d.value.value == "use strict" })
        _ => false
      }
  }
  {
    _id: next_object_id(),
    properties,
    prototype,
    extensible: true,
    is_sealed: false,
    is_frozen: false,
    is_proxy: false,
    proxy_target: None,
    proxy_handler: None,
    is_callable: true,
    call_info: Some({
      name,
      params,
      body,
      context: context.unwrap_or(Context::new()),
      strict: is_strict,
      is_constructor: is_ctor,
      is_arrow: is_arrow.unwrap_or(false),
    }),
  }
}

///|
pub fn JSObject::new(
  properties? : Map[String, JSValue],
  prototype? : JSValue,
) -> JSObject {
  {
    _id: next_object_id(),
    properties: properties.unwrap_or({}),
    prototype,
    extensible: true,
    is_sealed: false,
    is_frozen: false,
    is_proxy: false,
    proxy_target: None,
    proxy_handler: None,
    is_callable: false,
    call_info: None,
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
    properties: {},
    prototype: None,
    extensible: true,
    is_sealed: false,
    is_frozen: false,
    is_proxy: false,
    proxy_target: None,
    proxy_handler: None,
    is_callable: false,
    call_info: None,
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
#alias("_[_]")
pub fn JSValue::get_property(self : JSValue, name : String) -> JSValue {
  self.get_property_throwing(name) catch {
    _ => Undefined
  }
}

///|
pub fn JSValue::get_property_throwing(
  self : JSValue,
  name : String,
) -> JSValue raise EvalError {
  self.get_property_internal_throwing(name, self)
}

///|
pub fn JSValue::get_property_internal_throwing(
  self : JSValue,
  name : String,
  receiver : JSValue,
) -> JSValue raise EvalError {
  match self {
    Object(obj) => {
      match (obj.proxy_target, obj.proxy_handler) {
        (Some(target), Some(handler)) => {
          let trap = handler.get_property_throwing("get") catch {
            _ => Undefined
          }
          match trap {
            Object(f) =>
              if f.is_callable {
                let ctx = f.call_info.unwrap().context
                return ctx.invoke(f, handler, [
                  target,
                  JSValue::String(name),
                  receiver,
                ])
              } else {
                return target.get_property_internal_throwing(name, receiver)
              }
            _ => return target.get_property_internal_throwing(name, receiver)
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
            Internal(Accessor(Some(getter), _)) => {
              let ctx = getter.call_info.unwrap().context
              return ctx.invoke(getter, receiver, [])
            }
            Internal(Accessor(None, _)) => return Undefined
            _ => return v
          }
        None =>
          match obj.prototype {
            Some(proto) =>
              return proto.get_property_internal_throwing(name, receiver)
            None => return Undefined
          }
      }
    }
    Internal(_) => Undefined
    _ => Undefined
  }
}

///|
pub fn JSValue::get_property_internal(
  self : JSValue,
  name : String,
  receiver : JSValue,
) -> JSValue {
  self.get_property_internal_throwing(name, receiver) catch {
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
            Object(f) =>
              if f.is_callable {
                let ctx = f.call_info.unwrap().context
                let res = ctx.invoke(f, handler, [
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
              } else {
                return target.set_property(name, value, strict~)
              }
            _ => return target.set_property(name, value, strict~)
          }
        }
        _ => ()
      }
      // Check for accessor
      match properties.get(name) {
        Some(Internal(Accessor(_, Some(setter)))) => {
          let ctx = setter.call_info.unwrap().context
          let _ = ctx.invoke(setter, self, [value]) catch { e => raise e }
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
        if name == "Symbol(Symbol.toStringTag)" {
          if strict {
            raise EvalError::Throw(
              JSValue::String("TypeError: Cannot assign to read only property"),
            )
          }
          return
        }
      }
      // Check for prototype assignment on built-in constructors
      if obj.is_callable && name == "prototype" {
        let func_name = obj.call_info.unwrap().name.unwrap_or("")
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

      // Check writable descriptor
      let is_writable = match properties.get("__descriptors") {
        Some(Object(d)) =>
          match d.properties.get(name) {
            Some(Object(desc)) =>
              match desc.properties.get("writable") {
                Some(Boolean(b)) => b
                _ => true
              }
            _ => true
          }
        _ => true
      }
      if not(is_writable) {
        if strict {
          raise EvalError::Throw(
            JSValue::String("TypeError: Cannot assign to read only property"),
          )
        }
        return
      }
      match properties.get(name) {
        Some(Internal(Accessor(_, Some(setter)))) => {
          let ctx = setter.call_info.unwrap().context
          let _ = ctx.invoke(setter, self, [value]) catch { _ => Undefined }

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
    _ =>
      if strict {
        raise EvalError::Throw(
          JSValue::String("TypeError: Cannot set property on non-object"),
        )
      }
  }
}

///|
pub fn JSValue::delete_property(
  self : JSValue,
  ctx : Context,
  name : String,
  strict? : Bool = false,
) -> Bool raise EvalError {
  match self {
    Object(obj) => {
      // String object index property is non-configurable
      let is_string_obj = match obj.properties.get("PrimitiveValue") {
        Some(String(_)) => true
        _ => false
      }
      if is_string_obj {
        let idx = @strconv.parse_int(name) catch { _ => -1 }
        if idx >= 0 {
          let len = match obj.properties.get("length") {
            Some(Number(n)) => n.to_int()
            _ => 0
          }
          if idx < len {
            if strict {
              ctx.throw_type_error(
                "Cannot delete property " + name + " of String",
              )
            }
            return false
          }
        }
      }
      if obj.is_proxy {
        match (obj.proxy_target, obj.proxy_handler) {
          (Some(target), Some(handler)) => {
            let trap = handler.get_property("deleteProperty")
            match trap {
              Object(f) =>
                if f.is_callable {
                  let res = ctx.invoke(f, handler, [
                    target,
                    JSValue::String(name),
                  ])
                  let is_truthy = res.is_truthy()
                  if not(is_truthy) && strict {
                    ctx.throw_type_error(
                      "Proxy deleteProperty trap returned false",
                    )
                  }
                  // Invariant check: cannot report true for non-configurable property
                  if is_truthy {
                    let get_own_desc = match ctx.resolve("Object") {
                      Object(obj_ctor) =>
                        obj_ctor.get("getOwnPropertyDescriptor")
                      _ => Undefined
                    }
                    match get_own_desc {
                      Object(get_desc_fn) if get_desc_fn.is_callable => {
                        let desc = ctx.invoke(get_desc_fn, Undefined, [
                          target,
                          JSValue::String(name),
                        ]) catch {
                          _ => Undefined
                        }
                        match desc {
                          Object(d) => {
                            let configurable = match d.get("configurable") {
                              Boolean(b) => b
                              _ => true
                            }
                            if not(configurable) {
                              ctx.throw_type_error(
                                "Proxy deleteProperty trap invariant violated: cannot report true for non-configurable property",
                              )
                            }
                            // Check extensibility invariant
                            let is_ext = match ctx.resolve("Object") {
                              Object(ctor) =>
                                match ctor.get("isExtensible") {
                                  Object(ie) if ie.is_callable =>
                                    ctx
                                    .invoke(ie, Undefined, [target])
                                    .is_truthy()
                                  _ => true
                                }
                              _ => true
                            }
                            if not(is_ext) {
                              ctx.throw_type_error(
                                "Proxy deleteProperty trap invariant violated: cannot report true for existing property on non-extensible target",
                              )
                            }
                          }
                          _ => ()
                        }
                      }
                      _ => ()
                    }
                  }
                  return is_truthy
                } else {
                  ctx.throw_type_error(
                    "Proxy deleteProperty trap is not a function",
                  )
                  return false // Unreachable if throw works
                }
              Undefined | Null =>
                return target.delete_property(ctx, name, strict~)
              _ =>
                ctx.throw_type_error(
                  "Proxy deleteProperty trap is not a function",
                )
            }
          }
          _ =>
            ctx.throw_type_error(
              "Cannot perform 'deleteProperty' on a revoked proxy",
            )
        }
      }
      if obj.is_frozen || obj.is_sealed {
        if strict {
          ctx.throw_type_error("Cannot delete property of sealed/frozen object")
        }
        return false
      }
      // Special case: Function prototype
      if obj.is_callable && name == "prototype" {
        if strict {
          ctx.throw_type_error(
            "Cannot delete non-configurable property prototype",
          )
        }
        return false
      }
      // Check if property is configurable
      let is_configurable = match obj.properties.get("__descriptors") {
        Some(Object(d)) =>
          match d.properties.get(name) {
            Some(Object(desc)) =>
              match desc.properties.get("configurable") {
                Some(Boolean(b)) => b
                _ => true
              }
            _ => true
          }
        _ => true
      }
      // Special case: String object length and indices
      let is_string_obj = obj.properties.contains("PrimitiveValue") &&
        (match obj.properties.get("PrimitiveValue") {
          Some(String(_)) => true
          _ => false
        })
      let is_array = not(obj.is_callable) &&
        not(is_string_obj) &&
        obj.properties.contains("length")
      if is_string_obj || is_array {
        if name == "length" {
          if strict {
            ctx.throw_type_error(
              "Cannot delete non-configurable property length",
            )
          }
          return false
        }
        if is_string_obj {
          let idx = @strconv.parse_int(name) catch { _ => -1 }
          if idx >= 0 {
            let len = match obj.properties.get("length") {
              Some(Number(n)) => n.to_int()
              _ => 0
            }
            if idx < len {
              if strict {
                ctx.throw_type_error(
                  "Cannot delete non-configurable property " + name,
                )
              }
              return false
            }
          }
        }
      }
      if not(is_configurable) {
        if strict {
          ctx.throw_type_error(
            "Cannot delete non-configurable property " + name,
          )
        }
        return false
      }
      obj.properties.remove(name)
      return true
    }
    _ => true
  }
}

///|
pub fn JSValue::is_object(self : JSValue) -> Bool {
  match self {
    Object(_) => true
    _ => false
  }
}

///|
pub fn JSValue::is_truthy(self : JSValue) -> Bool {
  match self {
    String(s) => s.length() > 0
    Number(n) => n != 0.0 && not(n.is_nan())
    Boolean(b) => b
    BigInt(i) => i != 0
    Symbol(_, _) | Object(_) | Internal(_) => true
    Null | Undefined => false
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
    String(s) => parse_js_number(s.to_string())
    Null => 0.0
    Undefined => @double.not_a_number
    Object(_) => @double.not_a_number
    Internal(_) => @double.not_a_number
    BigInt(i) =>
      @strconv.parse_double(i.to_string()) catch {
        _ => @double.not_a_number
      }
    Symbol(_, _) => @double.not_a_number
  }
}

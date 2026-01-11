///|
pub(all) struct Context {
  scope : @hashmap.HashMap[String, JSValue]
  parent : Context?
  mut pending_labels : Array[String]
  mut strict : Bool
} derive(Show)

///|
pub impl ToJson for Context with to_json(_) {
  JSValue::Null.to_json()
}

///|
pub impl FromJson for Context with from_json(_, _) {
  Context::new()
}

///|
pub impl Eq for Context with equal(_, _) {
  // Simple reference equality check if possible, or always false for now
  false
}

///|
#as_free_fn(new)
pub fn Context::new(parent? : Context, strict? : Bool) -> Context {
  let scope = @hashmap.new()
  match parent {
    None => {
      scope.set("NaN", Number(@double.not_a_number))
      scope.set("Infinity", Number(@double.infinity))
    }
    Some(_) => ()
  }
  let is_strict = match strict {
    Some(s) => s
    None =>
      match parent {
        Some(p) => p.strict
        None => false
      }
  }
  { scope, parent, pending_labels: [], strict: is_strict }
}

///|
pub fn Context::resolve(self : Context, name : String) -> JSValue {
  let current = Option::Some(self)
  loop current {
    Some(ctx) =>
      match ctx.scope.get(name) {
        Some(v) => return v
        None => continue ctx.parent
      }
    None => return Undefined
  }
}

///|
#as_free_fn(create_global)
pub fn Context::create_global() -> Context {
  let ctx = Context::new()

  // Object.prototype
  let object_proto_props = @hashmap.new()
  let object_proto = JSObject::{
    properties: object_proto_props,
    prototype: None,
  }
  let object_proto_val = JSValue::Object(object_proto)

  // Function.prototype
  let func_proto_props = @hashmap.new()
  let func_proto = JSObject::{
    properties: func_proto_props,
    prototype: Some(object_proto_val),
  }
  let func_proto_val = JSValue::Object(func_proto)
  init_object_prototype(object_proto_val, func_proto_val)
  init_function_prototype(func_proto_val)

  // Object Constructor
  let object_fn_val = create_object_constructor(
    object_proto_val, func_proto_val,
  )

  // Object.prototype.constructor = Object
  object_proto_props.set("constructor", object_fn_val)
  ctx.scope.set("Object", object_fn_val)

  // Function Constructor
  let func_ctor_val = create_function_constructor(func_proto_val)
  func_proto_props.set("constructor", func_ctor_val)
  ctx.scope.set("Function", func_ctor_val)

  // Array.prototype
  let array_proto_props = @hashmap.new()
  let array_proto = JSObject::{
    properties: array_proto_props,
    prototype: Some(object_proto_val),
  }
  let array_proto_val = JSValue::Object(array_proto)
  init_array_prototype(array_proto_val, func_proto_val)

  // Array Constructor
  let array_fn_body = Native(fn(_ctx, _this_val, args) {
    let arr_props = @hashmap.new()
    let mut len = 0.0
    match args {
      [Number(n)] => len = n
      [arg] => {
        arr_props.set("0", arg)
        len = 1.0
      }
      _ => {
        let mut i = 0
        for arg in args {
          arr_props.set(i.to_string(), arg)
          i = i + 1
        }
        len = i.to_double()
      }
    }
    arr_props.set("length", Number(len))
    Object({ properties: arr_props, prototype: Some(array_proto_val) })
  })
  let array_fn_props = @hashmap.new()
  array_fn_props.set("prototype", array_proto_val)
  let array_fn = JSFunction::new(
    name="Array",
    body=array_fn_body,
    context=ctx,
    properties=array_fn_props,
    prototype=func_proto_val,
  )
  let array_fn_val = JSValue::Function(array_fn)
  init_array_constructor(array_fn_val)

  // Array.prototype.constructor = Array
  array_proto_props.set("constructor", array_fn_val)
  ctx.scope.set("Array", array_fn_val)

  // String.prototype
  let string_proto_props = @hashmap.new()
  let string_proto = JSObject::{
    properties: string_proto_props,
    prototype: Some(object_proto_val),
  }
  let string_proto_val = JSValue::Object(string_proto)
  init_string_prototype(string_proto_val, func_proto_val)

  // String Constructor
  let string_ctor_val = create_string_constructor(
    string_proto_val, func_proto_val,
  )
  string_proto_props.set("constructor", string_ctor_val)
  ctx.scope.set("String", string_ctor_val)

  // Number.prototype
  let number_proto_props = @hashmap.new()
  let number_proto = JSObject::{
    properties: number_proto_props,
    prototype: Some(object_proto_val),
  }
  let number_proto_val = JSValue::Object(number_proto)
  init_number_prototype(number_proto_val, func_proto_val)

  // Number Constructor
  let number_ctor_val = create_number_constructor(
    number_proto_val, func_proto_val,
  )
  number_proto_props.set("constructor", number_ctor_val)
  ctx.scope.set("Number", number_ctor_val)

  // Console Object
  let console_val = create_console_object(object_proto_val)
  ctx.scope.set("console", console_val)

  // Boolean.prototype
  let boolean_proto_props = @hashmap.new()
  let boolean_proto = JSObject::{
    properties: boolean_proto_props,
    prototype: Some(object_proto_val),
  }
  let boolean_proto_val = JSValue::Object(boolean_proto)
  init_boolean_prototype(boolean_proto_val, func_proto_val)

  // Boolean Constructor
  let boolean_ctor_val = create_boolean_constructor(
    boolean_proto_val, func_proto_val,
  )
  boolean_proto_props.set("constructor", boolean_ctor_val)
  ctx.scope.set("Boolean", boolean_ctor_val)

  // Math Object
  let math_val = create_math_object(object_proto_val)
  ctx.scope.set("Math", math_val)

  // Date Object
  let date_val = create_date_object(object_proto_val)
  ctx.scope.set("Date", date_val)

  // JSON Object
  let json_val = create_json_object(object_proto_val)
  ctx.scope.set("JSON", json_val)

  // Symbol.prototype
  let symbol_proto_props = @hashmap.new()
  let symbol_proto = JSObject::{
    properties: symbol_proto_props,
    prototype: Some(object_proto_val),
  }
  let symbol_proto_val = JSValue::Object(symbol_proto)
  init_symbol_prototype(symbol_proto_val, func_proto_val)

  // Symbol Constructor
  let symbol_ctor_val = create_symbol_constructor(
    symbol_proto_val, func_proto_val,
  )
  symbol_proto_props.set("constructor", symbol_ctor_val)
  ctx.scope.set("Symbol", symbol_ctor_val)

  // Error.prototype
  let error_proto_val = create_error_prototype(object_proto_val)

  // Error Constructor
  let error_ctor_val = create_error_constructor(
    "Error", error_proto_val, func_proto_val,
  )
  ctx.scope.set("Error", error_ctor_val)

  // Native Errors
  let native_errors = [
    "EvalError", "RangeError", "ReferenceError", "SyntaxError", "TypeError", "URIError",
  ]
  for name in native_errors {
    let ctor = create_native_error_constructor(
      name, error_proto_val, func_proto_val,
    )
    ctx.scope.set(name, ctor)
  }

  // RegExp Object
  let syntax_error_val = match ctx.scope.get("SyntaxError") {
    Some(v) => v
    None => JSValue::Undefined
  }
  let regexp_val = create_regexp_object(object_proto_val, syntax_error_val)
  ctx.scope.set("RegExp", regexp_val)

  // Reflect Object
  let reflect_val = create_reflect_object(object_proto_val)
  ctx.scope.set("Reflect", reflect_val)

  // Global functions (eval, isNaN, etc.)
  init_global_functions(ctx)
  ctx
}

///|
pub fn Context::get_property(
  self : Context,
  value : JSValue,
  name : String,
) -> JSValue {
  match value {
    Object(_) | Function(_) => value.get_property(name)
    String(s) =>
      if name == "length" {
        JSValue::Number(s.length().to_double())
      } else {
        match self.resolve("String") {
          Function(f) =>
            match f.properties.get("prototype") {
              Some(proto) => proto.get_property(name)
              None => Undefined
            }
          _ => Undefined
        }
      }
    Number(_) =>
      match self.resolve("Number") {
        Function(f) =>
          match f.properties.get("prototype") {
            Some(proto) => proto.get_property(name)
            None => Undefined
          }
        _ => Undefined
      }
    Boolean(_) =>
      match self.resolve("Boolean") {
        Function(f) =>
          match f.properties.get("prototype") {
            Some(proto) => proto.get_property(name)
            None => Undefined
          }
        _ => Undefined
      }
    _ => Undefined
  }
}

///|
pub impl Compare for Context with compare(_, _) -> Int {
  0
}

///|
pub impl Hash for Context with hash_combine(_, _) -> Unit {
  // Not implemented
}

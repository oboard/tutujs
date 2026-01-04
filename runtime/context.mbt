///|
pub(all) struct Context {
  scope : @hashmap.HashMap[String, JSValue]
  parent : Context?
} derive(Show)

///|
pub impl Eq for Context with equal(_, _) {
  // Simple reference equality check if possible, or always false for now
  false
}

///|
pub impl ToJson for Context with to_json(_) {
  JSValue::Null.to_json()
}

///|
pub impl FromJson for Context with from_json(_, _) {
  Context::new()
}

///|
#as_free_fn(new)
pub fn Context::new(parent? : Context) -> Context {
  let scope = @hashmap.new()
  match parent {
    None => {
      scope.set("NaN", Number(@double.not_a_number))
      scope.set("Infinity", Number(@double.infinity))
    }
    Some(_) => ()
  }
  { scope, parent }
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
  init_object_prototype(object_proto_val)

  // Function.prototype
  let func_proto_props = @hashmap.new()
  let func_proto = JSObject::{
    properties: func_proto_props,
    prototype: Some(object_proto_val),
  }
  let func_proto_val = JSValue::Object(func_proto)
  init_function_prototype(func_proto_val)

  // Object Constructor
  let object_fn_body = Native(fn(_ctx, _this_val, args) {
    if args.length() > 0 {
      let val = args[0]
      match val {
        Object(_) => val
        Null | Undefined =>
          Object({
            properties: @hashmap.new(),
            prototype: Some(object_proto_val),
          })
        _ => val // TODO: Box primitive
      }
    } else {
      Object({ properties: @hashmap.new(), prototype: Some(object_proto_val) })
    }
  })
  let object_fn_props = @hashmap.new()
  object_fn_props.set("prototype", object_proto_val)
  let object_fn = JSFunction::new(
    name="Object",
    body=object_fn_body,
    context=ctx,
    properties=object_fn_props,
    prototype=func_proto_val,
  )
  let object_fn_val = JSValue::Function(object_fn)

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
  init_array_prototype(array_proto_val)

  // Array Constructor
  let array_fn_body = Native(fn(_ctx, _this_val, args) {
    let arr_props = @hashmap.new()
    let mut len = 0.0
    if args.length() == 1 {
      match args[0] {
        Number(n) => len = n
        _ => {
          arr_props.set("0", args[0])
          len = 1.0
        }
      }
    } else {
      for i, arg in args {
        arr_props.set(i.to_string(), arg)
      }
      len = args.length().to_double()
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
  init_string_prototype(string_proto_val)

  // String Constructor
  let string_ctor_val = create_string_constructor(string_proto_val)
  string_proto_props.set("constructor", string_ctor_val)
  ctx.scope.set("String", string_ctor_val)

  // Number.prototype
  let number_proto_props = @hashmap.new()
  let number_proto = JSObject::{
    properties: number_proto_props,
    prototype: Some(object_proto_val),
  }
  let number_proto_val = JSValue::Object(number_proto)
  init_number_prototype(number_proto_val)

  // Number Constructor
  let number_ctor_val = create_number_constructor(number_proto_val)
  number_proto_props.set("constructor", number_ctor_val)
  ctx.scope.set("Number", number_ctor_val)

  // Boolean.prototype
  let boolean_proto_props = @hashmap.new()
  let boolean_proto = JSObject::{
    properties: boolean_proto_props,
    prototype: Some(object_proto_val),
  }
  let boolean_proto_val = JSValue::Object(boolean_proto)
  init_boolean_prototype(boolean_proto_val)

  // Boolean Constructor
  let boolean_ctor_val = create_boolean_constructor(boolean_proto_val)
  boolean_proto_props.set("constructor", boolean_ctor_val)
  ctx.scope.set("Boolean", boolean_ctor_val)

  // Math Object
  let math_val = create_math_object(object_proto_val)
  ctx.scope.set("Math", math_val)
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

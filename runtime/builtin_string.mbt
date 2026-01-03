///|
pub fn init_string_prototype(string_proto_val : JSValue) -> Unit {
  match string_proto_val {
    Object(obj) => {
      // toString
      let to_string_fn = Native(fn(_ctx, this_val, _args) {
        match this_val {
          String(s) => JSValue::String(s)
          Object(o) =>
            match o.properties.get("PrimitiveValue") {
              Some(String(s)) => JSValue::String(s)
              _ => JSValue::String("[object String]") // Fallback
            }
          _ => JSValue::String("")
        }
      })
      let to_string_obj = JSFunction::{
        name: Some("toString"),
        params: [],
        body: to_string_fn,
        context: Context::new(),
        properties: @hashmap.new(),
        prototype: None,
      }
      obj.properties.set("toString", JSValue::Function(to_string_obj))

      // valueOf
      let value_of_fn = Native(fn(_ctx, this_val, _args) {
        match this_val {
          String(s) => JSValue::String(s)
          Object(o) =>
            match o.properties.get("PrimitiveValue") {
              Some(String(s)) => JSValue::String(s)
              _ => JSValue::String("") // Should throw TypeError in strict compliance
            }
          _ => JSValue::String("")
        }
      })
      let value_of_obj = JSFunction::{
        name: Some("valueOf"),
        params: [],
        body: value_of_fn,
        context: Context::new(),
        properties: @hashmap.new(),
        prototype: None,
      }
      obj.properties.set("valueOf", JSValue::Function(value_of_obj))

      // charAt
      let char_at_fn = Native(fn(_ctx, this_val, args) {
        let s = match this_val {
          String(str) => str
          Object(o) =>
            match o.properties.get("PrimitiveValue") {
              Some(String(str)) => str
              _ => ""
            }
          _ => ""
        }
        let pos = if args.length() > 0 {
          match args[0] {
            Number(n) => n.to_int()
            _ => 0
          }
        } else {
          0
        }
        if pos >= 0 && pos < s.length() {
          let char_code = s[pos].to_int()
          let c = match char_code.to_char() {
            Some(c) => c
            None => ' '
          }
          JSValue::String(String::make(1, c))
        } else {
          JSValue::String("")
        }
      })
      let char_at_obj = JSFunction::{
        name: Some("charAt"),
        params: [],
        body: char_at_fn,
        context: Context::new(),
        properties: @hashmap.new(),
        prototype: None,
      }
      obj.properties.set("charAt", JSValue::Function(char_at_obj))
    }
    _ => ()
  }
}

///|
pub fn create_string_constructor(proto : JSValue) -> JSValue {
  let ctor_fn = Native(fn(_ctx, _this_val, args) {
    let val = if args.length() > 0 { args[0].to_string() } else { "" }
    // If called as constructor (new String), should return object wrapping string.
    // But we need to detect 'new'. 
    // Current Native implementation doesn't easily distinguish 'new' vs 'call' unless we pass a flag or check 'this'.
    // For now, let's assume if it returns a non-object, NewExpression handles wrapping?
    // No, NewExpression expects the constructor to return an Object.

    // We need a way to return a String Object.
    // JSValue::Object with internal slot.

    let str_obj = JSValue::Object({
      properties: @hashmap.new(),
      prototype: Some(proto),
    })
    match str_obj {
      Object(o) => {
        o.properties.set("PrimitiveValue", JSValue::String(val))
        o.properties.set("length", JSValue::Number(val.length().to_double()))
      }
      _ => ()
    }
    str_obj
  })
  let ctor_obj = JSFunction::{
    name: Some("String"),
    params: [],
    body: ctor_fn,
    context: Context::new(),
    properties: @hashmap.new(),
    prototype: None,
  }
  ctor_obj.properties.set("prototype", proto)
  JSValue::Function(ctor_obj)
}

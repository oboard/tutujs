///|
pub fn init_string_prototype(string_proto_val : JSValue) -> Unit {
  match string_proto_val {
    Object(obj) => {
      // toString
      let to_string_fn = Native(fn(_ctx, this_val, _args) {
        match this_val {
          String(s) => JSValue::String(s)
          Object({ properties: { "PrimitiveValue": String(s), .. }, .. }) =>
            JSValue::String(s)
          _ => JSValue::String("")
        }
      })
      let to_string_obj = JSFunction::new(name="toString", body=to_string_fn)
      obj.properties.set("toString", JSValue::Function(to_string_obj))

      // valueOf
      let value_of_fn = Native(fn(_ctx, this_val, _args) {
        match this_val {
          String(s) => JSValue::String(s)
          Object({ properties: { "PrimitiveValue": String(s), .. }, .. }) =>
            JSValue::String(s)
          _ => JSValue::String("")
        }
      })
      let value_of_obj = JSFunction::new(name="valueOf", body=value_of_fn)
      obj.properties.set("valueOf", JSValue::Function(value_of_obj))

      // charAt
      let char_at_fn = Native(fn(_ctx, this_val, args) {
        let s = match this_val {
          String(str) => str
          Object({ properties: { "PrimitiveValue": String(str), .. }, .. }) =>
            str
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
      let char_at_obj = JSFunction::new(name="charAt", body=char_at_fn)
      obj.properties.set("charAt", JSValue::Function(char_at_obj))
    }
    _ => ()
  }
}

///|
pub fn create_string_constructor(proto : JSValue) -> JSValue {
  let ctor_fn = Native(fn(_ctx, this_val, args) {
    let val = if args.length() > 0 { args[0].to_string() } else { "" }
    let is_constructor = match this_val {
      Object(o) =>
        match o.prototype {
          Some(p) =>
            match (p, proto) {
              (Object(a), Object(b)) =>
                physical_equal(a.properties, b.properties)
              _ => false
            }
          None => false
        }
      _ => false
    }
    if is_constructor {
      match this_val {
        Object(o) => {
          o.properties.set("PrimitiveValue", JSValue::String(val))
          o.properties.set("length", JSValue::Number(val.length().to_double()))
        }
        _ => ()
      }
      JSValue::String(val)
    } else {
      JSValue::String(val)
    }
  })
  let ctor_obj = JSFunction::new(name="String", body=ctor_fn)
  ctor_obj.properties.set("prototype", proto)
  JSValue::Function(ctor_obj)
}

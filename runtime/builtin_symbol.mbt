///|
pub fn init_symbol_prototype(symbol_proto_val : JSValue) -> Unit {
  match symbol_proto_val {
    Object(obj) => {
      // toString
      let to_string_fn = Native(fn(_ctx, this_val, _args) {
        match this_val {
          Symbol(s) => JSValue::String("Symbol(" + s + ")")
          _ => JSValue::String("Symbol()")
        }
      })
      let to_string_obj = JSFunction::new(name="toString", body=to_string_fn)
      obj["toString"] = JSValue::Function(to_string_obj)
    }
    _ => ()
  }
}

///|
pub fn create_symbol_constructor(
  symbol_proto_val : JSValue,
  func_proto_val : JSValue,
) -> JSValue {
  let ctor_fn = Native(fn(_ctx, _this_val, args) {
    let desc = match args {
      [String(s), ..] => s.to_string()
      _ => ""
    }
    // Note: This does not guarantee uniqueness, which is not spec compliant.
    // TODO: Implement unique symbols
    JSValue::Symbol(desc)
  })
  let ctor = JSFunction::new(
    name="Symbol",
    body=ctor_fn,
    prototype=func_proto_val,
  )
  let ctor_val = JSValue::Function(ctor)
  match ctor_val {
    Function(f) => {
      f.properties["prototype"] = symbol_proto_val
      f.properties["iterator"] = JSValue::Symbol("Symbol.iterator")
    }
    _ => ()
  }
  ctor_val
}

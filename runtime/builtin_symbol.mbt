///|
pub fn init_symbol_prototype(
  symbol_proto_val : JSValue,
  func_proto : JSValue,
) -> Unit {
  match symbol_proto_val {
    Object(obj) => {
      // toString
      let to_string_fn = Native(fn(_ctx, this_val, _args) {
        match this_val {
          Symbol(_, s) => JSValue::String("Symbol(" + s + ")")
          _ => JSValue::String("Symbol()")
        }
      })
      let to_string_obj = JSFunction::new(
        name="toString",
        body=to_string_fn,
        prototype=func_proto,
      )
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
    JSValue::Symbol(next_object_id(), desc)
  })
  let ctor = JSFunction::new(
    name="Symbol",
    body=ctor_fn,
    prototype=func_proto_val,
    is_constructor=true,
  )
  let ctor_val = JSValue::Function(ctor)
  match ctor_val {
    Function(f) => {
      f.properties["prototype"] = symbol_proto_val
      f.properties["iterator"] = JSValue::Symbol(1001, "Symbol.iterator")
      f.properties["toStringTag"] = JSValue::Symbol(1002, "Symbol.toStringTag")
      f.properties["hasInstance"] = JSValue::Symbol(1003, "Symbol.hasInstance")
      f.properties["isConcatSpreadable"] = JSValue::Symbol(
        1004, "Symbol.isConcatSpreadable",
      )
      f.properties["match"] = JSValue::Symbol(1005, "Symbol.match")
      f.properties["replace"] = JSValue::Symbol(1006, "Symbol.replace")
      f.properties["search"] = JSValue::Symbol(1007, "Symbol.search")
      f.properties["species"] = JSValue::Symbol(1008, "Symbol.species")
      f.properties["split"] = JSValue::Symbol(1009, "Symbol.split")
      f.properties["toPrimitive"] = JSValue::Symbol(1010, "Symbol.toPrimitive")
      f.properties["unscopables"] = JSValue::Symbol(1011, "Symbol.unscopables")
    }
    _ => ()
  }
  ctor_val
}

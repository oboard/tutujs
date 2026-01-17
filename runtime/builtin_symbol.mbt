///|
pub fn init_symbol_prototype(
  symbol_proto_val : JSValue,
  func_proto : JSValue,
) -> Unit {
  match symbol_proto_val {
    Object(obj) => {
      // toString
      let to_string_obj = JSObject::new_function(
        name="toString",
        body=Native(fn(_ctx, this_val, _args) {
          match this_val {
            Symbol(_, s) => JSValue::String("Symbol(" + s + ")")
            _ => JSValue::String("Symbol()")
          }
        }),
        prototype=func_proto,
      )
      obj["toString"] = JSValue::Object(to_string_obj)
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
  let ctor = JSObject::new_function(
    name="Symbol",
    body=ctor_fn,
    prototype=func_proto_val,
    is_constructor=true,
    properties={
      "prototype": symbol_proto_val,
      "iterator": JSValue::Symbol(1001, "Symbol.iterator"),
      "toStringTag": JSValue::Symbol(1002, "Symbol.toStringTag"),
      "hasInstance": JSValue::Symbol(1003, "Symbol.hasInstance"),
      "isConcatSpreadable": JSValue::Symbol(1004, "Symbol.isConcatSpreadable"),
      "match": JSValue::Symbol(1005, "Symbol.match"),
      "replace": JSValue::Symbol(1006, "Symbol.replace"),
      "search": JSValue::Symbol(1007, "Symbol.search"),
      "species": JSValue::Symbol(1008, "Symbol.species"),
      "split": JSValue::Symbol(1009, "Symbol.split"),
      "toPrimitive": JSValue::Symbol(1010, "Symbol.toPrimitive"),
      "unscopables": JSValue::Symbol(1011, "Symbol.unscopables"),
    },
  )
  JSValue::Object(ctor)
}

///|
pub fn init_boolean_prototype(boolean_proto_val : JSValue) -> Unit {
  match boolean_proto_val {
    Object(obj) => {
      // valueOf
      let value_of_fn = Native(fn(_ctx, this_val, _args) {
        JSValue::Boolean(
          match this_val {
            Boolean(b) => b
            Object({ properties: { "PrimitiveValue": Boolean(b), .. }, .. }) =>
              b
            _ => false // Should throw TypeError
          },
        )
      })
      let value_of_obj = JSFunction::new(name="valueOf", body=value_of_fn)
      obj["valueOf"] = JSValue::Function(value_of_obj)

      // toString
      let to_string_fn = Native(fn(_ctx, this_val, _args) {
        let val = match this_val {
          Boolean(b) => b
          Object({ properties: { "PrimitiveValue": Boolean(b), .. }, .. }) => b
          _ => false
        }
        JSValue::String(val.to_string())
      })
      let to_string_obj = JSFunction::new(name="toString", body=to_string_fn)
      obj["toString"] = JSValue::Function(to_string_obj)
    }
    _ => ()
  }
}

///|
pub fn create_boolean_constructor(
  proto : JSValue,
  func_proto : JSValue,
) -> JSValue {
  let ctor_fn = Native(fn(_ctx, this_val, args) {
    let val = if args is [arg0, ..] { arg0.is_truthy() } else { false }
    let is_constructor = match (this_val, proto) {
      (
        Object({ prototype: Some(Object({ properties: p1, .. })), .. }),
        Object({ properties: p2, .. }),
      ) => physical_equal(p1, p2)
      _ => false
    }
    if is_constructor {
      match this_val {
        Object({ properties, .. }) =>
          properties["PrimitiveValue"] = JSValue::Boolean(val)
        _ => ()
      }
      JSValue::Boolean(val)
    } else {
      JSValue::Boolean(val)
    }
  })
  let ctor_obj = JSFunction::new(
    name="Boolean",
    params=["value"],
    body=ctor_fn,
    prototype=func_proto,
  )
  ctor_obj["prototype"] = proto
  JSValue::Function(ctor_obj)
}

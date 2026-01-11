///|
pub fn create_bigint_constructor(
  bigint_proto : JSValue,
  func_proto : JSValue,
) -> JSValue {
  let bigint_fn_body = Native(fn(_ctx, _this_val, args) {
    if args is [val, ..] {
      match val {
        BigInt(_) => val
        _ => JSValue::BigInt(BigInt::from_int(0)) // TODO: ToBigInt conversion
      }
    } else {
      JSValue::BigInt(BigInt::from_int(0))
    }
  })
  let bigint_fn = JSFunction::new(
    name="BigInt",
    params=["value"],
    body=bigint_fn_body,
    prototype=func_proto,
    is_constructor=false, // BigInt cannot be called with 'new'
  )
  bigint_fn["prototype"] = bigint_proto
  JSValue::Function(bigint_fn)
}

///|
pub fn init_bigint_prototype(
  bigint_proto_val : JSValue,
  func_proto : JSValue,
) -> Unit {
  match bigint_proto_val {
    Object(obj) => {
      // valueOf
      let value_of_fn = Native(fn(_ctx, this_val, _args) {
        match this_val {
          BigInt(n) => JSValue::BigInt(n)
          Object({ properties, .. }) =>
            match properties.get("PrimitiveValue") {
              Some(BigInt(n)) => JSValue::BigInt(n)
              _ => JSValue::BigInt(BigInt::from_int(0))
            }
          _ => JSValue::BigInt(BigInt::from_int(0))
        }
      })
      let value_of_obj = JSFunction::new(
        name="valueOf",
        body=value_of_fn,
        prototype=func_proto,
      )
      obj["valueOf"] = JSValue::Function(value_of_obj)

      // toString
      let to_string_fn = Native(fn(_ctx, this_val, _args) {
        let val = match this_val {
          BigInt(n) => n
          Object({ properties, .. }) =>
            match properties.get("PrimitiveValue") {
              Some(BigInt(n)) => n
              _ => BigInt::from_int(0)
            }
          _ => BigInt::from_int(0)
        }
        JSValue::String(val.to_string())
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

///|
pub fn init_number_prototype(
  number_proto_val : JSValue,
  func_proto : JSValue,
) -> Unit {
  match number_proto_val {
    Object(obj) => {
      obj.properties.set("PrimitiveValue", JSValue::Number(0.0))
      // valueOf
      let value_of_fn = Native(fn(_ctx, this_val, _args) {
        match this_val {
          Number(n) => JSValue::Number(n)
          Object(obj) =>
            match obj.properties.get("PrimitiveValue") {
              Some(Number(n)) => JSValue::Number(n)
              _ => JSValue::Number(0.0) // Should throw TypeError
            }
          _ => JSValue::Number(0.0)
        }
      })
      let value_of_obj = JSObject::new_function(
        name="valueOf",
        body=value_of_fn,
        prototype=func_proto,
      )
      obj["valueOf"] = JSValue::Object(value_of_obj)

      // toString
      let to_string_fn = Native(fn(_ctx, this_val, _args) {
        let val = match this_val {
          Number(n) => n
          Object(obj) =>
            match obj.properties.get("PrimitiveValue") {
              Some(Number(n)) => n
              _ => @double.not_a_number // Should throw TypeError
            }
          _ => @double.not_a_number
        }

        // TODO: Handle radix properly
        JSValue::String(val.to_string())
      })
      let to_string_obj = JSObject::new_function(
        name="toString",
        body=to_string_fn,
        prototype=func_proto,
      )
      obj["toString"] = JSValue::Object(to_string_obj)

      // toFixed
      let to_fixed_fn = Native(fn(_ctx, this_val, args) {
        let val = match this_val {
          Number(n) => n
          Object({ properties: { "PrimitiveValue": Number(n), .. }, .. }) => n
          _ => 0.0
        }
        let f = if args is [arg0, ..] {
          let n = arg0.to_number().to_int()
          if n < 0 || n > 100 {
            -1
          } else {
            n
          }
        } else {
          0
        }
        if f == -1 {
          return JSValue::String(
            "RangeError: toFixed() digits argument must be between 0 and 100",
          )
        }
        if val.is_nan() {
          return JSValue::String("NaN")
        }
        if val.abs() >= 1.0e21 {
          return JSValue::String(val.to_string())
        }
        let sign = if val < 0.0 { "-" } else { "" }
        let x = val.abs()
        try {
          // Exact formatting using BigInt
          let bits = x.reinterpret_as_int64()
          let mant_mask = 0xFFFFFFFFFFFFFL
          let exp_mask = 0x7FFL
          let mant_bits = bits & mant_mask
          let exp_bits = (bits >> 52) & exp_mask
          let (e, m) = if exp_bits == 0L {
            // Subnormal
            (-1074, mant_bits)
          } else {
            // Normal
            (exp_bits.to_int() - 1023 - 52, mant_bits | 0x10000000000000L)
          }

          // Value is m * 2^e
          // We want round(m * 2^e * 10^f)
          // = round(m * 2^e * 2^f * 5^f)
          // = round(m * 5^f * 2^(e+f))

          let m_big = @bigint.BigInt::from_int64(m)
          let five_big = @bigint.BigInt::from_int(5)
          let pow5 = five_big.pow(@bigint.BigInt::from_int(f))
          let num = m_big * pow5
          let k = e + f
          let res_big = if k >= 0 {
            num << k
          } else {
            let shift = -k
            let rounding = @bigint.BigInt::from_int(1) << (shift - 1)
            (num + rounding) >> shift
          }
          let s = res_big.to_string()
          if f == 0 {
            JSValue::String(sign + s)
          } else {
            let len = s.length()
            if len <= f {
              let padding = "0".repeat(f + 1 - len)
              let padded = padding + s
              let dot_pos = padded.length() - f
              let int_part = padded[0:dot_pos].to_string()
              let frac_part = padded[dot_pos:].to_string()
              JSValue::String(sign + int_part + "." + frac_part)
            } else {
              let dot_pos = len - f
              let int_part = s[0:dot_pos].to_string()
              let frac_part = s[dot_pos:].to_string()
              JSValue::String(sign + int_part + "." + frac_part)
            }
          }
        } catch {
          _ => JSValue::String("RangeError: Internal error in toFixed")
        }
      })
      let to_fixed_obj = JSObject::new_function(
        name="toFixed",
        body=to_fixed_fn,
        prototype=func_proto,
      )
      obj["toFixed"] = JSValue::Object(to_fixed_obj)
    }
    _ => ()
  }
}

///|
pub fn create_number_constructor(
  ctx : Context,
  proto : JSValue,
  func_proto : JSValue,
) -> JSValue {
  let ctor_fn = Native(fn(ctx, this_val, args) raise EvalError {
    let val = if args is [arg0, ..] { js_to_number(ctx, arg0) } else { 0.0 }
    match this_val {
      Object(obj) => {
        // Check if called as constructor (this_val has Number.prototype)
        let is_ctor = match (obj.prototype, proto) {
          (Some(p1), Object(p2)) => p1.strict_equal(JSValue::Object(p2))
          _ => false
        }
        if is_ctor {
          obj.properties.set("PrimitiveValue", JSValue::Number(val))
          return JSValue::Undefined // Result of constructor call is ignored if it's primitive
        }
      }
      _ => ()
    }
    JSValue::Number(val)
  })
  let ctor_obj = JSObject::new_function(
    name="Number",
    params=["value"],
    body=ctor_fn,
    prototype=func_proto,
    is_constructor=true,
  )
  ctor_obj["prototype"] = proto
  let set_readonly_prop = fn(name : String, val : JSValue) {
    ctor_obj[name] = val
    let descriptors = match ctor_obj.properties.get("__descriptors") {
      Some(Object(d)) => d
      _ => {
        let d = JSObject::new()
        ctor_obj.properties.set("__descriptors", JSValue::Object(d))
        d
      }
    }
    let desc = JSObject::new(properties={
      "enumerable": JSValue::Boolean(false),
      "configurable": JSValue::Boolean(false),
      "writable": JSValue::Boolean(false),
      "value": val,
    })
    descriptors[name] = JSValue::Object(desc)
  }
  let set_std_prop = fn(name : String, val : JSValue) {
    ctor_obj[name] = val
    let descriptors = match ctor_obj.properties.get("__descriptors") {
      Some(Object(d)) => d
      _ => {
        let d = JSObject::new()
        ctor_obj.properties.set("__descriptors", JSValue::Object(d))
        d
      }
    }
    let desc = JSObject::new(properties={
      "enumerable": JSValue::Boolean(false),
      "configurable": JSValue::Boolean(true),
      "writable": JSValue::Boolean(true),
      "value": val,
    })
    descriptors[name] = JSValue::Object(desc)
  }
  set_readonly_prop("MAX_VALUE", JSValue::Number(1.7976931348623157e308))
  set_readonly_prop("MIN_VALUE", JSValue::Number(5.0e-324))
  set_readonly_prop("NaN", JSValue::Number(@double.not_a_number))
  set_readonly_prop("NEGATIVE_INFINITY", JSValue::Number(-@double.infinity))
  set_readonly_prop("POSITIVE_INFINITY", JSValue::Number(@double.infinity))
  set_readonly_prop("EPSILON", JSValue::Number(2.220446049250313e-16))
  set_readonly_prop("MAX_SAFE_INTEGER", JSValue::Number(9007199254740991.0))
  set_readonly_prop("MIN_SAFE_INTEGER", JSValue::Number(-9007199254740991.0))

  // parseInt & parseFloat
  match ctx.resolve("parseInt") {
    Object(_) as f => set_std_prop("parseInt", f)
    _ => ()
  }
  match ctx.resolve("parseFloat") {
    Object(_) as f => set_std_prop("parseFloat", f)
    _ => ()
  }
  JSValue::Object(ctor_obj)
}

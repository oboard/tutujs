///|
pub fn init_number_prototype(
  number_proto_val : JSValue,
  func_proto : JSValue,
) -> Unit {
  match number_proto_val {
    Object(obj) => {
      // valueOf
      let value_of_fn = Native(fn(_ctx, this_val, _args) {
        match this_val {
          Number(n) => JSValue::Number(n)
          Object({ properties: { "PrimitiveValue": Number(n), .. }, .. }) =>
            JSValue::Number(n)
          _ => JSValue::Number(0.0) // Should throw TypeError
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
          Number(n) => n
          Object({ properties: { "PrimitiveValue": Number(n), .. }, .. }) => n
          _ => @double.not_a_number // Should throw TypeError
        }

        // TODO: Handle radix properly
        // For now we just return standard string representation
        JSValue::String(val.to_string())
      })
      let to_string_obj = JSFunction::new(
        name="toString",
        body=to_string_fn,
        prototype=func_proto,
      )
      obj["toString"] = JSValue::Function(to_string_obj)

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
      let to_fixed_obj = JSFunction::new(
        name="toFixed",
        body=to_fixed_fn,
        prototype=func_proto,
      )
      obj["toFixed"] = JSValue::Function(to_fixed_obj)
    }
    _ => ()
  }
}

///|
pub fn create_number_constructor(
  proto : JSValue,
  func_proto : JSValue,
) -> JSValue {
  let ctor_fn = Native(fn(ctx, this_val, args) {
    let val = if args is [arg0, ..] {
      js_to_number(ctx, arg0) catch {
        _ => @double.not_a_number
      }
    } else {
      0.0
    }
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
          properties["PrimitiveValue"] = JSValue::Number(val)
        _ => ()
      }
    }
    JSValue::Number(val)
  })
  let ctor_obj = JSFunction::new(
    name="Number",
    params=["value"],
    body=ctor_fn,
    prototype=func_proto,
  )
  ctor_obj["prototype"] = proto
  ctor_obj["MAX_VALUE"] = JSValue::Number(1.7976931348623157e308)
  ctor_obj["MIN_VALUE"] = JSValue::Number(5.0e-324)
  ctor_obj["NaN"] = JSValue::Number(@double.not_a_number)
  ctor_obj["NEGATIVE_INFINITY"] = JSValue::Number(-@double.infinity)
  ctor_obj["POSITIVE_INFINITY"] = JSValue::Number(@double.infinity)
  JSValue::Function(ctor_obj)
}

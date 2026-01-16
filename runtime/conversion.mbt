///|
pub fn to_primitive(
  ctx : Context,
  val : JSValue,
  hint? : String,
) -> JSValue raise EvalError {
  match val {
    Object(_) | Function({ inner: _, .. }) => {
      // 1. Check Symbol.toPrimitive
      let to_prim_key = JSValue::Symbol(1010, "Symbol.toPrimitive").to_property_key()
      match val.get_property_throwing(to_prim_key) {
        Function(f) => {
          let h = match hint {
            Some("String") => JSValue::String("string")
            Some("Number") => JSValue::String("number")
            _ => JSValue::String("default")
          }
          let res = ctx.invoke(f, val, [h])
          match res {
            Object(_) | Function(_) =>
              ctx.throw_type_error("Symbol.toPrimitive must return a primitive")
            _ => return res
          }
        }
        _ => ()
      }

      // 2. Default hint for Date is String
      let is_date = match val {
        Object({ properties, .. })
        | Function({ inner: { properties, .. }, .. }) => {
          let toStringTag = JSValue::Symbol(1011, "Symbol.toStringTag").to_property_key()
          properties.contains("__internal_date__") ||
          properties.get(toStringTag) == Some(JSValue::String("Date"))
        }
        _ => false
      }
      let effective_hint = match hint {
        Some(h) => h
        None => if is_date { "String" } else { "Number" }
      }
      let method_names = if effective_hint == "String" {
        ["toString", "valueOf"]
      } else {
        ["valueOf", "toString"]
      }
      for name in method_names {
        match val.get_property_throwing(name) {
          Function(f) => {
            let res = ctx.invoke(f, val, [])
            match res {
              Object(_) | Function(_) => ()
              _ => return res
            }
          }
          _ => ()
        }
      }
      ctx.throw_type_error("Cannot convert object to primitive")
      JSValue::Undefined
    }
    _ => val
  }
}

///|
pub fn js_to_string(ctx : Context, val : JSValue) -> String raise EvalError {
  match val {
    String(s) => s.to_string()
    Undefined => "undefined"
    Null => "null"
    Boolean(true) => "true"
    Boolean(false) => "false"
    Number(n) =>
      if n.is_nan() {
        "NaN"
      } else if n.is_inf() {
        if n > 0.0 {
          "Infinity"
        } else {
          "-Infinity"
        }
      } else {
        let s = n.to_string()
        if s.has_suffix(".0") {
          s[0:s.length() - 2].to_string() catch {
            _ => s
          }
        } else {
          s
        }
      }
    Symbol(_) => {
      ctx.throw_type_error("Cannot convert a Symbol value to a string")
      ""
    }
    Object(_) | Function(_) => {
      let prim = to_primitive(ctx, val, hint="String")
      js_to_string(ctx, prim)
    }
    BigInt(i) => i.to_string()
    Internal(_) => "[internal]"
  }
}

///|
pub fn js_to_number(ctx : Context, val : JSValue) -> Double raise EvalError {
  match val {
    Number(n) => n
    Undefined => @double.not_a_number
    Null | Boolean(false) => 0.0
    Boolean(true) => 1.0
    String(s) =>
      @strconv.parse_double(s.to_string()) catch {
        _ => @double.not_a_number
      }
    Symbol(_) => {
      ctx.throw_type_error("Cannot convert a Symbol value to a number")
      0.0
    }
    BigInt(i) =>
      @strconv.parse_double(i.to_string()) catch {
        _ => @double.not_a_number
      }
    Object(_) | Function(_) => {
      let prim = to_primitive(ctx, val, hint="Number")
      js_to_number(ctx, prim)
    }
    Internal(_) => @double.not_a_number
  }
}

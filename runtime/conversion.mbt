///|
pub fn to_primitive(
  ctx : Context,
  val : JSValue,
  hint? : String,
) -> JSValue raise EvalError {
  match val {
    Object(_) | Function(_) => {
      let method_names = if hint == Some("String") {
        ["toString", "valueOf"]
      } else {
        ["valueOf", "toString"]
      }
      for name in method_names {
        let method_ = match val {
          Object(_) | Function(_) =>
            match val.get_property(name) {
              Function(_) as f => f
              _ => Undefined
            }
          _ => Undefined
        }
        match method_ {
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
      // The throw_type_error raises EvalError, so this line is unreachable but satisfies type checker if it returns Unit?
      // Wait, throw_type_error returns Unit raise EvalError.
      // match requires returning JSValue.
      // If throw_type_error raises, it never returns.
      // MoonBit compiler should handle this.
      JSValue::Undefined // Unreachable
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
    Null => 0.0
    Boolean(true) => 1.0
    Boolean(false) => 0.0
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

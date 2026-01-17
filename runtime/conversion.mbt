///|
pub fn to_primitive(
  ctx : Context,
  val : JSValue,
  hint? : String,
) -> JSValue raise EvalError {
  match val {
    Object(_) => {
      // 1. Check Symbol.toPrimitive
      let to_prim_key = JSValue::Symbol(1010, "Symbol.toPrimitive").to_property_key()
      match val.get_property_throwing(to_prim_key) {
        Object(f) =>
          if f.is_callable {
            let h = match hint {
              Some("String") => JSValue::String("string")
              Some("Number") => JSValue::String("number")
              _ => JSValue::String("default")
            }
            let res = ctx.invoke(f, val, [h])
            match res {
              Object(_) =>
                ctx.throw_type_error(
                  "Symbol.toPrimitive must return a primitive",
                )
              _ => return res
            }
          }
        _ => ()
      }

      // 2. Default hint for Date is String
      let is_date = match val {
        Object({ properties, .. }) => {
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
          Object(f) =>
            if f.is_callable {
              let res = ctx.invoke(f, val, [])
              match res {
                Object(_) => ()
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
    Object(_) => {
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
    String(s) => parse_js_number(s.to_string())
    Symbol(_) => {
      ctx.throw_type_error("Cannot convert a Symbol value to a number")
      0.0
    }
    BigInt(i) => {
      let s = i.to_string()
      if s == "0" || s == "-0" {
        return 0.0
      }
      @strconv.parse_double(s) catch {
        _ => {
          let mut is_neg = false
          if s.length() > 0 && s[0].to_int() == 0x2D {
            is_neg = true
          }
          if is_neg {
            -@double.infinity
          } else {
            @double.infinity
          }
        }
      }
    }
    Object(_) => {
      let prim = to_primitive(ctx, val, hint="Number")
      js_to_number(ctx, prim)
    }
    Internal(_) => @double.not_a_number
  }
}

///|

///|
pub fn parse_js_number(s : String) -> Double {
  let mut start = 0
  let mut end = s.length()
  while start < end && is_js_whitespace(s[start].to_int()) {
    start = start + 1
  }
  while end > start && is_js_whitespace(s[end - 1].to_int()) {
    end = end - 1
  }
  let s_str = s.substring(start~, end~)
  if s_str == "" {
    return 0.0
  }
  if s_str.contains("_") {
    return @double.not_a_number
  }
  if s_str.to_lower() == "infinity" {
    if s_str == "Infinity" || s_str == "+Infinity" {
      return @double.infinity
    }
    if s_str == "-Infinity" {
      return -@double.infinity
    }
    return @double.not_a_number
  }
  if s_str.length() >= 2 && s_str[0].to_int() == 0x30 { // '0'
    let s1 = s_str[1].to_int()
    let mut second = s1
    if s1 == 0x58 || s1 == 0x78 { // 'X' || 'x'
      second = 0x78 // 'x'
    } else if s1 == 0x4F || s1 == 0x6F { // 'O' || 'o'
      second = 0x6F // 'o'
    } else if s1 == 0x42 || s1 == 0x62 { // 'B' || 'b'
      second = 0x62 // 'b'
    }
    if second == 0x78 { // 'x'
      let rest = s_str.substring(start=2)
      if rest == "" {
        return @double.not_a_number
      }
      let res = @strconv.parse_int(rest, base=16) catch { _ => -1 }
      if res == -1 {
        return @double.not_a_number
      }
      return res.to_double()
    } else if second == 0x6F { // 'o'
      let rest = s_str.substring(start=2)
      if rest == "" {
        return @double.not_a_number
      }
      let res = @strconv.parse_int(rest, base=8) catch { _ => -1 }
      if res == -1 {
        return @double.not_a_number
      }
      return res.to_double()
    } else if second == 0x62 { // 'b'
      let rest = s_str.substring(start=2)
      if rest == "" {
        return @double.not_a_number
      }
      let res = @strconv.parse_int(rest, base=2) catch { _ => -1 }
      if res == -1 {
        return @double.not_a_number
      }
      return res.to_double()
    }
  }
  let mut val = @strconv.parse_double(s_str) catch { _ => @double.not_a_number }
  // Handle overflow for scientific notation
  if val.is_nan() && s_str.to_lower().contains("e") {
    let mut e_idx = -1
    for i = 0; i < s_str.length(); i = i + 1 {
      let c = s_str[i].to_int()
      if c == 0x65 || c == 0x45 {
        e_idx = i
        break
      }
    }
    if e_idx != -1 {
      let mut exp_s = s_str.substring(start=e_idx + 1)
      if exp_s.length() > 0 && exp_s[0].to_int() == 0x2B { // '+'
        exp_s = exp_s.substring(start=1)
      }
      let exp = @strconv.parse_int(exp_s) catch { _ => 0 }
      if exp > 308 {
        let mut is_neg = false
        if s_str.length() > 0 && s_str[0].to_int() == 0x2D {
          is_neg = true
        }
        val = if is_neg { -@double.infinity } else { @double.infinity }
      }
    }
  }
  val
}

///|
fn is_js_whitespace(code : Int) -> Bool {
  match code {
    0x0009 | 0x000A | 0x000B | 0x000C | 0x000D | 0x0020 | 0x00A0 | 0xFEFF =>
      true
    _ =>
      code == 0x2028 ||
      code == 0x2029 ||
      code == 0x1680 ||
      (code >= 0x2000 && code <= 0x200A) ||
      code == 0x202F ||
      code == 0x205F ||
      code == 0x3000
  }
}

///|
fn parse_int_radix(s : String, radix : Int) -> Double {
  let mut res = 0.0
  let len = s.length()
  for i = 0; i < len; i = i + 1 {
    match s.get(i) {
      Some(c) => {
        let mut digit = -1
        if c == '0' {
          digit = 0
        } else if c == '1' {
          digit = 1
        } else if c == '2' {
          digit = 2
        } else if c == '3' {
          digit = 3
        } else if c == '4' {
          digit = 4
        } else if c == '5' {
          digit = 5
        } else if c == '6' {
          digit = 6
        } else if c == '7' {
          digit = 7
        } else if c == '8' {
          digit = 8
        } else if c == '9' {
          digit = 9
        } else if c == 'a' || c == 'A' {
          digit = 10
        } else if c == 'b' || c == 'B' {
          digit = 11
        } else if c == 'c' || c == 'C' {
          digit = 12
        } else if c == 'd' || c == 'D' {
          digit = 13
        } else if c == 'e' || c == 'E' {
          digit = 14
        } else if c == 'f' || c == 'F' {
          digit = 15
        }
        if digit == -1 || digit >= radix {
          return @double.not_a_number
        }
        res = res * radix.to_double() + digit.to_double()
      }
      None => break
    }
  }
  res
}

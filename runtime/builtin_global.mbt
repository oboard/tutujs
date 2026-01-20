///|
pub fn init_global_functions(ctx : Context) -> Unit {
  // eval
  let eval_fn = Native(fn(ctx, _this, args) {
    if args.length() == 0 {
      return Undefined
    }
    let code = args[0]
    match code {
      String(s) =>
        match ctx.eval_safe_annex_b(s) {
          Ok(v) => v
          Err(_) => {
            ctx.throw_syntax_error("Syntax error in eval")
            Undefined
          }
        }
      _ => code
    }
  })
  let eval_obj = JSObject::new_function(name="eval", body=eval_fn)
  ctx.register_builtin("eval", JSValue::Object(eval_obj))

  // isNaN
  let is_nan_fn = Native(fn(_ctx, _this, args) {
    if args.length() == 0 {
      return Boolean(true)
    }
    let n = js_to_number(_ctx, args[0]) catch { _ => @double.not_a_number }
    Boolean(n.is_nan())
  })
  let is_nan_obj = JSObject::new_function(name="isNaN", body=is_nan_fn)
  ctx.register_builtin("isNaN", JSValue::Object(is_nan_obj))

  // isFinite
  let is_finite_fn = Native(fn(_ctx, _this, args) {
    if args.length() == 0 {
      return Boolean(false)
    }
    let n = js_to_number(_ctx, args[0]) catch { _ => @double.not_a_number }
    Boolean(not(n.is_nan()) && not(n.is_inf()))
  })
  let is_finite_obj = JSObject::new_function(name="isFinite", body=is_finite_fn)
  ctx.register_builtin("isFinite", JSValue::Object(is_finite_obj))

  // parseInt
  let parse_int_fn = Native(fn(_ctx, _this, args) {
    if args.length() == 0 {
      return Number(@double.not_a_number)
    }
    let s = js_to_string(_ctx, args[0]) catch { _ => "NaN" }
    // let radix = if args.length() > 1 {
    //   js_to_number(_ctx, args[1]) catch {
    //     _ => 0.0
    //   }
    // } else {
    //   0.0
    // }
    // Simple implementation delegating to MoonBit's parsing if possible or simplified
    // TODO: proper radix support
    let res = @strconv.parse_double(s) catch { _ => @double.not_a_number }
    Number(res.floor())
  })
  let parse_int_obj = JSObject::new_function(name="parseInt", body=parse_int_fn)
  ctx.register_builtin("parseInt", JSValue::Object(parse_int_obj))

  // parseFloat
  let parse_float_fn = Native(fn(_ctx, _this, args) {
    if args.length() == 0 {
      return Number(@double.not_a_number)
    }
    let s = js_to_string(_ctx, args[0]) catch { _ => "NaN" }
    let res = @strconv.parse_double(s) catch { _ => @double.not_a_number }
    Number(res)
  })
  let parse_float_obj = JSObject::new_function(
    name="parseFloat",
    body=parse_float_fn,
  )
  ctx.register_builtin("parseFloat", JSValue::Object(parse_float_obj))

  // TypedArrays (Dummies)
  let typed_array_fn = Native(fn(_ctx, _this, _args) {
    let obj = JSObject::new()
    JSValue::Object(obj)
  })
  let typed_arrays = [
    "Int8Array", "Uint8Array", "Uint8ClampedArray", "Int16Array", "Uint16Array",
    "Int32Array", "Uint32Array", "Float32Array", "Float64Array", "BigInt64Array",
    "BigUint64Array",
  ]
  for name in typed_arrays {
    let ctor = JSObject::new_function(
      name~,
      body=typed_array_fn,
      is_constructor=true,
    )
    ctx.register_builtin(name, JSValue::Object(ctor))
  }

  // BigInt
  let bigint_fn = Native(fn(_ctx, _this, args) {
    if args.length() == 0 {
      return BigInt(BigInt::from_int(0))
    }
    let val = args[0].to_string()
    JSValue::BigInt(BigInt::from_string(val))
  })
  let bigint_ctor = JSObject::new_function(name="BigInt", body=bigint_fn)
  ctx.register_builtin("BigInt", JSValue::Object(bigint_ctor))

  // Set, WeakMap, WeakSet, WeakRef (Dummies)
  let dummy_ctor_fn = Native(fn(_ctx, _this, _args) {
    JSValue::Object(JSObject::new())
  })
  let dummies = ["WeakMap", "WeakSet", "WeakRef"]
  for name in dummies {
    let ctor = JSObject::new_function(
      name~,
      body=dummy_ctor_fn,
      is_constructor=true,
    )
    ctx.register_builtin(name, JSValue::Object(ctor))
  }

  // Helper function to convert number to hex character
  let to_hex_char = fn(n : Int) -> Char {
    if n >= 0 && n <= 9 {
      Int::unsafe_to_char('0' + n)
    } else if n >= 10 && n <= 15 {
      Int::unsafe_to_char('A' + n - 10)
    } else {
      '0'
    }
  }

  // Helper function to parse hex string to int
  let parse_hex = fn(hex_str : String) -> Int? {
    if hex_str.length() == 0 {
      return None
    }
    let mut result = 0
    for i = 0; i < hex_str.length(); i = i + 1 {
      let c = hex_str[i]
      let digit = match c {
        '0'..='9' => c.to_int() - '0'.to_int()
        'A'..='F' => c.to_int() - 'A'.to_int() + 10
        'a'..='f' => c.to_int() - 'a'.to_int() + 10
        _ => return None
      }
      result = result * 16 + digit
    }
    Some(result)
  }

  // escape function (Annex B)
  let escape_fn = Native(fn(_ctx, _this, args) {
    if args.length() == 0 {
      return String("")
    }
    let str = js_to_string(_ctx, args[0]) catch { _ => "" }
    let result = StringBuilder::new()
    for i = 0; i < str.length(); i = i + 1 {
      let code = str.code_unit_at(i)
      if code < 256 {
        // Characters below 256: escape as %XX
        match code.to_int() {
          48..=57 | 65..=90 | 97..=122 | 64 | 42 | 43 | 45 | 46 | 47 | 95 =>
            // Don't escape these characters: 0-9, A-Z, a-z, @, *, +, -, ., /, _
            result.write_char(code.to_char().unwrap_or('?'))
          _ => {
            // Escape as %XX
            result.write_char('%')
            let hex1 = to_hex_char(code.to_int() / 16)
            let hex2 = to_hex_char(code.to_int() % 16)
            result.write_char(hex1)
            result.write_char(hex2)
          }
        }
      } else {
        // Characters 256+: escape as %uXXXX
        result.write_char('%')
        result.write_char('u')
        let code_int = code.to_int()
        let hex1 = to_hex_char(code_int / 4096)
        let hex2 = to_hex_char(code_int / 256 % 16)
        let hex3 = to_hex_char(code_int / 16 % 16)
        let hex4 = to_hex_char(code_int % 16)
        result.write_char(hex1)
        result.write_char(hex2)
        result.write_char(hex3)
        result.write_char(hex4)
      }
    }
    String(result.to_string())
  })
  let escape_obj = JSObject::new_function(name="escape", body=escape_fn)
  ctx.register_builtin("escape", JSValue::Object(escape_obj))

  // unescape function (Annex B)
  let unescape_fn = Native(fn(_ctx, _this, args) {
    if args.length() == 0 {
      return String("undefined")
    }
    let str = js_to_string(_ctx, args[0]) catch { _ => "" }
    let result = StringBuilder::new()
    let mut i = 0
    let len = str.length()
    while i < len {
      let c = str[i]
      if c == '%' && i + 1 < len {
        let next_char = str[i + 1]
        if next_char == 'u' && i + 5 < len {
          // %uXXXX format (4 hex digits)
          let hex_view = str[i + 2:i + 6] catch { _ => "" }
          let hex_str = hex_view.to_string()
          match parse_hex(hex_str) {
            Some(code) => {
              match code.to_char() {
                Some(char) => result.write_char(char)
                None => result.write_char('?')
              }
              i = i + 6
              continue
            }
            None => {
              // Invalid hex, just copy the %u
              result.write_char('%')
              result.write_char('u')
              i = i + 2
              continue
            }
          }
        } else if i + 2 < len {
          // %XX format (2 hex digits)
          let hex_view = str[i + 1:i + 3] catch { _ => "" }
          let hex_str = hex_view.to_string()
          match parse_hex(hex_str) {
            Some(code) => {
              if code >= 0 && code <= 255 {
                match code.to_char() {
                  Some(char) => result.write_char(char)
                  None => result.write_char('?')
                }
              } else {
                // Invalid code, just copy the %
                result.write_char('%')
              }
              i = i + 3
              continue
            }
            None => {
              // Invalid hex, just copy the %
              result.write_char('%')
              i = i + 1
              continue
            }
          }
        } else {
          // Not enough characters for hex, just copy the %
          result.write_char('%')
          i = i + 1
          continue
        }
      } else {
        // Regular character, just copy it
        result.write_char(c.to_char().unwrap_or('?'))
        i = i + 1
      }
    } else {
      String(result.to_string())
    }
  })
  let unescape_obj = JSObject::new_function(name="unescape", body=unescape_fn)
  ctx.register_builtin("unescape", JSValue::Object(unescape_obj))
}

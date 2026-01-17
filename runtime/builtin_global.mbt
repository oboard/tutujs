///|
pub fn init_global_functions(ctx : Context) -> Unit {
  // eval
  let eval_fn = Native(fn(ctx, _this, args) {
    if args.length() == 0 {
      return Undefined
    }
    let code = args[0]
    match code {
      String(s) => {
        let lexer = @lexer.Lexer::new(s.to_string())
        let tokens = lexer.tokenize()
        try {
          let program = @parser.parse(tokens)
          let mut result = JSValue::Undefined
          for stmt in program.body {
            result = ctx.evaluate(Statement(stmt))
          }
          result
        } catch {
          _ => {
            ctx.throw_syntax_error("Syntax error in eval")
            Undefined
          }
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
}

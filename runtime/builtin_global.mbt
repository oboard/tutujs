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
  let eval_obj = JSFunction::new(name="eval", body=eval_fn)
  ctx.scope.set("eval", JSValue::Function(eval_obj))

  // isNaN
  let is_nan_fn = Native(fn(_ctx, _this, args) {
    if args.length() == 0 {
      return Boolean(true)
    }
    let n = js_to_number(_ctx, args[0]) catch { _ => @double.not_a_number }
    Boolean(n.is_nan())
  })
  let is_nan_obj = JSFunction::new(name="isNaN", body=is_nan_fn)
  ctx.scope.set("isNaN", JSValue::Function(is_nan_obj))

  // isFinite
  let is_finite_fn = Native(fn(_ctx, _this, args) {
    if args.length() == 0 {
      return Boolean(false)
    }
    let n = js_to_number(_ctx, args[0]) catch { _ => @double.not_a_number }
    Boolean(not(n.is_nan()) && not(n.is_inf()))
  })
  let is_finite_obj = JSFunction::new(name="isFinite", body=is_finite_fn)
  ctx.scope.set("isFinite", JSValue::Function(is_finite_obj))

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
  let parse_int_obj = JSFunction::new(name="parseInt", body=parse_int_fn)
  ctx.scope.set("parseInt", JSValue::Function(parse_int_obj))

  // parseFloat
  let parse_float_fn = Native(fn(_ctx, _this, args) {
    if args.length() == 0 {
      return Number(@double.not_a_number)
    }
    let s = js_to_string(_ctx, args[0]) catch { _ => "NaN" }
    let res = @strconv.parse_double(s) catch { _ => @double.not_a_number }
    Number(res)
  })
  let parse_float_obj = JSFunction::new(name="parseFloat", body=parse_float_fn)
  ctx.scope.set("parseFloat", JSValue::Function(parse_float_obj))

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
    let ctor = JSFunction::new(name~, body=typed_array_fn, is_constructor=true)
    ctx.scope.set(name, JSValue::Function(ctor))
  }

  // BigInt
  let bigint_fn = Native(fn(_ctx, _this, args) {
    if args.length() == 0 {
      return BigInt(BigInt::from_int(0))
    }
    let val = args[0].to_string()
    JSValue::BigInt(BigInt::from_string(val))
  })
  let bigint_ctor = JSFunction::new(name="BigInt", body=bigint_fn)
  ctx.scope.set("BigInt", JSValue::Function(bigint_ctor))

  // Set, WeakMap, WeakSet, WeakRef (Dummies)
  let dummy_ctor_fn = Native(fn(_ctx, _this, _args) {
    JSValue::Object(JSObject::new())
  })
  let dummies = ["WeakMap", "WeakSet", "WeakRef"]
  for name in dummies {
    let ctor = JSFunction::new(name~, body=dummy_ctor_fn, is_constructor=true)
    ctx.scope.set(name, JSValue::Function(ctor))
  }
}

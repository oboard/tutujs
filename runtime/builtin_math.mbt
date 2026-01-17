///|
pub fn create_math_object(object_proto : JSValue) -> JSValue {
  let math_props = {
    "E": JSValue::Number(2.718281828459045),
    "LN10": JSValue::Number(2.302585092994046),
    "LN2": JSValue::Number(0.6931471805599453),
    "LOG10E": JSValue::Number(0.4342944819032518),
    "LOG2E": JSValue::Number(1.4426950408889634),
    "PI": JSValue::Number(3.141592653589793),
    "SQRT1_2": JSValue::Number(0.7071067811865476),
    "SQRT2": JSValue::Number(1.4142135623730951),
  }

  // Methods
  let wrap_unary = fn(op : (Double) -> Double) {
    Native(fn(_ctx, _this_val, args) {
      JSValue::Number(
        if args is [n, ..] {
          let n = n.to_number()
          op(n)
        } else {
          @double.not_a_number
        },
      )
    })
  }
  let wrap_binary = fn(op : (Double, Double) -> Double) {
    Native(fn(_ctx, _this_val, args) {
      let x = if args is [arg0, ..] {
        arg0.to_number()
      } else {
        @double.not_a_number
      }
      let y = if args is [_, arg1, ..] {
        arg1.to_number()
      } else {
        @double.not_a_number
      }
      JSValue::Number(op(x, y))
    })
  }
  let install_method = fn(name : String, func : FunctionBody) {
    math_props.set(
      name,
      JSValue::Object(JSObject::new_function(name~, body=func)),
    )
  }

  // abs
  install_method("abs", wrap_unary(fn(n) { if n < 0.0 { -n } else { n } }))

  // acos
  install_method("acos", wrap_unary(@math.acos))

  // acosh
  install_method("acosh", wrap_unary(@math.acosh))

  // asin
  install_method("asin", wrap_unary(@math.asin))

  // asinh
  install_method("asinh", wrap_unary(@math.asinh))

  // atan
  install_method("atan", wrap_unary(@math.atan))

  // atanh
  install_method("atanh", wrap_unary(@math.atanh))

  // atan2
  install_method("atan2", wrap_binary(@math.atan2))

  // cbrt
  install_method("cbrt", wrap_unary(@math.cbrt))

  // ceil
  install_method("ceil", wrap_unary(@math.ceil))

  // clz32
  // TODO: Implement clz32

  // cos
  install_method("cos", wrap_unary(@math.cos))

  // cosh
  install_method("cosh", wrap_unary(@math.cosh))

  // exp
  install_method("exp", wrap_unary(@math.exp))

  // expm1
  install_method("expm1", wrap_unary(@math.expm1))

  // floor
  install_method("floor", wrap_unary(@math.floor))

  // fround
  // TODO: Implement fround

  // hypot
  // JS hypot takes any number of arguments, @math.hypot takes 2
  let hypot_fn = Native(fn(_ctx, _this_val, args) {
    let mut result = 0.0
    let mut i = 0
    for arg in args {
      let n = arg.to_number()
      if n.is_nan() {
        result = @double.not_a_number
        break
      }
      // Using generic Pythagorean addition: sqrt(sum(squares))
      // Or iteratively using hypot?
      // JS Spec: Math.hypot(v1, v2, ...) = sqrt(v1^2 + v2^2 + ...)
      // But careful about overflow.
      // If we use @math.hypot iteratively: hypot(a, b, c) = hypot(hypot(a, b), c)
      // This preserves precision and avoids overflow.
      if i == 0 {
        result = n.abs() // hypot(n) = abs(n)
      } else {
        result = @math.hypot(result, n)
      }
      i = i + 1
    }
    JSValue::Number(result)
  })
  install_method("hypot", hypot_fn)

  // imul
  // TODO: Implement imul

  // log
  install_method("log", wrap_unary(@math.ln))

  // log1p
  install_method("log1p", wrap_unary(@math.ln_1p))

  // log10
  install_method("log10", wrap_unary(@math.log10))

  // log2
  install_method("log2", wrap_unary(@math.log2))

  // pow
  install_method("pow", wrap_binary(@math.pow))

  // round
  install_method("round", wrap_unary(@math.round))

  // sign
  let sign_fn = Native(fn(_ctx, _this_val, args) {
    JSValue::Number(
      if args is [arg0, ..] {
        let n = arg0.to_number()
        if n.is_nan() {
          @double.not_a_number
        } else if n == 0.0 {
          n // Preserves +0 and -0
        } else if n > 0.0 {
          1.0
        } else {
          -1.0
        }
      } else {
        @double.not_a_number
      },
    )
  })
  install_method("sign", sign_fn)

  // sin
  install_method("sin", wrap_unary(@math.sin))

  // sinh
  install_method("sinh", wrap_unary(@math.sinh))

  // sqrt
  install_method("sqrt", wrap_unary(fn(n) { @math.pow(n, 0.5) }))

  // tan
  install_method("tan", wrap_unary(@math.tan))

  // tanh
  install_method("tanh", wrap_unary(@math.tanh))

  // trunc
  install_method("trunc", wrap_unary(@math.trunc))

  // max
  let max_fn = Native(fn(_ctx, _this_val, args) {
    let mut max_val = @double.neg_infinity
    for arg in args {
      let n = arg.to_number()
      if n.is_nan() {
        max_val = @double.not_a_number
        break
      }
      if n > max_val {
        max_val = n
      }
    }
    JSValue::Number(max_val)
  })
  install_method("max", max_fn)

  // min
  let min_fn = Native(fn(_ctx, _this_val, args) {
    let mut min_val = @double.infinity
    for arg in args {
      let n = arg.to_number()
      if n.is_nan() {
        min_val = @double.not_a_number
        break
      }
      if n < min_val {
        min_val = n
      }
    }
    JSValue::Number(min_val)
  })
  install_method("min", min_fn)

  // random
  let random_fn = Native(fn(_ctx, _this_val, _args) {
    // TODO: Use a real random number generator
    JSValue::Number(0.5)
  })
  install_method("random", random_fn)
  JSValue::Object(JSObject::new(properties=math_props, prototype=object_proto))
}

///|
pub fn init_function_prototype(func_proto_val : JSValue) -> Unit {
  match func_proto_val {
    Object(obj) => {
      // toString
      let to_string_fn = Native(fn(_ctx, this_val, _args) {
        match this_val {
          Object(f) =>
            if f.is_callable {
              // Basic implementation: return "function() { [native code] }" or source if available
              // For now, simple stub
              let name = f.call_info.unwrap().name.unwrap_or("anonymous")
              JSValue::String("function \{name}() { [native code] }")
            } else {
              JSValue::String("function() { [native code] }")
            }
          _ =>
            // In ES3/5, Function.prototype.toString.call(non-function) throws TypeError
            // For now return generic string
            JSValue::String("function() { [native code] }")
        }
      })
      let to_string_obj = JSObject::new_function(
        name="toString",
        body=to_string_fn,
        prototype=func_proto_val,
      )
      obj["toString"] = JSValue::Object(to_string_obj)

      // call (ES3)
      let call_fn = Native(fn(ctx, this_val, args) {
        match this_val {
          Object(f) =>
            if f.is_callable {
              let this_arg = if args is [arg0, ..] {
                arg0
              } else {
                JSValue::Undefined
              }
              let call_args = []
              match args {
                [_, .. rest] =>
                  for arg in rest {
                    call_args.push(arg)
                  }
                _ => ()
              }

              // println("call_fn invoke: this_arg=\{this_arg}, args=\{call_args}")
              ctx.invoke(f, this_arg, call_args) catch {
                EvalError::Return(v) => v
                e => raise e
              }
            } else {
              JSValue::Undefined
            }
          _ => JSValue::Undefined // TypeError
        }
      })
      let call_obj = JSObject::new_function(
        name="call",
        body=call_fn,
        prototype=func_proto_val,
      )
      obj["call"] = JSValue::Object(call_obj)

      // apply (ES3)
      let apply_fn = Native(fn(ctx, this_val, args) {
        match this_val {
          Object(f) =>
            if f.is_callable {
              let this_arg = if args is [arg0, ..] {
                arg0
              } else {
                JSValue::Undefined
              }
              let call_args = []
              if args is [_, arg1, ..] {
                match arg1 {
                  Object({ properties, .. }) => {
                    let len = match properties.get("length") {
                      Some(Number(n)) => n.to_int()
                      _ => 0
                    }
                    for i = 0; i < len; i = i + 1 {
                      match properties.get(i.to_string()) {
                        Some(val) => call_args.push(val)
                        None => call_args.push(JSValue::Undefined)
                      }
                    }
                  }
                  _ => ()
                }
              }
              ctx.invoke(f, this_arg, call_args) catch {
                _ => JSValue::Undefined
              }
            } else {
              JSValue::Undefined
            }
          _ => JSValue::Undefined
        }
      })
      let apply_obj = JSObject::new_function(
        name="apply",
        body=apply_fn,
        prototype=func_proto_val,
      )
      obj["apply"] = JSValue::Object(apply_obj)

      // bind (ES5)
      let bind_fn = Native(fn(_ctx, this_val, args) {
        match this_val {
          Object(f) =>
            if f.is_callable {
              let this_arg = if args is [arg0, ..] {
                arg0
              } else {
                JSValue::Undefined
              }
              let bound_args = []
              if args is [_, .. rest] {
                for arg in rest {
                  bound_args.push(arg)
                }
              }
              let bound_fn_body = Native(fn(ctx, _this, call_args) {
                let final_args = []
                for arg in bound_args {
                  final_args.push(arg)
                }
                for arg in call_args {
                  final_args.push(arg)
                }
                ctx.invoke(f, this_arg, final_args)
              })
              let bound_obj = JSObject::new_function(
                name="bound " + f.call_info.unwrap().name.unwrap_or(""),
                body=bound_fn_body,
                prototype=func_proto_val,
              )
              JSValue::Object(bound_obj)
            } else {
              JSValue::Undefined
            }
          _ => JSValue::Undefined // TypeError
        }
      })
      let bind_obj = JSObject::new_function(
        name="bind",
        body=bind_fn,
        prototype=func_proto_val,
      )
      obj["bind"] = JSValue::Object(bind_obj)
    }
    _ => ()
  }
}

///|
pub fn create_function_constructor(proto : JSValue) -> JSValue {
  let ctor_fn = Native(fn(ctx, _this_val, args) {
    // new Function(p1, p2, body)
    // 1. Concatenate params
    // 2. Parse
    // 3. Return new function

    // Argument handling
    let mut params_str = ""
    let mut body_str = ""
    match args {
      [] => ()
      _ => {
        let mut last_arg = JSValue::Undefined
        let mut first = true
        for arg in args {
          if not(first) {
            if params_str != "" {
              params_str = params_str + ","
            }
            params_str = params_str + last_arg.to_string()
          }
          last_arg = arg
          first = false
        }
        body_str = last_arg.to_string()
      }
    }

    // Construct source code
    // We need to parse: "function anonymous(" + params_str + ") { " + body_str + " }"
    // But our parser parses Programs or Expressions.
    // "function ..." is a FunctionDeclaration (Statement) or FunctionExpression.

    let source = "(function anonymous(\{params_str}) {\n\{body_str}\n})"

    // We need to invoke parser.
    let tokens = source |> @lexer.parse
    let parser = @parser.Parser::new(tokens)
    let program = parser.parse_program()
    if parser.errors.length() > 0 {
      ctx.throw_syntax_error("Invalid function body: " + parser.errors[0])
    }
    if program.body.length() > 0 {
      match program.body[0] {
        @parser.Statement::ExpressionStatement(
          { expression: @parser.Expression::FunctionExpression(_) as expr, .. }
        ) => {
          let mut root = ctx
          loop root.parent {
            Some(p) => {
              root = p
              continue p.parent
            }
            None => break
          }
          root.evaluate(Expression(expr)) catch {
            _ => JSValue::Undefined
          }
        }
        _ => ctx.throw_syntax_error("Invalid function body")
      }
    } else {
      ctx.throw_syntax_error("Invalid function body")
    }
  })
  let ctor_obj = JSObject::new_function(
    name="Function",
    body=ctor_fn,
    prototype=proto,
    is_constructor=true,
  )
  ctor_obj["prototype"] = proto
  JSValue::Object(ctor_obj)
}

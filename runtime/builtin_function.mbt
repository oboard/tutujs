///|
pub fn init_function_prototype(func_proto_val : JSValue) -> Unit {
  match func_proto_val {
    Object(obj) => {
      // toString
      let to_string_fn = Native(fn(_ctx, this_val, _args) {
        match this_val {
          Function(f) => {
            // Basic implementation: return "function() { [native code] }" or source if available
            // For now, simple stub
            let name = f.name.unwrap_or("anonymous")
            JSValue::String("function \{name}() { [native code] }")
          }
          _ =>
            // In ES3/5, Function.prototype.toString.call(non-function) throws TypeError
            // For now return generic string
            JSValue::String("function() { [native code] }")
        }
      })
      let to_string_obj = JSFunction::{
        name: Some("toString"),
        params: [],
        body: to_string_fn,
        context: Context::new(),
        properties: @hashmap.new(),
        prototype: None,
      }
      obj.properties.set("toString", JSValue::Function(to_string_obj))

      // call (ES3)
      let call_fn = Native(fn(ctx, this_val, args) {
        match this_val {
          Function(f) => {
            let this_arg = if args.length() > 0 {
              args[0]
            } else {
              JSValue::Undefined
            }
            let call_args = []
            for i = 1; i < args.length(); i = i + 1 {
              call_args.push(args[i])
            }

            // println("call_fn invoke: this_arg=\{this_arg}, args=\{call_args}")
            ctx.invoke(f, this_arg, call_args) catch {
              _ => JSValue::Undefined
            }
          }
          _ => JSValue::Undefined // TypeError
        }
      })
      let call_obj = JSFunction::{
        name: Some("call"),
        params: [],
        body: call_fn,
        context: Context::new(),
        properties: @hashmap.new(),
        prototype: None,
      }
      obj.properties.set("call", JSValue::Function(call_obj))

      // apply (ES3)
      let apply_fn = Native(fn(ctx, this_val, args) {
        match this_val {
          Function(f) => {
            let this_arg = if args.length() > 0 {
              args[0]
            } else {
              JSValue::Undefined
            }
            let call_args = []
            if args.length() > 1 {
              match args[1] {
                Object(obj) => {
                  let len_val = obj.properties
                    .get("length")
                    .unwrap_or(Number(0.0))
                  let len = match len_val {
                    Number(n) => n.to_int()
                    _ => 0
                  }
                  for i = 0; i < len; i = i + 1 {
                    call_args.push(
                      obj.properties.get(i.to_string()).unwrap_or(Undefined),
                    )
                  }
                }
                _ => ()
              }
            }
            ctx.invoke(f, this_arg, call_args) catch {
              _ => JSValue::Undefined
            }
          }
          _ => JSValue::Undefined
        }
      })
      let apply_obj = JSFunction::{
        name: Some("apply"),
        params: [],
        body: apply_fn,
        context: Context::new(),
        properties: @hashmap.new(),
        prototype: None,
      }
      obj.properties.set("apply", JSValue::Function(apply_obj))
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
    if args.length() > 0 {
      body_str = args[args.length() - 1].to_string()
      for i = 0; i < args.length() - 1; i = i + 1 {
        if i > 0 {
          params_str = params_str + ","
        }
        params_str = params_str + args[i].to_string()
      }
    }

    // Construct source code
    // We need to parse: "function anonymous(" + params_str + ") { " + body_str + " }"
    // But our parser parses Programs or Expressions.
    // "function ..." is a FunctionDeclaration (Statement) or FunctionExpression.

    let source = "(function anonymous(\{params_str}) { \{body_str} })"

    // We need to invoke parser.
    let tokens = source |> @lexer.parse
    let program = tokens |> @parser.parse
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
        _ => JSValue::Undefined
      }
    } else {
      JSValue::Undefined
    }
  })
  let ctor_obj = JSFunction::{
    name: Some("Function"),
    params: [], // Varargs effectively
    body: ctor_fn,
    context: Context::new(), // Global scope usually
    properties: @hashmap.new(),
    prototype: Some(proto),
  }
  ctor_obj.properties.set("prototype", proto)
  JSValue::Function(ctor_obj)
}

//|

///|
pub fn create_json_object(object_proto : JSValue) -> JSValue {
  let json_obj = JSObject::new(properties={}, prototype=object_proto)

  // JSON.parse
  let parse_fn = Native(fn(ctx, _this_val, args) {
    let text = match args.get(0) {
      Some(v) => js_to_string(ctx, v)
      None => "undefined"
    }
    let lexer = @lexer.Lexer::new(text)
    lexer.set_json_mode(true)
    let tokens = lexer.tokenize()
    if lexer.errors.length() > 0 {
      ctx.throw_syntax_error("Invalid JSON token")
    }
    if tokens is ([] | [{ kind: @tokens.TokenKind::EOF, .. }]) {
      ctx.throw_syntax_error("Unexpected end of JSON input")
    }
    let parser = @parser.Parser::new(tokens)
    let expr = parser.parse_expression()
    if parser.errors.length() > 0 {
      ctx.throw_syntax_error("Invalid JSON: " + parser.errors[0])
    }

    // Check if all tokens consumed (except EOF)
    if parser.pos < tokens.length() - 1 {
      ctx.throw_syntax_error("Unexpected token after JSON")
    }

    // Validate AST is strict JSON
    validate_json_ast(ctx, expr)
    let val = ctx.evaluate(Expression(expr)) catch {
      _ => ctx.throw_syntax_error("Invalid JSON")
    }
    match args {
      [_, reviver_arg, ..] =>
        match reviver_arg {
          Object(reviver) =>
            if reviver.is_callable {
              let obj_ctor = ctx.resolve("Object")
              let obj_proto = match obj_ctor {
                Object(f) => f.get("prototype")
                _ => JSValue::Null
              }
              let root = JSObject::new(properties={}, prototype=obj_proto)
              root.set("", val)
              internalize_json_property(root, "", reviver, ctx)
            } else {
              val
            }
          _ => val
        }
      _ => val
    }
  })
  let parse_obj = JSObject::new_function(name="parse", body=parse_fn, params=[
    "text", "reviver",
  ])
  json_obj["parse"] = JSValue::Object(parse_obj)

  // JSON.stringify
  let stringify_fn = Native(fn(ctx, _this_val, args) {
    if args is [value, ..] {
      // TODO: Handle replacer and space
      stringify(ctx, value)
    } else {
      JSValue::Undefined
    }
  })
  let stringify_obj = JSObject::new_function(
    name="stringify",
    body=stringify_fn,
    params=["value", "replacer", "space"],
  )
  json_obj["stringify"] = JSValue::Object(stringify_obj)
  JSValue::Object(json_obj)
}

///|
fn stringify(ctx : Context, value : JSValue) -> JSValue raise EvalError {
  match value {
    String(s) => JSValue::String("\"" + escape_string(s.to_string()) + "\"")
    Number(n) =>
      if n.is_nan() || n.is_inf() {
        JSValue::String("null")
      } else {
        JSValue::String(n.to_string())
      }
    Boolean(b) => JSValue::String(b.to_string())
    Null => JSValue::String("null")
    Undefined => JSValue::Undefined // Should return Undefined for direct call, but omitted in object
    Object(o) => {
      if o.is_callable {
        return JSValue::Undefined
      }
      // Check for toJSON?
      // TODO: toJSON support

      // Unbox wrapper objects
      if o.properties.contains("PrimitiveValue") {
        match o.properties.get("PrimitiveValue") {
          Some(Number(n)) => return stringify(ctx, JSValue::Number(n))
          Some(String(s)) => return stringify(ctx, JSValue::String(s))
          Some(Boolean(b)) => return stringify(ctx, JSValue::Boolean(b))
          _ => ()
        }
      }

      // Is it Array?
      let is_array = is_array_strict(ctx, JSValue::Object(o))
      if is_array {
        let mut res = "["
        let len = match o["length"] {
          Number(n) => n.to_int()
          _ => 0
        }
        for i = 0; i < len; i = i + 1 {
          if i > 0 {
            res = res + ","
          }
          let val = o[i.to_string()]
          match stringify(ctx, val) {
            String(s) => res = res + s.to_string()
            Undefined => res = res + "null" // Array elements become null if undefined
            _ => res = res + "null"
          }
        }
        res = res + "]"
        JSValue::String(res)
      } else {
        let mut res = "{"
        let mut first = true
        let keys = JSValue::Object(o).own_keys(ctx)
        for k in keys {
          let val = o[k]
          match stringify(ctx, val) {
            String(s) => {
              if not(first) {
                res = res + ","
              }
              res = res + "\"" + escape_string(k) + "\":" + s.to_string()
              first = false
            }
            _ => () // Skip undefined values
          }
        }
        res = res + "}"
        JSValue::String(res)
      }
    }
    Symbol(_) => JSValue::Undefined
    BigInt(_) => JSValue::Undefined // TypeError in spec, but undefined here for safety
    Internal(_) => JSValue::String("{}")
  }
}

///|
fn escape_string(s : String) -> String {
  // TODO: Implement proper escaping
  s
}

///|
fn internalize_json_property(
  holder : JSObject,
  name : String,
  reviver : JSObject,
  ctx : Context,
) -> JSValue raise EvalError {
  let val = JSValue::Object(holder).get_property_throwing(name)
  match val {
    Object(obj) => {
      let is_array = is_array_strict(ctx, val)
      if is_array {
        let len_val = JSValue::Object(obj).get_property_throwing("length")
        let len = match len_val {
          Number(n) => n.to_int()
          _ => 0
        }
        for i = 0; i < len; i = i + 1 {
          let prop = i.to_string()
          let new_element = internalize_json_property(obj, prop, reviver, ctx)
          match new_element {
            Undefined =>
              JSValue::Object(obj).delete_property(ctx, prop) |> ignore
            _ => create_data_property(ctx, obj, prop, new_element)
          }
        }
      } else {
        let keys = JSValue::Object(obj).own_keys(ctx)
        for k in keys {
          let new_element = internalize_json_property(obj, k, reviver, ctx)
          match new_element {
            Undefined => JSValue::Object(obj).delete_property(ctx, k) |> ignore
            _ => create_data_property(ctx, obj, k, new_element)
          }
        }
      }
    }
    _ => ()
  }
  ctx.invoke(reviver, JSValue::Object(holder), [JSValue::String(name), val]) catch {
    e => raise e
  }
}

///|
fn is_array_strict(ctx : Context, val : JSValue) -> Bool raise EvalError {
  match val {
    Object(obj) =>
      if obj.is_proxy {
        match obj.proxy_handler {
          Some(_) =>
            match obj.proxy_target {
              Some(target) => is_array_strict(ctx, target)
              None => false // Should not happen
            }
          None =>
            ctx.throw_type_error("Cannot perform IsArray on revoked proxy")
        }
      } else {
        obj["length"] is Number(_)
      }
    _ => false
  }
}

///|
fn create_data_property(
  ctx : Context,
  obj : JSObject,
  prop : String,
  val : JSValue,
) -> Unit raise EvalError {
  let define_prop = match ctx.resolve("Object") {
    Object(f) => f.get("defineProperty")
    _ => Undefined
  }
  match define_prop {
    Object(f) => {
      let desc = JSObject::new(prototype=JSValue::Null, properties={
        "value": val,
        "writable": JSValue::Boolean(true),
        "enumerable": JSValue::Boolean(true),
        "configurable": JSValue::Boolean(true),
      })
      // InternalizeJSONProperty uses CreateDataProperty, which uses [[DefineOwnProperty]].
      // [[DefineOwnProperty]] returns false on failure, it does not throw.
      // But Object.defineProperty throws on failure (TypeError).
      // So we must catch TypeError and ignore it to match spec behavior for InternalizeJSONProperty.
      try
        ctx.invoke(f, JSValue::Undefined, [
          JSValue::Object(obj),
          JSValue::String(prop),
          JSValue::Object(desc),
        ])
        |> ignore
      catch {
        EvalError::Throw(e) => {
          let type_error = ctx.resolve("TypeError")
          if e.instanceof(type_error) {
            () // Ignore TypeError (assumed to be failure to define)
          } else {
            raise EvalError::Throw(e) // Propagate other errors
          }
        }
        e => raise e
      }
    }
    _ => obj.set(prop, val)
  }
}

///|
fn validate_json_ast(
  ctx : Context,
  expr : @parser.Expression,
) -> Unit raise EvalError {
  match expr {
    @parser.Expression::ObjectExpression(obj) =>
      for prop in obj.properties {
        match prop {
          @parser.ObjectMember::ObjectProperty(p) => {
            if p.computed || p.shorthand {
              ctx.throw_syntax_error(
                "Invalid JSON: Computed property or shorthand",
              )
            }
            match p.key {
              @parser.Expression::StringLiteral(_) => ()
              _ =>
                ctx.throw_syntax_error(
                  "Invalid JSON: Key must be string literal",
                )
            }
            validate_json_ast(ctx, p.value)
          }
          _ => ctx.throw_syntax_error("Invalid JSON: Method or spread")
        }
      }
    @parser.Expression::ArrayLiteralExpression(arr) =>
      for elem in arr.elements {
        match elem {
          @parser.ArrayElement::Expression(e) => validate_json_ast(ctx, e)
          _ => ctx.throw_syntax_error("Invalid JSON: Spread in array")
        }
      }
    @parser.Expression::StringLiteral(_)
    | @parser.Expression::NullLiteral
    | @parser.Expression::BooleanLiteral(_)
    | @parser.Expression::NumericLiteral(_) => ()
    @parser.Expression::PrefixUnaryExpression(unary) => {
      if unary.operator != @parser.UnaryOperator::Minus {
        ctx.throw_syntax_error(
          "Invalid JSON: Only minus unary operator allowed",
        )
      }
      match unary.argument {
        @parser.Expression::NumericLiteral(_) => ()
        _ => ctx.throw_syntax_error("Invalid JSON: Invalid unary argument")
      }
    }
    _ => ctx.throw_syntax_error("Invalid JSON: Invalid expression type")
  }
}

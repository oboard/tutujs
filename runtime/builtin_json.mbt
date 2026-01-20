//|

///|
fn define_non_enumerable(
  ctx : Context,
  obj : JSObject,
  prop : String,
  val : JSValue,
) -> Unit {
  let define_prop = match ctx.resolve("Object") {
    Object(f) => f.get("defineProperty")
    _ => Undefined
  }
  match define_prop {
    Object(f) => {
      let desc = JSObject::new(properties={
        "value": val,
        "writable": JSValue::Boolean(true),
        "enumerable": JSValue::Boolean(false),
        "configurable": JSValue::Boolean(true),
      })
      try
        ctx.invoke(f, JSValue::Undefined, [
          JSValue::Object(obj),
          JSValue::String(prop),
          JSValue::Object(desc),
        ])
        |> ignore
      catch {
        _ => ()
      }
    }
    _ => obj.set(prop, val)
  }
}

///|
pub fn create_json_object(
  ctx : Context,
  object_proto : JSValue,
  func_proto : JSValue,
) -> JSValue {
  let json_obj = JSObject::new(properties={}, prototype=object_proto)

  // JSON.parse
  let parse_fn = Native(fn(ctx, _this_val, args) {
    let text = js_to_string(ctx, args[0])
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
    match args.0 {
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
  // Set length to be non-writable and non-enumerable
  let length_desc = JSObject::new(properties={
    "value": JSValue::Number(2.0),
    "writable": JSValue::Boolean(false),
    "enumerable": JSValue::Boolean(false),
    "configurable": JSValue::Boolean(true),
  })
  let descriptors = match parse_obj.properties.get("__descriptors") {
    Some(Object(d)) => d
    _ => {
      let d = JSObject::new(properties={})
      parse_obj["__descriptors"] = JSValue::Object(d)
      d
    }
  }
  descriptors["length"] = JSValue::Object(length_desc)
  // parse_obj["length"] = JSValue::Number(2.0) // Handled by descriptor

  // Set parse property on JSON object (non-enumerable)
  let parse_prop_desc = JSObject::new(properties={
    "value": JSValue::Object(parse_obj),
    "writable": JSValue::Boolean(true),
    "enumerable": JSValue::Boolean(false),
    "configurable": JSValue::Boolean(true),
  })
  let json_descriptors = match json_obj.properties.get("__descriptors") {
    Some(Object(d)) => d
    _ => {
      let d = JSObject::new(properties={})
      json_obj["__descriptors"] = JSValue::Object(d)
      d
    }
  }
  json_descriptors["parse"] = JSValue::Object(parse_prop_desc)
  json_obj["parse"] = JSValue::Object(parse_obj)

  // JSON.stringify
  let stringify_fn = Native(fn(ctx, _this_val, args) {
    if args.0 is [value, ..] {
      let replacer = args[1]
      let space = args[2]

      // Process space
      let mut gap : StringView = ""
      match space {
        Number(n) => {
          let count = n.to_int()
          let count = if count < 0 {
            0
          } else if count > 10 {
            10
          } else {
            count
          }
          gap = " ".repeat(count)
        }
        String(s) => {
          let s = s.to_string()
          if s.length() > 10 {
            gap = (s[0:10] catch { _ => s[:] }).to_string()
          } else {
            gap = s
          }
        }
        Object({ properties, .. }) =>
          if properties.contains("PrimitiveValue") {
            match properties.get("PrimitiveValue") {
              Some(Number(n)) => {
                let count = n.to_int()
                let count = if count < 0 {
                  0
                } else if count > 10 {
                  10
                } else {
                  count
                }
                gap = " ".repeat(count)
              }
              Some(String(s)) => {
                let s = s.to_string()
                if s.length() > 10 {
                  gap = (s[0:10] catch { _ => s[:] }).to_string()
                } else {
                  gap = s
                }
              }
              _ => ()
            }
          }
        _ => ()
      }

      // Process replacer
      let mut replacer_fn : JSObject? = None
      let mut property_list : Array[String]? = None
      match replacer {
        Object(f) =>
          if f.is_callable {
            replacer_fn = Some(f)
          } else {
            let is_array = is_array_strict(ctx, replacer)
            if is_array {
              let list = []
              let set = JSObject::new() // Use JSObject as set
              let len_val = JSValue::Object(f).get_property_throwing("length")
              let len = match len_val {
                Number(n) => n.to_int()
                _ => 0
              }
              for i = 0; i < len; i = i + 1 {
                let v = JSValue::Object(f).get_property_throwing(i.to_string())
                let item = match v {
                  String(s) => Some(s.to_string())
                  Number(n) => Some(n.to_string())
                  Object({ properties, .. }) =>
                    if properties.contains("PrimitiveValue") {
                      match properties.get("PrimitiveValue") {
                        Some(String(s)) => Some(s.to_string())
                        Some(Number(n)) => Some(n.to_string())
                        _ => None
                      }
                    } else {
                      None
                    }
                  _ => None
                }
                match item {
                  Some(s) =>
                    if not(set.properties.contains(s)) {
                      set.set(s, JSValue::Boolean(true))
                      list.push(s)
                    }
                  None => ()
                }
              }
              property_list = Some(list)
            }
          }
        _ => ()
      }
      let wrapper = JSObject::new(properties={ "": value })
      stringify(
        ctx,
        value,
        "",
        JSValue::Object(wrapper),
        replacer_fn,
        property_list,
        [],
        "",
        gap,
      )
    } else {
      JSValue::Undefined
    }
  })
  let stringify_obj = JSObject::new_function(
    name="stringify",
    body=stringify_fn,
    params=["value", "replacer", "space"],
    prototype=func_proto,
  )
  // Set length to be non-writable and non-enumerable
  let length_desc_str = JSObject::new(properties={
    "value": JSValue::Number(3.0),
    "writable": JSValue::Boolean(false),
    "enumerable": JSValue::Boolean(false),
    "configurable": JSValue::Boolean(true),
  })
  let descriptors_str = match stringify_obj.properties.get("__descriptors") {
    Some(Object(d)) => d
    _ => {
      let d = JSObject::new(properties={})
      stringify_obj["__descriptors"] = JSValue::Object(d)
      d
    }
  }
  descriptors_str["length"] = JSValue::Object(length_desc_str)

  // Set stringify property on JSON object (non-enumerable)
  define_non_enumerable(
    ctx,
    json_obj,
    "stringify",
    JSValue::Object(stringify_obj),
  )
  JSValue::Object(json_obj)
}

///|
fn stringify(
  ctx : Context,
  value : JSValue,
  key : String,
  holder : JSValue,
  replacer_fn : JSObject?,
  property_list : Array[String]?,
  stack : Array[JSValue],
  indent : StringView,
  gap : StringView,
) -> JSValue raise EvalError {
  let mut value = value
  // 1. toJSON
  match value {
    Object(o) => {
      let to_json = JSValue::Object(o).get_property_throwing("toJSON")
      match to_json {
        Object(f) =>
          if f.is_callable {
            value = ctx.invoke(f, value, [JSValue::String(key)]) catch {
              e => raise e
            }
          }
        _ => ()
      }
    }
    _ => ()
  }

  // 2. Replacer function
  match replacer_fn {
    Some(f) =>
      value = ctx.invoke(f, holder, [JSValue::String(key), value]) catch {
        e => raise e
      }
    None => ()
  }
  match value {
    String(s) => JSValue::String("\"" + escape_string(s.to_string()) + "\"")
    Number(n) =>
      JSValue::String(
        if n.is_nan() || n.is_inf() {
          "null"
        } else {
          n.to_string()
        },
      )
    Boolean(b) => JSValue::String(b.to_string())
    Null => JSValue::String("null")
    Undefined => JSValue::Undefined
    Object(o) => {
      if o.is_callable {
        return JSValue::Undefined
      }

      // Unbox wrapper objects
      match o["PrimitiveValue"] {
        Number(_) => {
          let num = js_to_number(ctx, value) // Removed catch
          return stringify(
            ctx,
            JSValue::Number(num),
            key,
            holder,
            replacer_fn,
            property_list,
            stack,
            indent,
            gap,
          )
        }
        String(_) => {
          let str = js_to_string(ctx, value)
          return stringify(
            ctx,
            JSValue::String(str),
            key,
            holder,
            replacer_fn,
            property_list,
            stack,
            indent,
            gap,
          )
        }
        Boolean(b) =>
          return stringify(
            ctx,
            JSValue::Boolean(b),
            key,
            holder,
            replacer_fn,
            property_list,
            stack,
            indent,
            gap,
          )
        BigInt(bi) =>
          return stringify(
            ctx,
            JSValue::BigInt(bi),
            key,
            holder,
            replacer_fn,
            property_list,
            stack,
            indent,
            gap,
          )
        _ => ()
      }

      // Circular check
      for v in stack {
        if v == value {
          ctx.throw_type_error("Converting circular structure to JSON")
        }
      }
      stack.push(value)

      // Is it Array?
      let is_array = is_array_strict(ctx, JSValue::Object(o))
      if is_array {
        let len = match o["length"] {
          Number(n) => n.to_int()
          _ => 0
        }
        if len == 0 {
          stack.pop() |> ignore
          return JSValue::String("[]")
        }
        let mut res : StringView = "["
        let step : StringView = if gap != "" {
          "\n".to_string_view() + indent + gap
        } else {
          ""
        }
        let next_indent = if gap != "" { indent + gap } else { "" }
        for i = 0; i < len; i = i + 1 {
          if i > 0 {
            res = res + ","
          }
          res = res + step
          let key = i.to_string()
          let val = o[key]
          match
            stringify(
              ctx, val, key, value, replacer_fn, property_list, stack, next_indent,
              gap,
            ) {
            String(s) => res = res + s.to_string()
            Undefined => res = res + "null"
            _ => res = res + "null"
          }
        }
        if gap != "" {
          res = res + "\n" + indent + "]"
        } else {
          res = res + "]"
        }
        stack.pop() |> ignore
        JSValue::String(res)
      } else {
        let keys = match property_list {
          Some(list) => list
          None => o.own_keys(ctx)
        }
        if keys.length() == 0 {
          stack.pop() |> ignore
          return JSValue::String("{}")
        }
        let mut res : StringView = "{"
        let mut first = true
        let step = if gap != "" {
          "\n".to_string_view() + indent + gap
        } else {
          ""
        }
        let next_indent = if gap != "" { indent + gap } else { "" }
        for k in keys {
          let val = o[k]
          match
            stringify(
              ctx, val, k, value, replacer_fn, property_list, stack, next_indent,
              gap,
            ) {
            String(s) => {
              if !first {
                res = res + ","
              }
              res = res + step
              let key_str = "\"" + escape_string(k) + "\":"
              let sep = if gap != "" { " " } else { "" }
              res = res + key_str + sep + s.to_string()
              first = false
            }
            _ => ()
          }
        }
        if gap != "" {
          if not(first) {
            res = res + "\n".to_string_view() + indent
          }
        }
        res = res + "}"
        stack.pop() |> ignore
        JSValue::String(res)
      }
    }
    Symbol(_) => JSValue::Undefined
    BigInt(_) =>
      ctx.throw_type_error("TypeError: Do not know how to serialize a BigInt")
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
        let keys = obj.own_keys(ctx)
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

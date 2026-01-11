//|

///|
pub fn create_regexp_object(
  object_proto : JSValue,
  syntax_error_ctor : JSValue,
) -> JSValue {
  let regexp_proto_props = @hashmap.new()
  let regexp_proto = JSValue::Object(JSObject::{
    properties: regexp_proto_props,
    prototype: Some(object_proto),
  })

  // RegExp Constructor
  let regexp_ctor_fn = Native(fn(_ctx, this_val, args) {
    let (pattern_view, pattern_str) = if args is [JSValue::String(s), ..] {
      (s, s.to_string())
    } else {
      let s = ""
      (s[:], s)
    }

    // Parse flags
    let flags_str = if args is [_, JSValue::String(s), ..] {
      s.to_string()
    } else {
      ""
    }

    // Handle ignore case by prepending (?i) if supported or we rely on the engine
    // MoonBit's regexp currently doesn't support inline flags like (?i) or we don't have access to compile options.
    // So we just pass the pattern as is. Flags are stored in properties but not used for matching yet.
    let effective_pattern = pattern_str
    let (re, valid) = (@regexp.compile(effective_pattern[:]), true) catch {
      _ => (@regexp.compile(""[:]) catch { _ => panic() }, false)
    }
    if not(valid) {
      let syntax_error_proto = match syntax_error_ctor {
        Function(f) => f.properties.get("prototype")
        Object(o) => o.properties.get("prototype")
        _ => None
      }
      let err_props = @hashmap.new()
      err_props.set("name", JSValue::String("SyntaxError"))
      err_props.set(
        "message",
        JSValue::String("Invalid regular expression: " + effective_pattern),
      )
      let err = JSObject::{
        properties: err_props,
        prototype: syntax_error_proto,
      }
      raise EvalError::Throw(JSValue::Object(err))
    }
    let init_regexp_props = fn(obj : JSObject) {
      obj.properties.set("lastIndex", JSValue::Number(0.0))
      obj.properties.set("source", JSValue::String(pattern_view))
      obj.properties.set("global", JSValue::Boolean(flags_str.contains("g")))
      obj.properties.set(
        "ignoreCase",
        JSValue::Boolean(flags_str.contains("i")),
      )
      obj.properties.set("multiline", JSValue::Boolean(flags_str.contains("m")))
      obj.properties.set(
        "__internal_regexp__",
        JSValue::Internal(JSInternal::RegExp(re, pattern_str)),
      )
    }
    let is_constructor_call = match this_val {
      Object(_) => true
      _ => false
    }
    if is_constructor_call {
      match this_val {
        Object(obj) => {
          init_regexp_props(obj)
          this_val
        }
        _ => JSValue::Undefined
      }
    } else {
      // Function call - create new object
      let new_obj_props = @hashmap.new()
      let new_obj = JSValue::Object(JSObject::{
        properties: new_obj_props,
        prototype: Some(regexp_proto),
      })
      let new_obj_inner = match new_obj {
        Object(o) => o
        _ => panic()
      }
      init_regexp_props(new_obj_inner)
      new_obj
    }
  })
  let regexp_ctor_props = @hashmap.new()
  regexp_ctor_props.set("prototype", regexp_proto)
  let regexp_ctor = JSFunction::new(
    name="RegExp",
    body=regexp_ctor_fn,
    properties=regexp_ctor_props,
    prototype=object_proto,
  )
  let regexp_ctor_val = JSValue::Function(regexp_ctor)
  regexp_proto_props.set("constructor", regexp_ctor_val)

  // RegExp.prototype.exec(string)
  let exec_fn = Native(fn(_ctx, this_val, args) {
    let str = if args is [JSValue::String(s), ..] {
      s.to_string()
    } else {
      "undefined"
    }
    match this_val {
      Object(
        {
          properties: {
            "__internal_regexp__": JSValue::Internal(JSInternal::RegExp(re, _)),
            ..
          } as properties,
          ..,
        }
      ) => {
        let global = match properties.get("global") {
          Some(JSValue::Boolean(b)) => b
          _ => false
        }
        let last_index = if global {
          match properties.get("lastIndex") {
            Some(JSValue::Number(n)) => n.to_int()
            _ => 0
          }
        } else {
          0
        }
        if last_index < 0 || last_index > str.length() {
          if global {
            properties.set("lastIndex", JSValue::Number(0.0))
          }
          return JSValue::Null
        }
        let search_str = str[last_index:].to_string() catch { _ => "" }
        let res = re.execute(search_str)
        if res.results().length() > 0 {
          let match_content = res.results()[0]
          let match_str = match match_content {
            Some(s) => s.to_string()
            None => ""
          }
          let relative_index = res.before().length()
          let match_index = last_index + relative_index
          if global {
            properties.set(
              "lastIndex",
              JSValue::Number((match_index + match_str.length()).to_double()),
            )
          }
          let result_array_props = @hashmap.new()
          result_array_props.set("0", JSValue::String(match_str))
          result_array_props.set(
            "index",
            JSValue::Number(match_index.to_double()),
          )
          result_array_props.set("input", JSValue::String(str))
          result_array_props.set("length", JSValue::Number(1.0))
          JSValue::Object(JSObject::{
            properties: result_array_props,
            prototype: Some(object_proto),
          })
        } else {
          if global {
            properties.set("lastIndex", JSValue::Number(0.0))
          }
          JSValue::Null
        }
      }
      _ => JSValue::Null
    }
  })
  regexp_proto_props.set(
    "exec",
    JSValue::Function(JSFunction::new(name="exec", body=exec_fn)),
  )

  // RegExp.prototype.test(string)
  let test_fn = Native(fn(ctx, this_val, args) {
    let exec_res = match exec_fn {
      Native(f) => f(ctx, this_val, args)
      _ => JSValue::Null
    }
    match exec_res {
      Null => JSValue::Boolean(false)
      _ => JSValue::Boolean(true)
    }
  })
  regexp_proto_props.set(
    "test",
    JSValue::Function(JSFunction::new(name="test", body=test_fn)),
  )

  // RegExp.prototype.toString()
  let to_string_fn = Native(fn(_ctx, this_val, _args) {
    match this_val {
      Object(
        {
          properties: {
            "__internal_regexp__": JSValue::Internal(JSInternal::RegExp(_, src)),
            ..
          },
          ..,
        }
      ) => JSValue::String("/" + src + "/")
      _ => JSValue::String("/(?:)/")
    }
  })
  regexp_proto_props.set(
    "toString",
    JSValue::Function(JSFunction::new(name="toString", body=to_string_fn)),
  )
  regexp_ctor_val
}

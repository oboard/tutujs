//|

///|
pub fn create_regexp_object(
  object_proto : JSValue,
  syntax_error_ctor : JSValue,
) -> JSValue {
  let regexp_proto_props = {}
  let regexp_proto = JSValue::Object(
    JSObject::new(properties=regexp_proto_props, prototype=object_proto),
  )

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
    let effective_pattern = sanitize_pattern(pattern_str)
    let (re, valid) = (@regexp.compile(effective_pattern[:]), true) catch {
      _ => (@regexp.compile(""[:]) catch { _ => panic() }, false)
    }
    if not(valid) {
      let syntax_error_proto = match syntax_error_ctor {
        Object(o) => o.properties.get("prototype")
        _ => None
      }
      let err_props = {
        "name": JSValue::String("SyntaxError"),
        "message": JSValue::String(
          "Invalid regular expression: " + effective_pattern,
        ),
      }
      let err = match syntax_error_proto {
        Some(p) => JSObject::new(properties=err_props, prototype=p)
        None => JSObject::new(properties=err_props)
      }
      raise EvalError::Throw(JSValue::Object(err))
    }
    let init_regexp_props = fn(obj : JSObject) {
      // lastIndex is non-enumerable, non-configurable, writable
      obj["lastIndex"] = JSValue::Number(0.0)
      let descriptors = JSObject::new()
      let last_index_desc = JSObject::new(properties={
        "enumerable": JSValue::Boolean(false),
        "configurable": JSValue::Boolean(false),
        "writable": JSValue::Boolean(true),
        "value": JSValue::Number(0.0),
      })
      descriptors["lastIndex"] = JSValue::Object(last_index_desc)
      obj.properties.set("__descriptors", JSValue::Object(descriptors))
      obj["source"] = JSValue::String(pattern_view)
      obj["global"] = JSValue::Boolean(flags_str.contains("g"))
      obj["ignoreCase"] = JSValue::Boolean(flags_str.contains("i"))
      obj["multiline"] = JSValue::Boolean(flags_str.contains("m"))
      obj["__internal_regexp__"] = JSValue::Internal(
        JSInternal::RegExp(re, pattern_str),
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
      let new_obj_props = {}
      let new_obj = JSValue::Object(
        JSObject::new(properties=new_obj_props, prototype=regexp_proto),
      )
      let new_obj_inner = match new_obj {
        Object(o) => o
        _ => panic()
      }
      init_regexp_props(new_obj_inner)
      new_obj
    }
  })
  let regexp_ctor_props = { "prototype": regexp_proto }
  let regexp_ctor = JSObject::new_function(
    name="RegExp",
    body=regexp_ctor_fn,
    properties=regexp_ctor_props,
    prototype=object_proto,
    is_constructor=true,
  )
  let regexp_ctor_val = JSValue::Object(regexp_ctor)
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
          let result_array_props = {
            "0": JSValue::String(match_str),
            "index": JSValue::Number(match_index.to_double()),
            "input": JSValue::String(str),
            "length": JSValue::Number(1.0),
          }
          JSValue::Object(
            JSObject::new(properties=result_array_props, prototype=object_proto),
          )
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
    JSValue::Object(JSObject::new_function(name="exec", body=exec_fn)),
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
    JSValue::Object(JSObject::new_function(name="test", body=test_fn)),
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
    JSValue::Object(JSObject::new_function(name="toString", body=to_string_fn)),
  )
  regexp_ctor_val
}

///|
fn sanitize_pattern(pattern : String) -> String {
  let mut res = ""
  let mut i = 0
  let n = pattern.length()
  while i < n {
    if pattern[i] == '\\' && i + 1 < n {
      let slice = pattern[i:i + 2].to_string() catch { _ => "" }
      res += slice
      i += 2
      continue
    }
    if pattern[i] == '{' {
      let mut j = i + 1
      let mut num1 = ""
      while j < n && pattern[j] >= '0' && pattern[j] <= '9' {
        let digit = pattern[j:j + 1].to_string() catch { _ => "" }
        num1 += digit
        j += 1
      }
      let mut has_comma = false
      let mut num2 = ""
      let mut second_num_present = false
      if j < n && pattern[j] == ',' {
        has_comma = true
        j += 1
        while j < n && pattern[j] >= '0' && pattern[j] <= '9' {
          let digit = pattern[j:j + 1].to_string() catch { _ => "" }
          num2 += digit
          second_num_present = true
          j += 1
        }
      }
      if j < n && pattern[j] == '}' {
        // We found a quantifier
        let limit = 1000
        let mut new_num1 = num1
        if num1.length() > 0 {
          let val = @strconv.parse_int(num1) catch { _ => limit + 1 }
          if val > limit {
            new_num1 = limit.to_string()
          }
        }
        let mut new_num2 = num2
        if second_num_present {
          let val = @strconv.parse_int(num2) catch { _ => limit + 1 }
          if val > limit {
            new_num2 = limit.to_string()
          }
        }
        res += "{" + new_num1
        if has_comma {
          res += "," + new_num2
        }
        res += "}"
        i = j + 1
        continue
      }
    }
    let char_str = pattern[i:i + 1].to_string() catch { _ => "" }
    res += char_str
    i += 1
  }
  res
}

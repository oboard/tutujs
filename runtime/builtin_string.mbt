///|
fn escape_html_attribute(s : String) -> String {
  let mut res = ""
  for c in s {
    if c == '"' {
      res = res + "&quot;"
    } else {
      res = res + c.to_string()
    }
  }
  res
}

///|
fn to_integer_or_infinity(
  ctx : Context,
  arg : JSValue,
) -> Double raise EvalError {
  let n = js_to_number(ctx, arg)
  if n.is_nan() || n == 0.0 {
    0.0
  } else if n.is_inf() {
    n
  } else {
    @math.trunc(n)
  }
}

///|
fn string_index_of(s : String, search : String, from_index : Int) -> Int {
  let len = s.length()
  let search_len = search.length()
  if search_len == 0 {
    return if from_index > len {
      len
    } else if from_index < 0 {
      0
    } else {
      from_index
    }
  }
  let mut i = if from_index < 0 { 0 } else { from_index }
  while i + search_len <= len {
    let sub = s[i:i + search_len] catch { _ => "" }
    if sub == search {
      return i
    }
    i = i + 1
  }
  -1
}

///|
fn create_html_helper(
  ctx : Context,
  this_val : JSValue,
  tag : String,
  attribute : String,
  value : JSValue,
) -> JSValue raise EvalError {
  if this_val == JSValue::Null || this_val == JSValue::Undefined {
    ctx.throw_type_error("String.prototype method called on null or undefined")
  }
  let s = js_to_string(ctx, this_val).to_string()
  let mut p1 = "<" + tag
  if attribute != "" {
    let v = js_to_string(ctx, value).to_string()
    let escaped_v = escape_html_attribute(v)
    p1 = p1 + " " + attribute + "=\"" + escaped_v + "\""
  }
  let p2 = p1 + ">"
  let p3 = p2 + s
  let p4 = p3 + "</" + tag + ">"
  JSValue::String(p4)
}

///|
pub fn init_string_prototype(
  string_proto_val : JSValue,
  func_proto : JSValue,
) -> Unit {
  match string_proto_val {
    Object(obj) => {
      // PrimitiveValue = ""
      obj["PrimitiveValue"] = JSValue::String("")
      obj["length"] = JSValue::Number(0.0)
      // toString
      let to_string_fn = Native(fn(_ctx, this_val, _args) {
        JSValue::String(
          match this_val {
            String(s) => s
            Object(
              { properties: { "PrimitiveValue": JSValue::String(s), .. }, .. }
            ) => s
            _ => ""
          },
        )
      })
      let to_string_obj = JSObject::new_function(
        name="toString",
        body=to_string_fn,
        prototype=func_proto,
      )
      obj["toString"] = JSValue::Object(to_string_obj)

      // valueOf
      let value_of_fn = Native(fn(_ctx, this_val, _args) {
        match this_val {
          String(s) => JSValue::String(s)
          Object({ properties, .. }) =>
            match properties.get("PrimitiveValue") {
              Some(String(s)) => JSValue::String(s)
              _ => JSValue::String("")
            }
          _ => JSValue::String("")
        }
      })
      let value_of_obj = JSObject::new_function(
        name="valueOf",
        body=value_of_fn,
        prototype=func_proto,
      )
      obj["valueOf"] = JSValue::Object(value_of_obj)

      // charAt
      let char_at_fn = Native(fn(_ctx, this_val, args) {
        let s = match this_val {
          String(str) => str
          Object({ properties, .. }) =>
            match properties.get("PrimitiveValue") {
              Some(String(str)) => str
              _ => ""
            }
          _ => ""
        }
        let pos = if args is [Number(n), ..] { n.to_int() } else { 0 }
        if pos >= 0 && pos < s.length() {
          let char_code = s[pos].to_int()
          let c = match char_code.to_char() {
            Some(c) => c
            None => ' '
          }
          JSValue::String(String::make(1, c))
        } else {
          JSValue::String("")
        }
      })
      let char_at_obj = JSObject::new_function(
        name="charAt",
        body=char_at_fn,
        prototype=func_proto,
      )
      obj["charAt"] = JSValue::Object(char_at_obj)

      // match
      let match_fn = Native(fn(ctx, this_val, args) {
        if this_val == JSValue::Null || this_val == JSValue::Undefined {
          ctx.throw_type_error(
            "String.prototype.match called on null or undefined",
          )
        }
        let regexp = if args.length() > 0 {
          args[0]
        } else {
          JSValue::Undefined
        }
        if regexp != JSValue::Null && regexp != JSValue::Undefined {
          let matcher = regexp.get_property("Symbol(Symbol.match)")
          if matcher != JSValue::Undefined {
            match matcher {
              Object(m) => return ctx.invoke(m, regexp, [this_val])
              _ => ()
            }
          }
        }
        let rx_ctor = ctx.resolve("RegExp")
        // RegExp(regexp) is equivalent to new RegExp(regexp)
        let rx = match rx_ctor {
          Object(ctor) => ctx.invoke(ctor, JSValue::Undefined, [regexp])
          _ => ctx.throw_type_error("RegExp constructor not found")
        }
        let matcher = rx.get_property("Symbol(Symbol.match)")
        match matcher {
          Object(m) => ctx.invoke(m, rx, [this_val])
          _ => ctx.throw_type_error("Symbol.match not found on RegExp")
        }
      })
      let match_obj = JSObject::new_function(
        name="match",
        params=["regexp"],
        body=match_fn,
        prototype=func_proto,
      )
      obj["match"] = JSValue::Object(match_obj)

      // replace
      let replace_fn = Native(fn(ctx, this_val, args) {
        if this_val == JSValue::Null || this_val == JSValue::Undefined {
          ctx.throw_type_error(
            "String.prototype.replace called on null or undefined",
          )
        }
        let regexp = if args.length() > 0 {
          args[0]
        } else {
          JSValue::Undefined
        }
        let replace_value = if args.length() > 1 {
          args[1]
        } else {
          JSValue::Undefined
        }
        if regexp != JSValue::Null && regexp != JSValue::Undefined {
          let replacer = regexp.get_property("Symbol(Symbol.replace)")
          if replacer != JSValue::Undefined {
            match replacer {
              Object(r) =>
                return ctx.invoke(r, regexp, [this_val, replace_value])
              _ => ()
            }
          }
        }
        let search_string = js_to_string(ctx, regexp).to_string()
        let input = js_to_string(ctx, this_val).to_string()
        let idx = match string_index_of(input, search_string, 0) {
          -1 => -1
          i => i
        }
        if idx == -1 {
          JSValue::String(input)
        } else {
          let replacement = match replace_value {
            Object(f) if f.is_callable => {
              let match_str = JSValue::String(search_string)
              let offset = JSValue::Number(idx.to_double())
              let string_val = JSValue::String(input)
              let res = ctx.invoke(f, JSValue::Undefined, [
                match_str, offset, string_val,
              ]) catch {
                e => raise e
              }
              js_to_string(ctx, res).to_string()
            }
            _ => js_to_string(ctx, replace_value).to_string()
          }
          let before = input[0:idx] catch { _ => "" }
          let after = input[idx + search_string.length():input.length()] catch {
              _ => ""
            }
          JSValue::String(before + replacement + after)
        }
      })
      let replace_obj = JSObject::new_function(
        name="replace",
        params=["searchValue", "replaceValue"],
        body=replace_fn,
        prototype=func_proto,
      )
      obj["replace"] = JSValue::Object(replace_obj)

      // search
      let search_fn = Native(fn(ctx, this_val, args) {
        if this_val == JSValue::Null || this_val == JSValue::Undefined {
          ctx.throw_type_error(
            "String.prototype.search called on null or undefined",
          )
        }
        let regexp = if args.length() > 0 {
          args[0]
        } else {
          JSValue::Undefined
        }
        if regexp != JSValue::Null && regexp != JSValue::Undefined {
          let searcher = regexp.get_property("Symbol(Symbol.search)")
          if searcher != JSValue::Undefined {
            match searcher {
              Object(s) => return ctx.invoke(s, regexp, [this_val])
              _ => ()
            }
          }
        }
        let rx_ctor = ctx.resolve("RegExp")
        let rx = match rx_ctor {
          Object(ctor) => ctx.invoke(ctor, JSValue::Undefined, [regexp])
          _ => ctx.throw_type_error("RegExp constructor not found")
        }
        let searcher = rx.get_property("Symbol(Symbol.search)")
        match searcher {
          Object(s) => ctx.invoke(s, rx, [this_val])
          _ => ctx.throw_type_error("Symbol.search not found on RegExp")
        }
      })
      let search_obj = JSObject::new_function(
        name="search",
        params=["regexp"],
        body=search_fn,
        prototype=func_proto,
      )
      obj["search"] = JSValue::Object(search_obj)

      // substr
      let substr_fn = Native(fn(ctx, this_val, args) {
        if this_val == JSValue::Null || this_val == JSValue::Undefined {
          ctx.throw_type_error(
            "String.prototype.substr called on null or undefined",
          )
        }
        let s = js_to_string(ctx, this_val).to_string()
        let len = s.length().to_double()
        let start = if args.length() > 0 {
          to_integer_or_infinity(ctx, args[0])
        } else {
          0.0
        }
        let length = if args.length() > 1 && args[1] != JSValue::Undefined {
          to_integer_or_infinity(ctx, args[1])
        } else {
          @double.infinity
        }
        let int_start = if start.is_inf() {
          if start > 0.0 {
            len
          } else {
            0.0
          }
        } else if start < 0.0 {
          @math.maximum(len + start, 0.0)
        } else {
          @math.minimum(start, len)
        }
        let int_length = if length <= 0.0 {
          0.0
        } else if length.is_inf() {
          len - int_start
        } else {
          @math.minimum(length, len - int_start)
        }
        if int_length <= 0.0 {
          JSValue::String("")
        } else {
          let start_idx = int_start.to_int()
          let end_idx = (int_start + int_length).to_int()
          JSValue::String(s[start_idx:end_idx]) catch {
            _ => JSValue::String("")
          }
        }
      })
      let substr_obj = JSObject::new_function(
        name="substr",
        params=["start", "length"],
        body=substr_fn,
        prototype=func_proto,
      )
      obj["substr"] = JSValue::Object(substr_obj)

      // split
      let split_fn = Native(fn(ctx, this_val, args) {
        let s = match this_val {
          String(str) => str
          Object({ properties, .. }) =>
            match properties.get("PrimitiveValue") {
              Some(String(str)) => str
              _ => ""
            }
          _ => ""
        }
        let _separator = if args.length() > 0 {
          args[0]
        } else {
          JSValue::Undefined
        }
        let _limit = if args.length() > 1 {
          args[1]
        } else {
          JSValue::Undefined
        }
        let array_proto = match ctx.resolve("Array") {
          Object(f) => f.properties.get("prototype")
          _ => None
        }
        let arr_obj = match array_proto {
          Some(p) => JSObject::new(properties={}, prototype=p)
          None => JSObject::new(properties={})
        }
        arr_obj["length"] = JSValue::Number(1.0)
        arr_obj["0"] = JSValue::String(s)
        JSValue::Object(arr_obj)
      })
      let split_obj = JSObject::new_function(
        name="split",
        params=["separator", "limit"],
        body=split_fn,
        prototype=func_proto,
      )
      obj["split"] = JSValue::Object(split_obj)

      // Annex B HTML methods
      let html_methods = [
        ("anchor", "a", "name"),
        ("big", "big", ""),
        ("blink", "blink", ""),
        ("bold", "b", ""),
        ("fixed", "tt", ""),
        ("fontcolor", "font", "color"),
        ("fontsize", "font", "size"),
        ("italics", "i", ""),
        ("link", "a", "href"),
        ("small", "small", ""),
        ("strike", "strike", ""),
        ("sub", "sub", ""),
        ("sup", "sup", ""),
      ]
      for m in html_methods {
        let (name, tag, attr) = m
        let func = Native(fn(ctx, this_val, args) raise EvalError {
          let val = if attr != "" {
            if args.length() > 0 {
              args[0]
            } else {
              Undefined
            }
          } else {
            Undefined
          }
          create_html_helper(ctx, this_val, tag, attr, val)
        })
        let func_obj = JSObject::new_function(
          name~,
          params=if attr != "" { [attr] } else { [] },
          body=func,
          prototype=func_proto,
        )
        obj[name] = JSValue::Object(func_obj)

        // Make non-enumerable
        let desc = JSObject::new(properties={
          "value": JSValue::Object(func_obj),
          "writable": JSValue::Boolean(true),
          "enumerable": JSValue::Boolean(false),
          "configurable": JSValue::Boolean(true),
        })
        let descriptors = match obj.properties.get("__descriptors") {
          Some(Object(d)) => d
          _ => {
            let d = JSObject::new(properties={})
            obj.properties.set("__descriptors", JSValue::Object(d))
            d
          }
        }
        descriptors[name] = JSValue::Object(desc)
      }
    }
    _ => ()
  }
}

///|
pub fn create_string_constructor(
  proto : JSValue,
  func_proto : JSValue,
) -> JSValue {
  let ctor_fn = Native(fn(ctx, this_val, args) {
    let (val_str, is_symbol) = if args is [arg, ..] {
      match arg {
        Symbol(_, s) => ("Symbol(" + s + ")", true)
        _ => (js_to_string(ctx, arg) catch { e => raise e }, false)
      }
    } else {
      ("", false)
    }
    let is_constructor = match this_val {
      Object({ prototype: Some(Object({ properties: p_props, .. })), .. }) =>
        match proto {
          Object({ properties: proto_props, .. }) =>
            physical_equal(p_props, proto_props)
          _ => false
        }
      _ => false
    }
    if is_constructor {
      if is_symbol {
        ctx.throw_type_error("Cannot convert a Symbol value to a string")
      }
      match this_val {
        Object({ properties, .. }) => {
          properties["PrimitiveValue"] = JSValue::String(val_str)
          let len = val_str.length().to_double()
          properties["length"] = JSValue::Number(len)

          // Set length with descriptors (non-writable, non-enumerable, non-configurable)
          let len_desc = JSObject::new(properties={
            "value": JSValue::Number(len),
            "writable": JSValue::Boolean(false),
            "enumerable": JSValue::Boolean(false),
            "configurable": JSValue::Boolean(false),
          })
          let descriptors = match properties.get("__descriptors") {
            Some(Object(d)) => d
            _ => {
              let d = JSObject::new(properties={})
              properties["__descriptors"] = JSValue::Object(d)
              d
            }
          }
          descriptors["length"] = JSValue::Object(len_desc)

          // Populate indices for enumeration
          for i = 0; i < val_str.length(); i = i + 1 {
            // We need to store them in properties so for-in loop can see them.
            try {
              let char_val = JSValue::String(val_str[i:i + 1])
              let idx_str = i.to_string()
              properties[idx_str] = char_val

              // Indices are enumerable, non-writable, non-configurable
              let idx_desc = JSObject::new(properties={
                "value": char_val,
                "writable": JSValue::Boolean(false),
                "enumerable": JSValue::Boolean(true),
                "configurable": JSValue::Boolean(false),
              })
              descriptors[idx_str] = JSValue::Object(idx_desc)
            } catch {
              _ => ()
            }
          }
        }
        _ => ()
      }
      this_val
    } else {
      JSValue::String(val_str)
    }
  })
  let ctor_obj = JSObject::new_function(
    name="String",
    params=["value"],
    body=ctor_fn,
    prototype=func_proto,
    is_constructor=true,
  )

  // Set String.prototype.constructor
  match proto {
    Object(p) => p["constructor"] = JSValue::Object(ctor_obj)
    _ => ()
  }

  // Set String.prototype property on constructor (non-writable, non-enumerable, non-configurable)
  let proto_desc = JSObject::new(properties={
    "value": proto,
    "writable": JSValue::Boolean(false),
    "enumerable": JSValue::Boolean(false),
    "configurable": JSValue::Boolean(false),
  })
  let ctor_descriptors = match ctor_obj.properties.get("__descriptors") {
    Some(Object(d)) => d
    _ => {
      let d = JSObject::new(properties={})
      ctor_obj["__descriptors"] = JSValue::Object(d)
      d
    }
  }
  ctor_descriptors["prototype"] = JSValue::Object(proto_desc)
  ctor_obj["prototype"] = proto
  JSValue::Object(ctor_obj)
}

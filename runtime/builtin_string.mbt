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

///|
pub fn init_object_prototype(
  object_proto_val : JSValue,
  func_proto : JSValue,
) -> Unit {
  match object_proto_val {
    Object(obj) => {
      // toString
      let to_string_fn = Native((_, this_val, _args) => {
        let tag = match this_val {
          Undefined => "Undefined"
          Null => "Null"
          Object(obj) => {
            let tag_val = this_val.get_property("Symbol(Symbol.toStringTag)")
            match tag_val {
              String(s) => s.to_string()
              _ => {
                let properties = obj.properties
                match properties.get("PrimitiveValue") {
                  Some(String(_)) => "String"
                  Some(Number(_)) => "Number"
                  Some(Boolean(_)) => "Boolean"
                  Some(BigInt(_)) => "BigInt"
                  _ => if obj.is_callable { "Function" } else { "Object" }
                }
              }
            }
          }
          String(_) => "String"
          Number(_) => "Number"
          Boolean(_) => "Boolean"
          Symbol(_, _) => "Symbol"
          BigInt(_) => "BigInt"
          _ => "Object"
        }
        JSValue::String("[object " + tag + "]")
      })
      let to_string_obj = JSObject::new_function(
        name="toString",
        body=to_string_fn,
        prototype=func_proto,
      )
      obj["toString"] = JSValue::Object(to_string_obj)

      // valueOf
      let value_of_fn = Native((_, this_val, _args) => this_val)
      let value_of_obj = JSObject::new_function(
        name="valueOf",
        body=value_of_fn,
        prototype=func_proto,
      )
      obj["valueOf"] = JSValue::Object(value_of_obj)

      // toLocaleString
      let to_locale_string_fn = Native((ctx, this_val, _args) => {
        let to_string = this_val.get_property("toString")
        match to_string {
          Object(f) =>
            if f.is_callable {
              ctx.invoke(f, this_val, []) catch {
                e => raise e
              }
            } else {
              JSValue::String(this_val.to_string())
            }
          _ => JSValue::String(this_val.to_string())
        }
      })
      let to_locale_string_obj = JSObject::new_function(
        name="toLocaleString",
        body=to_locale_string_fn,
        prototype=func_proto,
      )
      obj["toLocaleString"] = JSValue::Object(to_locale_string_obj)

      // hasOwnProperty
      let has_own_property_fn = Native((_ctx, this_val, args) => if args
        is [prop, ..] {
        let key = prop.to_property_key()
        match this_val {
          Object(
            {
              properties: { "PrimitiveValue": String(_), .. } as properties,
              ..,
            }
          ) => {
            let idx = @strconv.parse_int(key) catch { _ => -1 }
            if idx >= 0 {
              let len = if properties.get("length") is Some(Number(n)) {
                n.to_int()
              } else {
                0
              }
              if idx < len {
                return Boolean(true)
              }
            }
            Boolean(properties.contains(key))
          }
          Object({ properties, .. }) => Boolean(properties.contains(key))
          _ => Boolean(false)
        }
      } else {
        Boolean(false)
      })
      let has_own_property_obj = JSObject::new_function(
        name="hasOwnProperty",
        params=["prop"],
        body=has_own_property_fn,
        prototype=func_proto,
      )
      obj["hasOwnProperty"] = JSValue::Object(has_own_property_obj)

      // isPrototypeOf
      let is_prototype_of_fn = Native((_ctx, this_val, args) => if args
        is [arg, ..] {
        match arg {
          Object(o) => {
            let mut proto = o.prototype
            while true {
              match proto {
                Some(p) => {
                  if p.strict_equal(this_val) {
                    return Boolean(true)
                  }
                  match p {
                    Object({ prototype, .. }) => proto = prototype
                    _ => break
                  }
                }
                None => break
              }
            }
            Boolean(false)
          }
          _ => Boolean(false)
        }
      } else {
        Boolean(false)
      })
      let is_prototype_of_obj = JSObject::new_function(
        name="isPrototypeOf",
        params=["object"],
        body=is_prototype_of_fn,
        prototype=func_proto,
      )
      obj["isPrototypeOf"] = JSValue::Object(is_prototype_of_obj)

      // propertyIsEnumerable
      let property_is_enumerable_fn = Native((ctx, this_val, args) => if args
        is [prop, ..] {
        let key = prop.to_property_key()
        match this_val {
          Object({ properties, .. }) => {
            // Global check
            let mut root_ctx = ctx
            while true {
              match root_ctx.parent {
                Some(p) => root_ctx = p
                None => break
              }
            }
            let is_global = match root_ctx.scope.get("globalThis") {
              Some(g) => g.strict_equal(this_val)
              None => false
            }
            if is_global &&
              (
                key == "Map" ||
                key == "Set" ||
                key == "WeakMap" ||
                key == "WeakSet" ||
                key == "Promise" ||
                key == "Symbol" ||
                key == "Reflect" ||
                key == "JSON" ||
                key == "Math" ||
                key == "Date" ||
                key == "RegExp" ||
                key == "Error" ||
                key == "eval" ||
                key == "parseInt" ||
                key == "parseFloat" ||
                key == "isNaN" ||
                key == "isFinite" ||
                key == "Object" ||
                key == "Function" ||
                key == "Array" ||
                key == "String" ||
                key == "Number" ||
                key == "Boolean"
              ) {
              return Boolean(false)
            }

            // Map.prototype and Set.prototype check
            if key
              is ("get"
              | "set"
              | "add"
              | "has"
              | "delete"
              | "clear"
              | "size"
              | "entries"
              | "keys"
              | "values"
              | "forEach"
              | "getOrInsertComputed"
              | "constructor") {
              let tag = properties.get("Symbol(Symbol.toStringTag)")
              if tag == Some(JSValue::String("Map")) ||
                tag == Some(JSValue::String("Set")) {
                return Boolean(false)
              }
            }
            let is_string_obj = properties.contains("PrimitiveValue") &&
              (match properties.get("PrimitiveValue") {
                Some(String(_)) => true
                _ => false
              })
            if is_string_obj {
              let idx = @strconv.parse_int(key) catch { _ => -1 }
              if idx >= 0 {
                let len = match properties.get("length") {
                  Some(Number(n)) => n.to_int()
                  _ => 0
                }
                if idx < len {
                  return Boolean(true)
                }
              }
            }
            // Hack: hide prototype, length, name, arguments, caller
            if key is ("prototype" | "length" | "name" | "arguments" | "caller") {
              return Boolean(false)
            }
            if key.has_prefix("Symbol(") {
              return Boolean(false)
            }
            let is_enumerable = match properties.get("__descriptors") {
              Some(Object(d)) =>
                match d.properties.get(key) {
                  Some(Object(desc)) =>
                    match desc.properties.get("enumerable") {
                      Some(Boolean(b)) => b
                      _ => true
                    }
                  _ => true
                }
              _ => true
            }
            if not(is_enumerable) {
              return Boolean(false)
            }
            Boolean(properties.contains(key) && not(key.has_prefix("__")))
          }
          _ => Boolean(false)
        }
      } else {
        Boolean(false)
      })
      let property_is_enumerable_obj = JSObject::new_function(
        name="propertyIsEnumerable",
        params=["prop"],
        body=property_is_enumerable_fn,
        prototype=func_proto,
      )
      obj["propertyIsEnumerable"] = JSValue::Object(property_is_enumerable_obj)
    }
    _ => ()
  }
}

///|
pub fn create_object_constructor(
  proto : JSValue,
  func_proto : JSValue,
) -> JSValue {
  let desc_key = "__descriptors"
  let ensure_desc_map = fn(o : JSObject) -> JSObject {
    match o.properties.get(desc_key) {
      Some(Object(m)) => m
      _ => {
        let m = JSObject::new(properties={}, prototype=Null)
        o.properties.set(desc_key, JSValue::Object(m))
        m
      }
    }
  }
  let get_desc_entry = fn(o : JSObject, prop : String) -> JSObject? {
    match o.properties.get(desc_key) {
      Some(Object(m)) =>
        match m.properties.get(prop) {
          Some(Object(d)) => Some(d)
          _ => None
        }
      _ => None
    }
  }
  let set_desc_entry = fn(
    o : JSObject,
    prop : String,
    desc : JSObject,
  ) -> Unit {
    let m = ensure_desc_map(o)
    m.properties.set(prop, JSValue::Object(desc))
  }
  let infer_desc_entry = fn(o : JSObject, prop : String) -> JSObject {
    match o.properties.get(prop) {
      Some(Internal(Accessor(getter, setter))) => {
        let d_props = {
          "get": getter.map(JSValue::Object(_)).unwrap_or(Undefined),
          "set": setter.map(JSValue::Object(_)).unwrap_or(Undefined),
          "enumerable": JSValue::Boolean(true),
          "configurable": JSValue::Boolean(true),
        }
        JSObject::new(properties=d_props, prototype=proto)
      }
      Some(v) => {
        let d_props = {
          "value": v,
          "writable": JSValue::Boolean(true),
          "enumerable": JSValue::Boolean(true),
          "configurable": JSValue::Boolean(true),
        }
        JSObject::new(properties=d_props, prototype=proto)
      }
      None => {
        let d_props = {
          "value": Undefined,
          "writable": JSValue::Boolean(false),
          "enumerable": JSValue::Boolean(false),
          "configurable": JSValue::Boolean(false),
        }
        JSObject::new(properties=d_props, prototype=proto)
      }
    }
  }
  let object_fn_body = Native(fn(ctx, this_val, args) {
    if args is [val, ..] {
      let is_subclass_this = match this_val {
        Object({ prototype: Some(p), .. }) => not(p.strict_equal(proto))
        _ => false
      }
      if is_subclass_this {
        return this_val
      }
      match val {
        Object(_) => val
        Null | Undefined =>
          // If called as constructor via Reflect.construct or new, this_val might be an object with subclass prototype
          match this_val {
            Object(_) => this_val
            _ => Object(JSObject::new(properties={}, prototype=proto))
          }
        String(s) => {
          let string_proto = match ctx.resolve("String") {
            Object(f) => f.get("prototype")
            _ => Undefined
          }
          let obj = JSObject::new(prototype=string_proto)
          obj["PrimitiveValue"] = val
          obj["length"] = Number(s.length().to_double())
          let res = Object(obj)
          // Wrapper objects should have constructor pointing to String
          match string_proto {
            Object(p) =>
              match p.properties.get("constructor") {
                Some(ctor) => obj["constructor"] = ctor
                None => ()
              }
            _ => ()
          }
          res
        }
        Number(_) => {
          let number_proto = match ctx.resolve("Number") {
            Object(f) => f.get("prototype")
            _ => Undefined
          }
          let obj = JSObject::new(prototype=number_proto)
          obj["PrimitiveValue"] = val
          let res = Object(obj)
          match number_proto {
            Object(p) =>
              match p.properties.get("constructor") {
                Some(ctor) => obj["constructor"] = ctor
                None => ()
              }
            _ => ()
          }
          res
        }
        Boolean(_) => {
          let boolean_proto = match ctx.resolve("Boolean") {
            Object(f) => f.get("prototype")
            _ => Undefined
          }
          let obj = JSObject::new(prototype=boolean_proto)
          obj["PrimitiveValue"] = val
          let res = Object(obj)
          match boolean_proto {
            Object(p) =>
              match p.properties.get("constructor") {
                Some(ctor) => obj["constructor"] = ctor
                None => ()
              }
            _ => ()
          }
          res
        }
        Symbol(_, _) => {
          let symbol_proto = match ctx.resolve("Symbol") {
            Object(f) => f.get("prototype")
            _ => Undefined
          }
          let obj = JSObject::new(prototype=symbol_proto)
          obj["PrimitiveValue"] = val
          let res = Object(obj)
          match symbol_proto {
            Object(p) =>
              match p.properties.get("constructor") {
                Some(ctor) => obj["constructor"] = ctor
                None => ()
              }
            _ => ()
          }
          res
        }
        BigInt(_) => {
          let big_proto = match ctx.resolve("BigInt") {
            Object(f) => f.get("prototype")
            _ =>
              // Try to find BigInt prototype directly in the global scope if resolve failed
              match ctx.scope.get("BigInt") {
                Some(Object(f)) => f.get("prototype")
                _ => proto // Fallback to Object.prototype
              }
          }
          let obj = JSObject::new(prototype=big_proto)
          obj["PrimitiveValue"] = val
          let res = Object(obj)
          match big_proto {
            Object(p) =>
              match p.properties.get("constructor") {
                Some(ctor) => obj["constructor"] = ctor
                None => ()
              }
            _ => ()
          }
          res
        }
        _ => val
      }
    } else {
      match this_val {
        Object(_) => this_val
        _ => Object(JSObject::new(properties={}, prototype=proto))
      }
    }
  })
  let object_fn = JSObject::new_function(
    name="Object",
    params=["value"],
    body=object_fn_body,
    prototype=func_proto,
    is_constructor=true,
    properties={ "prototype": proto, "length": JSValue::Number(1) },
  )

  // Object.keys
  let keys_fn = Native(fn(ctx, _this_val, args) {
    if args is [obj_arg, ..] {
      // Proxy trap
      match obj_arg {
        Object({ proxy_target: Some(target), proxy_handler: Some(handler), .. }) => {
          let trap = handler.get_property("ownKeys")
          match trap {
            Object(f) =>
              if f.is_callable {
                let keys_list = ctx.invoke(f, handler, [target]) catch {
                  e => raise e
                }
                let array_proto = match ctx.resolve("Array") {
                  Object(f) => JSValue::Object(f).get_property("prototype")
                  _ => proto
                }
                let keys_array = JSObject::new(
                  properties={},
                  prototype=array_proto,
                )
                let mut i = 0.0
                match keys_list {
                  Object({ properties: keys_props, .. }) => {
                    let len = match keys_props.get("length") {
                      Some(Number(n)) => n.to_int()
                      _ => 0
                    }
                    for j in 0..<len {
                      let k_val = match keys_props.get(j.to_string()) {
                        Some(v) => v
                        None => Undefined
                      }
                      let k = k_val.to_string()
                      if not(k.has_prefix("Symbol(")) {
                        // Object.keys only returns enumerable keys
                        let get_own_property_descriptor = match
                          ctx.resolve("Object") {
                          Object(obj_ctor) =>
                            JSValue::Object(obj_ctor).get_property(
                              "getOwnPropertyDescriptor",
                            )
                          _ => Undefined
                        }
                        let desc_val = match get_own_property_descriptor {
                          Object(f) =>
                            if f.is_callable {
                              ctx.invoke(f, Undefined, [
                                target,
                                JSValue::String(k),
                              ]) catch {
                                _ => Undefined
                              }
                            } else {
                              Undefined
                            }
                          _ => Undefined
                        }
                        let is_enumerable = match desc_val {
                          Object(o) =>
                            match o.properties.get("enumerable") {
                              Some(Boolean(b)) => b
                              _ => false
                            }
                          _ => false
                        }
                        if is_enumerable {
                          keys_array[i.to_string()] = JSValue::String(k)
                          i = i + 1.0
                        }
                      }
                    }
                  }
                  _ => ()
                }
                keys_array["length"] = JSValue::Number(i)
                return JSValue::Object(keys_array)
              }
            _ => ()
          }
        }
        _ => ()
      }
      let obj_props = match obj_arg {
        Object({ properties, .. }) => properties
        _ => {
          if obj_arg == JSValue::Null || obj_arg == JSValue::Undefined {
            ctx.throw_type_error("Cannot convert undefined or null to object")
          }
          return JSValue::Undefined
        }
      }
      let array_proto = match ctx.resolve("Array") {
        Object(f) => JSValue::Object(f).get_property("prototype")
        _ => proto
      }
      let keys_array = JSObject::new(properties={}, prototype=array_proto)
      let mut i = 0.0
      // Handle String indices
      let is_string_obj = obj_props.contains("PrimitiveValue") &&
        (match obj_props.get("PrimitiveValue") {
          Some(String(_)) => true
          _ => false
        })
      if is_string_obj {
        let len = match obj_props.get("length") {
          Some(Number(n)) => n.to_int()
          _ => 0
        }
        for idx in 0..<len {
          keys_array[i.to_string()] = JSValue::String(idx.to_string())
          i = i + 1.0
        }
      }
      for k, _ in obj_props {
        if not(k.has_prefix("Symbol(")) &&
          not(k.has_prefix("__")) &&
          k != "PrimitiveValue" &&
          k != "length" {
          // Object.keys only returns enumerable keys
          let is_enumerable = match obj_props.get("__descriptors") {
            Some(Object(d)) =>
              match d.properties.get(k) {
                Some(Object(desc)) =>
                  match desc.properties.get("enumerable") {
                    Some(Boolean(b)) => b
                    _ => true
                  }
                _ => true
              }
            _ => true
          }
          if is_enumerable {
            keys_array[i.to_string()] = JSValue::String(k)
            i = i + 1.0
          }
        }
      }
      keys_array["length"] = JSValue::Number(i)
      JSValue::Object(keys_array)
    } else {
      ctx.throw_type_error("Cannot convert undefined or null to object")
      JSValue::Undefined
    }
  })
  let keys_obj = JSObject::new_function(
    name="keys",
    params=["obj"],
    body=keys_fn,
    prototype=func_proto,
  )
  object_fn["keys"] = JSValue::Object(keys_obj)

  // Object.create
  let create_fn = Native(fn(ctx, _this_val, args) {
    if args is [proto_arg, ..] {
      match proto_arg {
        Object(_) | Null =>
          JSValue::Object(JSObject::new(properties={}, prototype=proto_arg))
        _ => {
          ctx.throw_type_error(
            "Object.create: prototype must be an object or null",
          )
          JSValue::Undefined
        }
      }
    } else {
      ctx.throw_type_error("Object.create requires at least 1 argument")
      JSValue::Undefined
    }
  })
  let create_obj = JSObject::new_function(
    name="create",
    params=["proto", "properties"],
    body=create_fn,
    prototype=func_proto,
  )
  object_fn["create"] = JSValue::Object(create_obj)

  // Object.is
  let is_fn = Native(fn(_ctx, _this_val, args) {
    if args is [v1, v2, ..] {
      JSValue::Boolean(v1.strict_equal(v2))
    } else {
      JSValue::Boolean(false)
    }
  })
  let is_obj = JSObject::new_function(
    name="is",
    params=["value1", "value2"],
    body=is_fn,
    prototype=func_proto,
  )
  object_fn["is"] = JSValue::Object(is_obj)

  // Object.assign
  let assign_fn = Native(fn(_ctx, _this_val, args) {
    if args is [target_arg, ..] {
      let properties = match target_arg {
        Object({ properties, .. }) => properties
        _ => return target_arg
      }
      for i = 1; i < args.length(); i = i + 1 {
        let src_props = match args[i] {
          Object({ properties, .. }) => properties
          _ => continue
        }
        for k, v in src_props {
          if not(k.has_prefix("__")) && k != "PrimitiveValue" {
            properties.set(k, v)
          }
        }
      }
      target_arg
    } else {
      JSValue::Undefined
    }
  })
  let assign_obj = JSObject::new_function(
    name="assign",
    params=["target", "...sources"],
    body=assign_fn,
    prototype=func_proto,
  )
  object_fn["assign"] = JSValue::Object(assign_obj)

  // Object.defineProperty (Simplified but handles accessors)
  let define_property_fn = Native(fn(ctx, _this_val, args) {
    if args
      is [
        Object({ proxy_target: Some(target), proxy_handler: Some(handler), .. }) as proxy,
        prop_arg,
        desc_arg,
        ..,
      ] {
      let trap = handler.get_property("defineProperty")
      match trap {
        Object(f) =>
          if f.is_callable {
            let res = ctx.invoke(f, handler, [target, prop_arg, desc_arg]) catch {
              e => raise e
            }
            if not(res.is_truthy()) {
              ctx.throw_type_error("Proxy defineProperty trap returned false")
            }
            return proxy
          }
        _ => ()
      }
    }
    if args
      is [
        Object({ properties, .. } as o),
        prop_arg,
        Object({ properties: desc_props, .. }),
        ..,
      ] {
      let prop = prop_arg.to_property_key()
      let has_own = match get_desc_entry(o, prop) {
        Some(_) => true
        None => properties.contains(prop)
      }
      if not(has_own) && not(o.extensible) {
        ctx.throw_type_error("Cannot define property on non-extensible object")
      }
      let mut current_desc = match get_desc_entry(o, prop) {
        Some(d) => d
        None =>
          if properties.contains(prop) {
            infer_desc_entry(o, prop)
          } else {
            let is_accessor = desc_props.contains("get") ||
              desc_props.contains("set")
            if is_accessor {
              let d_props = {
                "get": Undefined,
                "set": Undefined,
                "enumerable": JSValue::Boolean(false),
                "configurable": JSValue::Boolean(false),
              }
              JSObject::new(properties=d_props, prototype=proto)
            } else {
              let d_props = {
                "value": Undefined,
                "writable": JSValue::Boolean(false),
                "enumerable": JSValue::Boolean(false),
                "configurable": JSValue::Boolean(false),
              }
              JSObject::new(properties=d_props, prototype=proto)
            }
          }
      }
      if has_own {
        let cur_conf = match current_desc.properties.get("configurable") {
          Some(Boolean(b)) => b
          _ => false
        }
        if not(cur_conf) {
          match desc_props.get("configurable") {
            Some(Boolean(true)) =>
              ctx.throw_type_error(
                "Cannot redefine non-configurable property '" + prop + "'",
              )
            _ => ()
          }
          let cur_enum = match current_desc.get("enumerable") {
            Boolean(b) => b
            _ => false
          }
          match desc_props.get("enumerable") {
            Some(Boolean(new_enum)) =>
              if new_enum != cur_enum {
                ctx.throw_type_error(
                  "Cannot change enumerable attribute of non-configurable property '" +
                  prop +
                  "'",
                )
              }
            _ => ()
          }
          let is_current_accessor = current_desc.properties.contains("get") ||
            current_desc.properties.contains("set")
          let is_desc_accessor = desc_props.contains("get") ||
            desc_props.contains("set")
          let is_desc_data = desc_props.contains("value") ||
            desc_props.contains("writable")
          if is_current_accessor && is_desc_data {
            ctx.throw_type_error(
              "Cannot change non-configurable accessor property to data property",
            )
          }
          if not(is_current_accessor) && is_desc_accessor {
            ctx.throw_type_error(
              "Cannot change non-configurable data property to accessor property",
            )
          }
          if not(is_current_accessor) && not(is_desc_accessor) {
            let cur_writable = match current_desc.properties.get("writable") {
              Some(Boolean(b)) => b
              _ => false
            }
            if not(cur_writable) {
              match desc_props.get("writable") {
                Some(Boolean(true)) =>
                  ctx.throw_type_error(
                    "Cannot change non-configurable, non-writable property to writable",
                  )
                _ => ()
              }
              match desc_props.get("value") {
                Some(new_val) => {
                  let cur_val = match current_desc.properties.get("value") {
                    Some(v) => v
                    _ => Undefined
                  }
                  if not(new_val.strict_equal(cur_val)) {
                    ctx.throw_type_error(
                      "Cannot change value of non-configurable, non-writable property",
                    )
                  }
                }
                None => ()
              }
            }
          }
        }
      }
      if desc_props.contains("get") || desc_props.contains("set") {
        let get_val = match desc_props.get("get") {
          Some(v) => v
          None => current_desc.get("get")
        }
        let set_val = match desc_props.get("set") {
          Some(v) => v
          None => current_desc.get("set")
        }
        let getter = match get_val {
          Object(f) => if f.is_callable { Some(f) } else { None }
          _ => None
        }
        let setter = match set_val {
          Object(f) => if f.is_callable { Some(f) } else { None }
          _ => None
        }
        properties[prop] = Internal(Accessor(getter, setter))
        let d_props = { "get": get_val, "set": set_val }
        let enumerable = match desc_props.get("enumerable") {
          Some(Boolean(b)) => b
          _ =>
            match current_desc.properties.get("enumerable") {
              Some(Boolean(b)) => b
              _ => false
            }
        }
        let configurable = match desc_props.get("configurable") {
          Some(Boolean(b)) => b
          _ =>
            match current_desc.properties.get("configurable") {
              Some(Boolean(b)) => b
              _ => false
            }
        }
        d_props.set("enumerable", JSValue::Boolean(enumerable))
        d_props.set("configurable", JSValue::Boolean(configurable))
        current_desc = JSObject::new(properties=d_props, prototype=proto)
      } else {
        let value = match desc_props.get("value") {
          Some(v) => v
          None =>
            match current_desc.properties.get("value") {
              Some(v) => v
              None =>
                match properties.get(prop) {
                  Some(v) => v
                  None => Undefined
                }
            }
        }
        properties[prop] = value
        let writable = match desc_props.get("writable") {
          Some(Boolean(b)) => b
          _ =>
            match current_desc.properties.get("writable") {
              Some(Boolean(b)) => b
              _ => false
            }
        }
        let enumerable = match desc_props.get("enumerable") {
          Some(Boolean(b)) => b
          _ =>
            match current_desc.properties.get("enumerable") {
              Some(Boolean(b)) => b
              _ => false
            }
        }
        let configurable = match desc_props.get("configurable") {
          Some(Boolean(b)) => b
          _ =>
            match current_desc.properties.get("configurable") {
              Some(Boolean(b)) => b
              _ => false
            }
        }
        let d_props = {
          "value": value,
          "writable": JSValue::Boolean(writable),
          "enumerable": JSValue::Boolean(enumerable),
          "configurable": JSValue::Boolean(configurable),
        }
        current_desc = JSObject::new(properties=d_props, prototype=proto)
      }
      set_desc_entry(o, prop, current_desc)
      Object(o)
    } else {
      ctx.throw_type_error(
        "Object.defineProperty requires an object and a property descriptor",
      )
      JSValue::Undefined
    }
  })
  let define_property_obj = JSObject::new_function(
    name="defineProperty",
    params=["obj", "prop", "desc"],
    body=define_property_fn,
    prototype=func_proto,
  )
  object_fn["defineProperty"] = JSValue::Object(define_property_obj)

  // Object.defineProperties
  let define_properties_fn = Native(fn(ctx, _this_val, args) {
    if args is [obj_arg, props_arg, ..] {
      if not(obj_arg.is_object()) {
        ctx.throw_type_error("Object.defineProperties called on non-object")
      }
      if not(props_arg.is_object()) {
        ctx.throw_type_error(
          "Object.defineProperties: descriptors must be an object",
        )
      }
      let define_prop_fn = match ctx.resolve("Object") {
        Object(ctor) => ctor.get("defineProperty")
        _ => Undefined
      }
      match define_prop_fn {
        Object(f) if f.is_callable =>
          match props_arg {
            Object(o) => {
              let keys = o.properties.keys()
              for k in keys {
                if not(k.has_prefix("__")) {
                  let desc = o.get(k)
                  if desc != Undefined {
                    let _ = ctx.invoke(f, Undefined, [
                      obj_arg,
                      JSValue::String(k),
                      desc,
                    ]) catch {
                      e => raise e
                    }

                  }
                }
              }
            }
            _ => ()
          }
        _ => ()
      }
      obj_arg
    } else {
      ctx.throw_type_error("Object.defineProperties requires 2 arguments")
      JSValue::Undefined
    }
  })
  let define_properties_obj = JSObject::new_function(
    name="defineProperties",
    params=["obj", "props"],
    body=define_properties_fn,
    prototype=func_proto,
  )
  object_fn["defineProperties"] = JSValue::Object(define_properties_obj)

  // Object.freeze
  let freeze_fn = Native(fn(ctx, _this_val, args) raise EvalError {
    if args is [obj_arg, ..] {
      match obj_arg {
        Object(o) => {
          // 1. Prevent Extensions
          let prevent_extensions_fn = match ctx.resolve("Object") {
            Object(obj_ctor) =>
              JSValue::Object(obj_ctor).get_property("preventExtensions")
            _ => Undefined
          }
          match prevent_extensions_fn {
            Object(f) if f.is_callable =>
              ctx.invoke(f, Undefined, [obj_arg]) |> ignore
            _ => o.extensible = false
          }

          // 2. Get all keys (names and symbols)
          let get_names_fn = match ctx.resolve("Object") {
            Object(obj_ctor) =>
              JSValue::Object(obj_ctor).get_property("getOwnPropertyNames")
            _ => Undefined
          }
          let get_syms_fn = match ctx.resolve("Object") {
            Object(obj_ctor) =>
              JSValue::Object(obj_ctor).get_property("getOwnPropertySymbols")
            _ => Undefined
          }
          let keys = []
          let collect_keys = fn(fn_val : JSValue) raise EvalError {
            match fn_val {
              Object(f) if f.is_callable => {
                let res = ctx.invoke(f, Undefined, [obj_arg])
                match res {
                  Object(arr_obj) => {
                    let len = match arr_obj.properties.get("length") {
                      Some(Number(n)) => n.to_int()
                      _ => 0
                    }
                    for i in 0..<len {
                      match arr_obj.properties.get(i.to_string()) {
                        Some(v) => keys.push(v)
                        _ => ()
                      }
                    }
                  }
                  _ => ()
                }
              }
              _ => ()
            }
          }
          collect_keys(get_names_fn)
          collect_keys(get_syms_fn)

          // 3. Define properties
          let define_prop_fn = match ctx.resolve("Object") {
            Object(obj_ctor) =>
              JSValue::Object(obj_ctor).get_property("defineProperty")
            _ => Undefined
          }
          let get_desc_fn = match ctx.resolve("Object") {
            Object(obj_ctor) =>
              JSValue::Object(obj_ctor).get_property("getOwnPropertyDescriptor")
            _ => Undefined
          }
          for k in keys {
            // Get descriptor to check if it's an accessor
            let (is_accessor, cur_enum) = match get_desc_fn {
              Object(f) if f.is_callable => {
                let d = ctx.invoke(f, Undefined, [obj_arg, k])
                match d {
                  Object(desc_obj) => {
                    let acc = desc_obj.properties.contains("get") ||
                      desc_obj.properties.contains("set")
                    let enu = match desc_obj.get("enumerable") {
                      Boolean(b) => b
                      _ => true
                    }
                    (acc, enu)
                  }
                  _ => (false, true)
                }
              }
              _ => (false, true)
            }
            let desc = JSObject::new(
              prototype=match ctx.resolve("Object") {
                Object(obj_ctor) => obj_ctor.get("prototype")
                _ => Undefined
              },
            )
            desc["configurable"] = JSValue::Boolean(false)
            desc["enumerable"] = JSValue::Boolean(cur_enum)
            if not(is_accessor) {
              desc["writable"] = JSValue::Boolean(false)
            } else {
              // For accessors, ensure get/set are present in the descriptor if they exist
              match get_desc_fn {
                Object(f) if f.is_callable => {
                  let d = ctx.invoke(f, Undefined, [obj_arg, k])
                  match d {
                    Object(desc_obj) => {
                      match desc_obj.get("get") {
                        v if v != Undefined => desc["get"] = v
                        _ => ()
                      }
                      match desc_obj.get("set") {
                        v if v != Undefined => desc["set"] = v
                        _ => ()
                      }
                    }
                    _ => ()
                  }
                }
                _ => ()
              }
            }
            match define_prop_fn {
              Object(f) if f.is_callable =>
                ctx.invoke(f, Undefined, [obj_arg, k, JSValue::Object(desc)])
                |> ignore
              _ => ()
            }
          }
          o.is_frozen = true
          o.is_sealed = true
        }
        _ => ()
      }
      obj_arg
    } else {
      JSValue::Undefined
    }
  })
  let freeze_obj = JSObject::new_function(
    name="freeze",
    params=["obj"],
    body=freeze_fn,
    prototype=func_proto,
  )
  object_fn["freeze"] = JSValue::Object(freeze_obj)

  // Object.isFrozen
  let is_frozen_fn = Native(fn(_ctx, _this_val, args) {
    if args is [obj_arg, ..] {
      match obj_arg {
        Object(o) => JSValue::Boolean(o.is_frozen)
        _ => JSValue::Boolean(true) // Primitives are always frozen in ES6+
      }
    } else {
      JSValue::Boolean(true)
    }
  })
  let is_frozen_obj = JSObject::new_function(
    name="isFrozen",
    params=["obj"],
    body=is_frozen_fn,
    prototype=func_proto,
  )
  object_fn["isFrozen"] = JSValue::Object(is_frozen_obj)

  // Object.seal
  let seal_fn = Native(fn(_ctx, _this_val, args) {
    if args is [obj_arg, ..] {
      match obj_arg {
        Object(o) => {
          o.extensible = false
          o.is_sealed = true
          obj_arg
        }
        _ => obj_arg
      }
    } else {
      JSValue::Undefined
    }
  })
  let seal_obj = JSObject::new_function(
    name="seal",
    params=["obj"],
    body=seal_fn,
    prototype=func_proto,
  )
  object_fn["seal"] = JSValue::Object(seal_obj)

  // Object.isSealed
  let is_sealed_fn = Native(fn(_ctx, _this_val, args) {
    if args is [obj_arg, ..] {
      match obj_arg {
        Object(o) => JSValue::Boolean(o.is_sealed)
        _ => JSValue::Boolean(true)
      }
    } else {
      JSValue::Boolean(true)
    }
  })
  let is_sealed_obj = JSObject::new_function(
    name="isSealed",
    params=["obj"],
    body=is_sealed_fn,
    prototype=func_proto,
  )
  object_fn["isSealed"] = JSValue::Object(is_sealed_obj)

  // Object.preventExtensions
  let prevent_extensions_fn = Native(fn(ctx, _this_val, args) {
    if args
      is [
        Object({ proxy_target: Some(target), proxy_handler: Some(handler), .. }) as proxy,
        ..,
      ] {
      let trap = handler.get_property("preventExtensions")
      match trap {
        Object(f) =>
          if f.is_callable {
            let res = ctx.invoke(f, handler, [target]) catch { e => raise e }
            if not(res.is_truthy()) {
              // TypeError
            }
            return proxy
          }
        _ => ()
      }
    }
    if args is [obj_arg, ..] {
      match obj_arg {
        Object(o) => {
          o.extensible = false
          obj_arg
        }
        _ => obj_arg
      }
    } else {
      JSValue::Undefined
    }
  })
  let prevent_extensions_obj = JSObject::new_function(
    name="preventExtensions",
    body=prevent_extensions_fn,
    prototype=func_proto,
  )
  object_fn["preventExtensions"] = JSValue::Object(prevent_extensions_obj)

  // Object.isExtensible
  let is_extensible_fn = Native(fn(ctx, _this_val, args) {
    if args is [obj_arg, ..] {
      // Proxy trap
      match obj_arg {
        Object({ proxy_target: Some(target), proxy_handler: Some(handler), .. }) => {
          let trap = handler.get_property("isExtensible")
          match trap {
            Object(f) if f.is_callable => {
              let res = ctx.invoke(f, handler, [target]) catch { e => raise e }
              let boolean_res = res.is_truthy()
              // Invariant check
              let target_is_extensible = match target {
                Object(t) => t.extensible
                _ => true
              }
              if boolean_res != target_is_extensible {
                ctx.throw_type_error(
                  "Proxy isExtensible trap invariant violated: must match target extensibility",
                )
              }
              return JSValue::Boolean(boolean_res)
            }
            Undefined | Null => {
              let obj_ctor = ctx.resolve("Object")
              let is_ext = obj_ctor.get_property("isExtensible")
              match is_ext {
                Object(f) if f.is_callable =>
                  return ctx.invoke(f, JSValue::Undefined, [target])
                _ => ()
              }
            }
            _ =>
              ctx.throw_type_error("Proxy isExtensible trap is not a function")
          }
        }
        _ => ()
      }
      match obj_arg {
        Object(o) => JSValue::Boolean(o.extensible)
        _ => JSValue::Boolean(false)
      }
    } else {
      JSValue::Boolean(false)
    }
  })
  let is_extensible_obj = JSObject::new_function(
    name="isExtensible",
    body=is_extensible_fn,
    prototype=func_proto,
  )
  object_fn["isExtensible"] = JSValue::Object(is_extensible_obj)

  // Object.getOwnPropertySymbols
  let get_own_property_symbols_fn = Native(fn(ctx, _this_val, args) {
    if args is [obj_arg, ..] {
      // Proxy trap
      match obj_arg {
        Object({ proxy_target: Some(target), proxy_handler: Some(handler), .. }) => {
          let trap = handler.get_property("ownKeys")
          match trap {
            Object(f) =>
              if f.is_callable {
                let keys_list = ctx.invoke(f, handler, [target]) catch {
                  e => raise e
                }
                let array_proto = match ctx.resolve("Array") {
                  Object(f) => JSValue::Object(f).get_property("prototype")
                  _ => proto
                }
                let symbols_array = JSObject::new(
                  properties={},
                  prototype=array_proto,
                )
                let mut i = 0.0
                match keys_list {
                  Object({ properties: keys_props, .. }) => {
                    let len = match keys_props.get("length") {
                      Some(Number(n)) => n.to_int()
                      _ => 0
                    }
                    let seen_keys = {}
                    for j = 0; j < len; j = j + 1 {
                      let k = match keys_props.get(j.to_string()) {
                        Some(v) => v
                        None => Undefined
                      }
                      let k_str = k.to_string()
                      if seen_keys.contains(k_str) {
                        ctx.throw_type_error(
                          "Proxy ownKeys trap returned duplicate keys",
                        )
                      }
                      seen_keys.set(k_str, true)
                      match k {
                        Symbol(_, _) => {
                          symbols_array[i.to_string()] = k
                          i = i + 1.0
                        }
                        _ => ()
                      }
                    }
                    // Invariants check
                    let is_target_extensible = match target {
                      Object(o) => o.extensible
                      _ => true
                    }
                    let target_props = match target {
                      Object(o) => o.properties
                      _ => {}
                    }
                    let is_sealed = match target {
                      Object(o) => o.is_sealed
                      _ => false
                    }

                    // Check that all non-configurable properties are present
                    // and if non-extensible, all properties are present.
                    for k, _ in target_props {
                      if k == "PrimitiveValue" || k.has_prefix("__") {
                        continue
                      }
                      let is_configurable = match
                        target_props.get("__descriptors") {
                        Some(Object(d)) =>
                          match d.properties.get(k) {
                            Some(Object(desc)) =>
                              match desc.properties.get("configurable") {
                                Some(Boolean(b)) => b
                                _ => true
                              }
                            _ => true
                          }
                        _ => true
                      }
                      if not(is_configurable) ||
                        is_sealed ||
                        not(is_target_extensible) {
                        if not(seen_keys.contains(k)) {
                          ctx.throw_type_error(
                            "Proxy ownKeys trap failed to include a required property: " +
                            k,
                          )
                        }
                      }
                    }
                    if not(is_target_extensible) {
                      for k, _ in seen_keys {
                        if not(target_props.contains(k)) && k != "length" {
                          // Check for string indices
                          let is_str_idx = match target {
                            Object(o) =>
                              match o.properties.get("PrimitiveValue") {
                                Some(String(s)) => {
                                  let idx = @strconv.parse_int(k) catch {
                                    _ => -1
                                  }
                                  idx >= 0 && idx < s.length()
                                }
                                _ => false
                              }
                            _ => false
                          }
                          if not(is_str_idx) {
                            ctx.throw_type_error(
                              "Proxy ownKeys trap returned extra property for non-extensible target",
                            )
                          }
                        }
                      }
                    }
                  }
                  _ =>
                    ctx.throw_type_error(
                      "Proxy ownKeys trap must return an object",
                    )
                }
                symbols_array["length"] = JSValue::Number(i)
                return JSValue::Object(symbols_array)
              }
            _ => ()
          }
        }
        _ => ()
      }
      let obj_props = match obj_arg {
        Object({ properties, .. }) => properties
        _ => {
          if obj_arg == JSValue::Null || obj_arg == JSValue::Undefined {
            ctx.throw_type_error("Cannot convert undefined or null to object")
          }
          // For primitives, return []
          let array_proto = match ctx.resolve("Array") {
            Object(f) => JSValue::Object(f).get_property("prototype")
            _ => proto
          }
          let empty_array = JSObject::new(properties={}, prototype=array_proto)
          empty_array["length"] = JSValue::Number(0.0)
          return JSValue::Object(empty_array)
        }
      }
      let array_proto = match ctx.resolve("Array") {
        Object(f) => JSValue::Object(f).get_property("prototype")
        _ => proto
      }
      let symbols_array = JSObject::new(properties={}, prototype=array_proto)
      let mut i = 0.0
      for k, _ in obj_props {
        try {
          if k.has_prefix("Symbol(") {
            let s = k[7:k.length() - 1].to_string()
            let comma_idx = s.find(",").unwrap_or(-1)
            if comma_idx != -1 {
              let id_str = s[:comma_idx].to_string()
              let desc = s[comma_idx + 1:].to_string()
              let id = @strconv.parse_int(id_str) catch { _ => -1 }
              if id >= 0 {
                symbols_array[i.to_string()] = JSValue::Symbol(id, desc)
                i = i + 1.0
              }
            }
          }
        } catch {
          _ => continue
        }
      }
      symbols_array["length"] = JSValue::Number(i)
      JSValue::Object(symbols_array)
    } else {
      ctx.throw_type_error("Cannot convert undefined or null to object")
      JSValue::Undefined
    }
  })
  let get_own_property_symbols_obj = JSObject::new_function(
    name="getOwnPropertySymbols",
    params=["obj"],
    body=get_own_property_symbols_fn,
    prototype=func_proto,
  )
  object_fn["getOwnPropertySymbols"] = JSValue::Object(
    get_own_property_symbols_obj,
  )

  // Object.getOwnPropertyDescriptor
  let get_own_property_descriptor_fn = Native(fn(ctx, _this_val, args) {
    if args is [obj_arg, ..] {
      let prop_arg = if args.length() > 1 {
        args[1]
      } else {
        JSValue::Undefined
      }
      // Proxy trap
      match obj_arg {
        Object(o) if o.is_proxy => {
          let (target, handler) = match (o.proxy_target, o.proxy_handler) {
            (Some(t), Some(h)) => (t, h)
            _ =>
              ctx.throw_type_error(
                "Cannot perform 'getOwnPropertyDescriptor' on a revoked proxy",
              )
          }
          let trap = handler.get_property("getOwnPropertyDescriptor")
          match trap {
            Object(f) if f.is_callable => {
              let trap_res = ctx.invoke(f, handler, [target, prop_arg]) catch {
                e => raise e
              }
              if not(trap_res.is_object()) && trap_res != Undefined {
                ctx.throw_type_error(
                  "Proxy getOwnPropertyDescriptor trap must return an object or undefined",
                )
              }
              // Invariant checks
              let target_desc = match ctx.resolve("Object") {
                Object(ctor) =>
                  match ctor.get("getOwnPropertyDescriptor") {
                    Object(gopd) if gopd.is_callable =>
                      ctx.invoke(gopd, Undefined, [target, prop_arg]) catch {
                        _ => Undefined
                      }
                    _ => Undefined
                  }
                _ => Undefined
              }
              if trap_res == Undefined {
                match target_desc {
                  Object(d) => {
                    let configurable = match d.get("configurable") {
                      Boolean(b) => b
                      _ => true
                    }
                    if not(configurable) {
                      ctx.throw_type_error(
                        "Proxy getOwnPropertyDescriptor trap invariant violated: cannot report undefined for non-configurable property",
                      )
                    }
                  }
                  _ => ()
                }
                // Check if target is non-extensible
                let is_ext = match ctx.resolve("Object") {
                  Object(ctor) =>
                    match ctor.get("isExtensible") {
                      Object(ie) if ie.is_callable =>
                        ctx.invoke(ie, Undefined, [target]).is_truthy()
                      _ => true
                    }
                  _ => true
                }
                if not(is_ext) && target_desc != Undefined {
                  ctx.throw_type_error(
                    "Proxy getOwnPropertyDescriptor trap invariant violated: cannot report undefined for existing property on non-extensible target",
                  )
                }
                return Undefined
              }
              // Normalize trap_res
              match trap_res {
                Object(tr_obj) => {
                  let res_desc = JSObject::new(
                    prototype=ctx.resolve("Object").get_property("prototype"),
                  )
                  // Copy properties and complete them
                  let keys = [
                    "value", "writable", "get", "set", "enumerable", "configurable",
                  ]
                  let is_accessor = tr_obj.get("get") != Undefined ||
                    tr_obj.get("set") != Undefined
                  for k in keys {
                    let v = tr_obj.get(k)
                    if v != Undefined {
                      res_desc[k] = v
                      // CompletePropertyDescriptor
                    } else if k == "enumerable" ||
                      k == "configurable" ||
                      k == "writable" {
                      if k == "writable" && is_accessor {
                        () // writable is not for accessors
                      } else {
                        res_desc[k] = JSValue::Boolean(false)
                      }
                    } else if k == "value" || k == "get" || k == "set" {
                      res_desc[k] = Undefined
                    }
                  }
                  // Invariant: non-configurable property
                  match target_desc {
                    Object(td) => {
                      let t_conf = match td.get("configurable") {
                        Boolean(b) => b
                        _ => true
                      }
                      let r_conf = match res_desc.get("configurable") {
                        Boolean(b) => b
                        _ => false
                      }
                      if t_conf && not(r_conf) {
                        ctx.throw_type_error(
                          "Proxy getOwnPropertyDescriptor trap invariant violated: cannot report non-configurable for configurable property",
                        )
                      }
                      if not(t_conf) {
                        if r_conf {
                          ctx.throw_type_error(
                            "Proxy getOwnPropertyDescriptor trap invariant violated: cannot report configurable for non-configurable property",
                          )
                        }
                        // Check compatibility
                        let t_writable = match td.get("writable") {
                          Boolean(b) => b
                          _ => false
                        }
                        if not(t_writable) {
                          let r_writable = match res_desc.get("writable") {
                            Boolean(b) => b
                            _ => false
                          }
                          if r_writable {
                            ctx.throw_type_error(
                              "Proxy getOwnPropertyDescriptor trap invariant violated: cannot report writable for non-writable property",
                            )
                          }
                        }
                      }
                    }
                    _ => {
                      // target_desc is undefined
                      let is_ext = match ctx.resolve("Object") {
                        Object(ctor) =>
                          match ctor.get("isExtensible") {
                            Object(ie) if ie.is_callable =>
                              ctx.invoke(ie, Undefined, [target]).is_truthy()
                            _ => true
                          }
                        _ => true
                      }
                      if not(is_ext) {
                        ctx.throw_type_error(
                          "Proxy getOwnPropertyDescriptor trap invariant violated: cannot report new property on non-extensible target",
                        )
                      }
                      let r_conf = match res_desc.get("configurable") {
                        Boolean(b) => b
                        _ => false
                      }
                      if not(r_conf) {
                        ctx.throw_type_error(
                          "Proxy getOwnPropertyDescriptor trap invariant violated: cannot report non-configurable for non-existent property",
                        )
                      }
                    }
                  }
                  return JSValue::Object(res_desc)
                }
                _ => return Undefined // Should be unreachable
              }
            }
            Undefined | Null => {
              let gopd = match ctx.resolve("Object") {
                Object(ctor) => ctor.get("getOwnPropertyDescriptor")
                _ => Undefined
              }
              match gopd {
                Object(f) if f.is_callable =>
                  return ctx.invoke(f, Undefined, [target, prop_arg])
                _ => ()
              }
            }
            _ =>
              ctx.throw_type_error(
                "Proxy getOwnPropertyDescriptor trap is not a function",
              )
          }
        }
        _ => ()
      }

      // Check if obj_arg is global object
      let is_global = match ctx.resolve("globalThis") {
        Object(g) => {
          let g_val = JSValue::Object(g)
          g_val.strict_equal(obj_arg) ||
          (match obj_arg {
            Object(o) if o.is_proxy =>
              match o.proxy_target {
                Some(t) => t.strict_equal(g_val)
                _ => false
              }
            _ => false
          })
        }
        _ => false
      }
      let (
        obj_props,
        is_func,
        is_native_func,
        is_string_obj,
        is_frozen,
        is_sealed,
        is_array,
      ) = match obj_arg {
        Object(o) => {
          let properties = o.properties
          let is_frozen = o.is_frozen
          let is_sealed = o.is_sealed
          let is_func = o.is_callable
          let is_native = match o.call_info {
            Some({ body: Native(_), .. }) => true
            _ => false
          }
          let is_str = match properties.get("PrimitiveValue") {
            Some(String(_)) => true
            _ => false
          }
          let is_array = not(is_func) &&
            not(is_str) &&
            properties.contains("length")
          (
            properties, is_func, is_native, is_str, is_frozen, is_sealed, is_array,
          )
        }
        _ => {
          if obj_arg == JSValue::Null || obj_arg == JSValue::Undefined {
            ctx.throw_type_error("Cannot convert undefined or null to object")
          }
          return JSValue::Undefined
        }
      }
      let prop = match prop_arg {
        _ => prop_arg.to_property_key()
      }
      if prop == "length" && not(is_string_obj) {
        // Force check PrimitiveValue
        let has_prim = obj_props.contains("PrimitiveValue")
        if has_prim {
          // If it has PrimitiveValue but is_string_obj is false, it must be that match failed.
          match obj_props.get("PrimitiveValue") {
            Some(String(_)) => () // Should be true
            Some(_) => () // Not a string?
            None => ()
          }
        }
      }
      if is_string_obj {
        let (len, str_val) = match obj_arg {
          Object({ proxy_target: Some(Object(t)), .. }) => {
            let l = match t.properties.get("length") {
              Some(Number(n)) => n.to_int()
              _ => 0
            }
            let s = match t.properties.get("PrimitiveValue") {
              Some(String(s)) => s
              _ => ""
            }
            (l, s)
          }
          Object(o) => {
            let l = match o.properties.get("length") {
              Some(Number(n)) => n.to_int()
              _ => 0
            }
            let s = match o.properties.get("PrimitiveValue") {
              Some(String(s)) => s
              _ => ""
            }
            (l, s)
          }
          _ => (0, "")
        }
        let idx = @strconv.parse_int(prop) catch { _ => -1 }
        if idx >= 0 && idx < len {
          let char_code = str_val[idx].to_int()
          let c = match char_code.to_char() {
            Some(c) => c
            None => ' '
          }
          let char_str = String::make(1, c)
          let desc = JSObject::new(properties={}, prototype=proto)
          desc["value"] = JSValue::String(char_str)
          desc["writable"] = JSValue::Boolean(false)
          desc["enumerable"] = JSValue::Boolean(true)
          desc["configurable"] = JSValue::Boolean(false)
          return JSValue::Object(desc)
        }
      }
      match obj_props.get(prop) {
        Some(val) => {
          let desc = JSObject::new(properties={}, prototype=proto)
          // println("DEBUG: getOwnPropertyDescriptor prop=" + prop)

          // Check for custom descriptors
          let custom_desc = match obj_props.get("__descriptors") {
            Some(Object(d)) => d.properties.get(prop)
            _ => None
          }
          match custom_desc {
            Some(Object(cd)) =>
              for k, v in cd.properties {
                desc[k] = v
              }
            _ => ()
          }
          if prop == "Proxy" {
            // Check if it's the global object more directly
            match ctx.resolve("globalThis") {
              Object(g) if JSValue::Object(g).strict_equal(obj_arg) =>
                desc["enumerable"] = JSValue::Boolean(false)
              _ => ()
            }
          }
          if custom_desc is Some(Object(_)) {
            return JSValue::Object(desc)
          }
          match val {
            Internal(Accessor(getter, setter)) => {
              desc["get"] = getter.map(JSValue::Object(_)).unwrap_or(Undefined)
              desc["set"] = setter.map(JSValue::Object(_)).unwrap_or(Undefined)
              desc["enumerable"] = JSValue::Boolean(true)
              desc["configurable"] = JSValue::Boolean(not(is_sealed))
            }
            _ => {
              let is_symbol_to_string_tag = prop.contains("toStringTag")
              if is_symbol_to_string_tag {
                let d_props = {
                  "writable": JSValue::Boolean(false),
                  "enumerable": JSValue::Boolean(false),
                  "configurable": JSValue::Boolean(true),
                  "value": val,
                }
                return JSValue::Object(
                  JSObject::new(properties=d_props, prototype=proto),
                )
              }
              let is_symbol_iterator = prop.contains("iterator")
              if is_symbol_iterator {
                let d_props = {
                  "writable": JSValue::Boolean(true),
                  "enumerable": JSValue::Boolean(false),
                  "configurable": JSValue::Boolean(true),
                  "value": val,
                }
                return JSValue::Object(
                  JSObject::new(properties=d_props, prototype=proto),
                )
              }
              desc["value"] = val
              desc["writable"] = JSValue::Boolean(not(is_frozen))
              desc["enumerable"] = JSValue::Boolean(true)
              desc["configurable"] = JSValue::Boolean(not(is_sealed))
              if is_func {
                if prop == "length" || prop == "name" {
                  desc["writable"] = JSValue::Boolean(false)
                  desc["enumerable"] = JSValue::Boolean(false)
                  desc["configurable"] = JSValue::Boolean(true)
                }
                if prop == "caller" || prop == "arguments" {
                  desc["enumerable"] = JSValue::Boolean(false)
                  desc["configurable"] = JSValue::Boolean(false)
                }
                if prop == "prototype" {
                  desc["enumerable"] = JSValue::Boolean(false)
                  desc["configurable"] = JSValue::Boolean(false)
                  if is_native_func {
                    desc["writable"] = JSValue::Boolean(false)
                  } else {
                    desc["writable"] = JSValue::Boolean(true)
                  }
                }
              }
              if (is_string_obj || is_array) && prop == "length" {
                desc["writable"] = JSValue::Boolean(is_array)
                desc["enumerable"] = JSValue::Boolean(false)
                desc["configurable"] = JSValue::Boolean(false)
              }
              if is_global {
                if prop
                  is ("String"
                  | "Number"
                  | "Boolean"
                  | "Array"
                  | "Object"
                  | "Function"
                  | "Math"
                  | "Date"
                  | "RegExp"
                  | "Error"
                  | "EvalError"
                  | "RangeError"
                  | "ReferenceError"
                  | "SyntaxError"
                  | "TypeError"
                  | "URIError"
                  | "JSON"
                  | "Reflect"
                  | "eval"
                  | "parseInt"
                  | "parseFloat"
                  | "isNaN"
                  | "isFinite"
                  | "Map"
                  | "Set"
                  | "WeakMap"
                  | "WeakSet"
                  | "Promise"
                  | "Proxy"
                  | "Symbol") {
                  desc["enumerable"] = JSValue::Boolean(false)
                }
              }

              // Map.prototype and Set.prototype methods (heuristic)
              if prop
                is ("get"
                | "set"
                | "add"
                | "has"
                | "delete"
                | "clear"
                | "size"
                | "entries"
                | "keys"
                | "values"
                | "forEach"
                | "getOrInsertComputed"
                | "constructor") {
                // Check if it's on Map.prototype/Set.prototype or an instance
                let tag = obj_props.get("Symbol(Symbol.toStringTag)")
                let is_related = obj_props.contains("MapData") ||
                  obj_props.contains("SetData") ||
                  tag == Some(JSValue::String("Map")) ||
                  tag == Some(JSValue::String("Set"))
                if is_related {
                  desc["enumerable"] = JSValue::Boolean(false)
                }
              }
            }
          }
          JSValue::Object(desc)
        }
        None => JSValue::Undefined
      }
    } else {
      JSValue::Undefined
    }
  })
  let get_own_property_descriptor_obj = JSObject::new_function(
    name="getOwnPropertyDescriptor",
    params=["obj", "prop"],
    body=get_own_property_descriptor_fn,
    prototype=func_proto,
  )
  object_fn["getOwnPropertyDescriptor"] = JSValue::Object(
    get_own_property_descriptor_obj,
  )

  // Object.getPrototypeOf
  let get_prototype_of_fn = Native(fn(ctx, _this_val, args) {
    if args is [obj_arg, ..] {
      // Proxy trap
      match obj_arg {
        Object({ proxy_target: Some(target), proxy_handler: Some(handler), .. }) => {
          let trap = handler.get_property("getPrototypeOf")
          match trap {
            Object(f) =>
              if f.is_callable {
                let res = ctx.invoke(f, handler, [target]) catch {
                  e => raise e
                }
                return res
              }
            _ => ()
          }
        }
        _ => ()
      }
      match obj_arg {
        Object({ prototype, .. }) =>
          match prototype {
            Some(p) => p
            None => Null
          }
        _ => {
          if obj_arg == JSValue::Null || obj_arg == JSValue::Undefined {
            ctx.throw_type_error("Cannot convert undefined or null to object")
          }
          // For primitives, return their prototype
          match obj_arg {
            String(_) =>
              match ctx.resolve("String") {
                Object(f) => JSValue::Object(f).get_property("prototype")
                _ => Null
              }
            Number(_) =>
              match ctx.resolve("Number") {
                Object(f) => JSValue::Object(f).get_property("prototype")
                _ => Null
              }
            Boolean(_) =>
              match ctx.resolve("Boolean") {
                Object(f) => JSValue::Object(f).get_property("prototype")
                _ => Null
              }
            Symbol(_, _) =>
              match ctx.resolve("Symbol") {
                Object(f) => JSValue::Object(f).get_property("prototype")
                _ => Null
              }
            BigInt(_) =>
              match ctx.resolve("BigInt") {
                Object(f) => f.get("prototype")
                _ => Null
              }
            _ => Null
          }
        }
      }
    } else {
      ctx.throw_type_error("Object.getPrototypeOf requires 1 argument")
      JSValue::Undefined
    }
  })
  let get_prototype_of_obj = JSObject::new_function(
    name="getPrototypeOf",
    params=["obj"],
    body=get_prototype_of_fn,
    prototype=func_proto,
  )
  object_fn["getPrototypeOf"] = JSValue::Object(get_prototype_of_obj)

  // Object.setPrototypeOf
  let set_prototype_of_fn = Native(fn(ctx, _this_val, args) {
    if args is [obj_arg, proto_arg, ..] {
      // Proxy trap
      match obj_arg {
        Object({ proxy_target: Some(target), proxy_handler: Some(handler), .. }) => {
          let trap = handler.get_property("setPrototypeOf")
          match trap {
            Object(f) =>
              if f.is_callable {
                let res = ctx.invoke(f, handler, [target, proto_arg]) catch {
                  e => raise e
                }
                if not(res.is_truthy()) {
                  ctx.throw_type_error(
                    "Proxy setPrototypeOf trap returned false",
                  )
                }
                return obj_arg
              }
            _ => ()
          }
        }
        _ => ()
      }
      match obj_arg {
        Object(o) => o.prototype = Some(proto_arg)
        _ =>
          if obj_arg == JSValue::Null || obj_arg == JSValue::Undefined {
            ctx.throw_type_error("Cannot convert undefined or null to object")
          }
      }
      obj_arg
    } else {
      ctx.throw_type_error("Object.setPrototypeOf requires 2 arguments")
      JSValue::Undefined
    }
  })
  let set_prototype_of_obj = JSObject::new_function(
    name="setPrototypeOf",
    params=["obj", "proto"],
    body=set_prototype_of_fn,
    prototype=func_proto,
  )
  object_fn["setPrototypeOf"] = JSValue::Object(set_prototype_of_obj)

  // Object.getOwnPropertyNames
  let get_own_property_names_fn = Native(fn(ctx, _this_val, args) {
    if args is [obj_arg, ..] {
      // Proxy trap
      match obj_arg {
        Object({ proxy_target: Some(target), proxy_handler: Some(handler), .. }) => {
          let trap = handler.get_property("ownKeys")
          match trap {
            Object(f) =>
              if f.is_callable {
                let keys_list = ctx.invoke(f, handler, [target]) catch {
                  e => raise e
                }
                // Convert keys_list (array-like) to Array of names
                let array_proto = match ctx.resolve("Array") {
                  Object(f) => JSValue::Object(f).get_property("prototype")
                  _ => proto
                }
                let names_array = JSObject::new(
                  properties={},
                  prototype=array_proto,
                )
                let mut i = 0.0
                let seen_keys = {}
                match keys_list {
                  Object({ properties: keys_props, .. }) => {
                    let len = match keys_props.get("length") {
                      Some(Number(n)) => n.to_int()
                      _ => 0
                    }
                    for j in 0..<len {
                      let k_val = match keys_props.get(j.to_string()) {
                        Some(v) => v
                        None => Undefined
                      }
                      let k = k_val.to_string()
                      if seen_keys.contains(k) {
                        ctx.throw_type_error(
                          "Proxy ownKeys trap returned duplicate keys",
                        )
                      }
                      seen_keys.set(k, true)
                      if not(k.has_prefix("Symbol(")) {
                        names_array[i.to_string()] = JSValue::String(k)
                        i = i + 1.0
                      }
                    }
                    // Invariants check
                    let is_target_extensible = match target {
                      Object(o) => o.extensible
                      _ => true
                    }
                    let target_props = match target {
                      Object(o) => o.properties
                      _ => {}
                    }
                    let is_sealed = match target {
                      Object(o) => o.is_sealed
                      _ => false
                    }
                    for k, _ in target_props {
                      if k == "PrimitiveValue" || k.has_prefix("__") {
                        continue
                      }
                      if k.has_prefix("Symbol(") {
                        continue
                      }
                      let is_configurable = match
                        target_props.get("__descriptors") {
                        Some(Object(d)) =>
                          match d.properties.get(k) {
                            Some(Object(desc)) =>
                              match desc.properties.get("configurable") {
                                Some(Boolean(b)) => b
                                _ => true
                              }
                            _ => true
                          }
                        _ => true
                      }
                      if not(is_configurable) ||
                        is_sealed ||
                        not(is_target_extensible) {
                        if not(seen_keys.contains(k)) {
                          ctx.throw_type_error(
                            "Proxy ownKeys trap failed to include a required property: " +
                            k,
                          )
                        }
                      }
                    }
                    if not(is_target_extensible) {
                      for k, _ in seen_keys {
                        if not(target_props.contains(k)) && k != "length" {
                          let is_str_idx = match target {
                            Object(o) =>
                              match o.properties.get("PrimitiveValue") {
                                Some(String(s)) => {
                                  let idx = @strconv.parse_int(k) catch {
                                    _ => -1
                                  }
                                  idx >= 0 && idx < s.length()
                                }
                                _ => false
                              }
                            _ => false
                          }
                          if not(is_str_idx) {
                            ctx.throw_type_error(
                              "Proxy ownKeys trap returned extra property for non-extensible target",
                            )
                          }
                        }
                      }
                    }
                  }
                  _ => ()
                }
                names_array["length"] = JSValue::Number(i)
                return JSValue::Object(names_array)
              }
            _ => ()
          }
        }
        _ => ()
      }
      let (obj_props, is_func) = match obj_arg {
        Object({ properties, .. } as obj) => (properties, obj.is_callable)
        _ => {
          if obj_arg == JSValue::Null || obj_arg == JSValue::Undefined {
            ctx.throw_type_error("Cannot convert undefined or null to object")
          }
          // For primitives, return their keys (e.g. string indices)
          let array_proto = match ctx.resolve("Array") {
            Object(f) => JSValue::Object(f).get_property("prototype")
            _ => proto
          }
          let names_array = JSObject::new(properties={}, prototype=array_proto)
          let mut i = 0.0
          match obj_arg {
            String(s) => {
              let len = s.length()
              for idx in 0..<len {
                names_array[i.to_string()] = JSValue::String(idx.to_string())
                i = i + 1.0
              }
              names_array["length"] = JSValue::Number(i)
            }
            _ => names_array["length"] = JSValue::Number(0.0)
          }
          return JSValue::Object(names_array)
        }
      }
      let array_proto = match ctx.resolve("Array") {
        Object(f) => JSValue::Object(f).get_property("prototype")
        _ => proto
      }
      let names_array = JSObject::new(properties={}, prototype=array_proto)
      let mut i = 0.0

      // For functions, prioritize length and name
      if is_func {
        if obj_props.contains("length") {
          names_array[i.to_string()] = JSValue::String("length")
          i = i + 1.0
        }
        if obj_props.contains("name") {
          names_array[i.to_string()] = JSValue::String("name")
          i = i + 1.0
        }
      }

      // Handle String indices
      let is_string_obj = obj_props.contains("PrimitiveValue") &&
        (match obj_props.get("PrimitiveValue") {
          Some(String(_)) => true
          _ => false
        })
      if is_string_obj {
        let len = match obj_props.get("length") {
          Some(Number(n)) => n.to_int()
          _ => 0
        }
        for idx in 0..<len {
          names_array[i.to_string()] = JSValue::String(idx.to_string())
          i = i + 1.0
        }
      }
      for k, _ in obj_props {
        if not(k.has_prefix("Symbol(")) &&
          not(k.has_prefix("__")) &&
          k != "PrimitiveValue" {
          if is_func && (k == "length" || k == "name") {
            continue
          }
          names_array[i.to_string()] = JSValue::String(k)
          i = i + 1.0
        }
      }
      names_array["length"] = JSValue::Number(i)
      JSValue::Object(names_array)
    } else {
      ctx.throw_type_error("Cannot convert undefined or null to object")
      JSValue::Undefined
    }
  })
  let get_own_property_names_obj = JSObject::new_function(
    name="getOwnPropertyNames",
    params=["obj"],
    body=get_own_property_names_fn,
    prototype=func_proto,
  )
  object_fn["getOwnPropertyNames"] = JSValue::Object(get_own_property_names_obj)
  JSValue::Object(object_fn)
}

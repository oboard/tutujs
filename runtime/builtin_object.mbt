///|
pub fn init_object_prototype(
  object_proto_val : JSValue,
  func_proto : JSValue,
) -> Unit {
  match object_proto_val {
    Object(obj) => {
      // toString
      let to_string_fn = Native(fn(_ctx, this_val, _args) {
        JSValue::String(
          match this_val {
            Object({ properties, .. }) =>
              match properties.get("PrimitiveValue") {
                Some(String(_)) => "[object String]"
                Some(Number(_)) => "[object Number]"
                Some(Boolean(_)) => "[object Boolean]"
                _ => "[object Object]"
              }
            Function(_) => "[object Function]"
            String(_) => "[object String]"
            Number(_) => "[object Number]"
            Boolean(_) => "[object Boolean]"
            _ => "[object Object]"
          },
        )
      })
      let to_string_obj = JSFunction::new(
        name="toString",
        body=to_string_fn,
        prototype=func_proto,
      )
      obj["toString"] = JSValue::Function(to_string_obj)

      // valueOf
      let value_of_fn = Native(fn(_ctx, this_val, _args) { this_val })
      let value_of_obj = JSFunction::new(
        name="valueOf",
        body=value_of_fn,
        prototype=func_proto,
      )
      obj["valueOf"] = JSValue::Function(value_of_obj)

      // toLocaleString
      let to_locale_string_fn = Native(fn(ctx, this_val, _args) {
        let to_string = this_val.get_property("toString")
        match to_string {
          Function(f) => ctx.invoke(f, this_val, []) catch { e => raise e }
          _ => JSValue::String(this_val.to_string())
        }
      })
      let to_locale_string_obj = JSFunction::new(
        name="toLocaleString",
        body=to_locale_string_fn,
        prototype=func_proto,
      )
      obj["toLocaleString"] = JSValue::Function(to_locale_string_obj)

      // hasOwnProperty
      let has_own_property_fn = Native(fn(_ctx, this_val, args) {
        if args is [prop, ..] {
          let key = prop.to_string()
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
            Object({ properties, .. }) | Function({ properties, .. }) =>
              Boolean(properties.contains(key))
            _ => Boolean(false)
          }
        } else {
          Boolean(false)
        }
      })
      let has_own_property_obj = JSFunction::new(
        name="hasOwnProperty",
        params=["prop"],
        body=has_own_property_fn,
        prototype=func_proto,
      )
      obj["hasOwnProperty"] = JSValue::Function(has_own_property_obj)

      // isPrototypeOf
      let is_prototype_of_fn = Native(fn(_ctx, this_val, args) {
        if args is [arg, ..] {
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
                      Object({ prototype, .. }) | Function({ prototype, .. }) =>
                        proto = prototype
                      _ => break
                    }
                  }
                  None => break
                }
              }
              Boolean(false)
            }
            Function(f) => {
              let mut proto = f.prototype
              while true {
                match proto {
                  Some(p) => {
                    if p.strict_equal(this_val) {
                      return Boolean(true)
                    }
                    match p {
                      Object({ prototype, .. }) | Function({ prototype, .. }) =>
                        proto = prototype
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
        }
      })
      let is_prototype_of_obj = JSFunction::new(
        name="isPrototypeOf",
        params=["object"],
        body=is_prototype_of_fn,
        prototype=func_proto,
      )
      obj["isPrototypeOf"] = JSValue::Function(is_prototype_of_obj)

      // propertyIsEnumerable
      let property_is_enumerable_fn = Native(fn(ctx, this_val, args) {
        if args is [prop, ..] {
          let key = prop.to_string()
          match this_val {
            Object({ properties, .. }) | Function({ properties, .. }) => {
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

              // Map.prototype check
              if key
                is ("get"
                | "set"
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
                if properties.get("Symbol(Symbol.toStringTag)") ==
                  Some(JSValue::String("Map")) {
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
              if key
                is ("prototype" | "length" | "name" | "arguments" | "caller") {
                return Boolean(false)
              }
              if key.has_prefix("Symbol(") {
                return Boolean(false)
              }
              Boolean(properties.contains(key) && not(key.has_prefix("__")))
            }
            _ => Boolean(false)
          }
        } else {
          Boolean(false)
        }
      })
      let property_is_enumerable_obj = JSFunction::new(
        name="propertyIsEnumerable",
        params=["prop"],
        body=property_is_enumerable_fn,
        prototype=func_proto,
      )
      obj["propertyIsEnumerable"] = JSValue::Function(
        property_is_enumerable_obj,
      )
    }
    _ => ()
  }
}

///|
pub fn create_object_constructor(
  proto : JSValue,
  func_proto : JSValue,
) -> JSValue {
  let object_fn_body = Native(fn(ctx, _this_val, args) {
    if args is [val, ..] {
      match val {
        Object(_) | Function(_) => val
        Null | Undefined =>
          Object(JSObject::new(properties=@hashmap.new(), prototype=proto))
        String(s) => {
          let string_proto = match ctx.resolve("String") {
            Function(f) => f.get("prototype")
            _ => Undefined
          }
          let obj = JSObject::new(prototype=string_proto)
          obj.properties.set("PrimitiveValue", val)
          obj.properties.set("length", Number(s.length().to_double()))
          Object(obj)
        }
        Number(_) => {
          let number_proto = match ctx.resolve("Number") {
            Function(f) => f.get("prototype")
            _ => Undefined
          }
          let obj = JSObject::new(prototype=number_proto)
          obj.properties.set("PrimitiveValue", val)
          Object(obj)
        }
        Boolean(_) => {
          let boolean_proto = match ctx.resolve("Boolean") {
            Function(f) => f.get("prototype")
            _ => Undefined
          }
          let obj = JSObject::new(prototype=boolean_proto)
          obj.properties.set("PrimitiveValue", val)
          Object(obj)
        }
        Symbol(_, _) => {
          let symbol_proto = match ctx.resolve("Symbol") {
            Function(f) => f.get("prototype")
            _ => Undefined
          }
          let obj = JSObject::new(prototype=symbol_proto)
          obj.properties.set("PrimitiveValue", val)
          Object(obj)
        }
        BigInt(_) => {
          let big_proto = match ctx.resolve("BigInt") {
            Function(f) => f.get("prototype")
            _ => Undefined
          }
          let obj = JSObject::new(prototype=big_proto)
          obj.properties.set("PrimitiveValue", val)
          Object(obj)
        }
        _ => val
      }
    } else {
      Object(JSObject::new(properties=@hashmap.new(), prototype=proto))
    }
  })
  let object_fn = JSFunction::new(
    name="Object",
    params=["value"],
    body=object_fn_body,
    prototype=func_proto,
    is_constructor=true,
  )
  object_fn["prototype"] = proto
  object_fn.properties.set("length", JSValue::Number(1.0))

  // Object.keys
  let keys_fn = Native(fn(ctx, _this_val, args) {
    if args is [obj_arg, ..] {
      let obj_props = match obj_arg {
        Object({ properties, .. }) | Function({ properties, .. }) => properties
        _ => return JSValue::Undefined // TypeError
      }
      let array_proto = match ctx.resolve("Array") {
        Function(f) => f.get("prototype")
        _ => proto
      }
      let keys_array = JSObject::new(
        properties=@hashmap.new(),
        prototype=array_proto,
      )
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
        for idx = 0; idx < len; idx = idx + 1 {
          keys_array[i.to_string()] = JSValue::String(idx.to_string())
          i = i + 1.0
        }
      }
      for k, _ in obj_props {
        if not(k.has_prefix("Symbol(")) &&
          not(k.has_prefix("__")) &&
          k != "PrimitiveValue" &&
          k != "length" {
          keys_array[i.to_string()] = JSValue::String(k)
          i = i + 1.0
        }
      }
      keys_array["length"] = JSValue::Number(i)
      JSValue::Object(keys_array)
    } else {
      JSValue::Undefined
    }
  })
  let keys_obj = JSFunction::new(
    name="keys",
    body=keys_fn,
    prototype=func_proto,
  )
  object_fn["keys"] = JSValue::Function(keys_obj)

  // Object.create
  let create_fn = Native(fn(_ctx, _this_val, args) {
    if args is [proto_arg, ..] {
      match proto_arg {
        Object(_) | Null =>
          JSValue::Object(
            JSObject::new(properties=@hashmap.new(), prototype=proto_arg),
          )
        _ => JSValue::Undefined // TypeError
      }
    } else {
      JSValue::Undefined // TypeError
    }
  })
  let create_obj = JSFunction::new(
    name="create",
    body=create_fn,
    prototype=func_proto,
  )
  object_fn["create"] = JSValue::Function(create_obj)

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
        Function(f) => {
          let res = ctx.invoke(f, handler, [target, prop_arg, desc_arg]) catch {
            e => raise e
          }
          if not(res.is_truthy()) {
            // TypeError
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
      let prop = prop_arg.to_string()
      if desc_props.contains("get") || desc_props.contains("set") {
        let getter = match desc_props.get("get") {
          Some(Function(f)) => Some(f)
          _ => None
        }
        let setter = match desc_props.get("set") {
          Some(Function(f)) => Some(f)
          _ => None
        }
        properties[prop] = Internal(Accessor(getter, setter))
      } else if desc_props.get("value") is Some(val) {
        properties[prop] = val
        // Default to undefined value if nothing specified
      } else if not(properties.contains(prop)) {
        properties[prop] = Undefined
      }
      // Ignore other descriptor properties like writable, enumerable, configurable for now
      Object(o)
    } else {
      JSValue::Undefined // TypeError
    }
  })
  let define_property_obj = JSFunction::new(
    name="defineProperty",
    body=define_property_fn,
    prototype=func_proto,
  )
  object_fn["defineProperty"] = JSValue::Function(define_property_obj)

  // Object.freeze
  let freeze_fn = Native(fn(_ctx, _this_val, args) {
    if args is [obj_arg, ..] {
      match obj_arg {
        Object(o) => {
          o.extensible = false
          o.is_sealed = true
          o.is_frozen = true
          obj_arg
        }
        Function(f) => {
          f.extensible = false
          f.is_sealed = true
          f.is_frozen = true
          obj_arg
        }
        _ => obj_arg
      }
    } else {
      JSValue::Undefined
    }
  })
  let freeze_obj = JSFunction::new(
    name="freeze",
    body=freeze_fn,
    prototype=func_proto,
  )
  object_fn["freeze"] = JSValue::Function(freeze_obj)

  // Object.isFrozen
  let is_frozen_fn = Native(fn(_ctx, _this_val, args) {
    if args is [obj_arg, ..] {
      match obj_arg {
        Object(o) => JSValue::Boolean(o.is_frozen)
        Function(f) => JSValue::Boolean(f.is_frozen)
        _ => JSValue::Boolean(true) // Primitives are always frozen in ES6+
      }
    } else {
      JSValue::Boolean(true)
    }
  })
  let is_frozen_obj = JSFunction::new(
    name="isFrozen",
    body=is_frozen_fn,
    prototype=func_proto,
  )
  object_fn["isFrozen"] = JSValue::Function(is_frozen_obj)

  // Object.seal
  let seal_fn = Native(fn(_ctx, _this_val, args) {
    if args is [obj_arg, ..] {
      match obj_arg {
        Object(o) => {
          o.extensible = false
          o.is_sealed = true
          obj_arg
        }
        Function(f) => {
          f.extensible = false
          f.is_sealed = true
          obj_arg
        }
        _ => obj_arg
      }
    } else {
      JSValue::Undefined
    }
  })
  let seal_obj = JSFunction::new(
    name="seal",
    body=seal_fn,
    prototype=func_proto,
  )
  object_fn["seal"] = JSValue::Function(seal_obj)

  // Object.isSealed
  let is_sealed_fn = Native(fn(_ctx, _this_val, args) {
    if args is [obj_arg, ..] {
      match obj_arg {
        Object(o) => JSValue::Boolean(o.is_sealed)
        Function(f) => JSValue::Boolean(f.is_sealed)
        _ => JSValue::Boolean(true)
      }
    } else {
      JSValue::Boolean(true)
    }
  })
  let is_sealed_obj = JSFunction::new(
    name="isSealed",
    body=is_sealed_fn,
    prototype=func_proto,
  )
  object_fn["isSealed"] = JSValue::Function(is_sealed_obj)

  // Object.preventExtensions
  let prevent_extensions_fn = Native(fn(ctx, _this_val, args) {
    if args
      is [
        Object({ proxy_target: Some(target), proxy_handler: Some(handler), .. }) as proxy,
        ..,
      ] {
      let trap = handler.get_property("preventExtensions")
      match trap {
        Function(f) => {
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
        Function(f) => {
          f.extensible = false
          obj_arg
        }
        _ => obj_arg
      }
    } else {
      JSValue::Undefined
    }
  })
  let prevent_extensions_obj = JSFunction::new(
    name="preventExtensions",
    body=prevent_extensions_fn,
    prototype=func_proto,
  )
  object_fn["preventExtensions"] = JSValue::Function(prevent_extensions_obj)

  // Object.isExtensible
  let is_extensible_fn = Native(fn(_ctx, _this_val, args) {
    if args is [obj_arg, ..] {
      match obj_arg {
        Object(o) => JSValue::Boolean(o.extensible)
        Function(f) => JSValue::Boolean(f.extensible)
        _ => JSValue::Boolean(false)
      }
    } else {
      JSValue::Boolean(false)
    }
  })
  let is_extensible_obj = JSFunction::new(
    name="isExtensible",
    body=is_extensible_fn,
    prototype=func_proto,
  )
  object_fn["isExtensible"] = JSValue::Function(is_extensible_obj)

  // Object.getOwnPropertySymbols
  let get_own_property_symbols_fn = Native(fn(ctx, _this_val, args) {
    if args is [obj_arg, ..] {
      // Proxy trap
      match obj_arg {
        Object({ proxy_target: Some(target), proxy_handler: Some(handler), .. })
        | Function(
          { proxy_target: Some(target), proxy_handler: Some(handler), .. }
        ) => {
          let trap = handler.get_property("ownKeys")
          match trap {
            Function(f) => {
              let keys_list = ctx.invoke(f, handler, [target]) catch {
                e => raise e
              }
              let array_proto = match ctx.resolve("Array") {
                Function(f) => f.get("prototype")
                _ => proto
              }
              let symbols_array = JSObject::new(
                properties=@hashmap.new(),
                prototype=array_proto,
              )
              let mut i = 0.0
              match keys_list {
                Object({ properties: keys_props, .. }) => {
                  let len = match keys_props.get("length") {
                    Some(Number(n)) => n.to_int()
                    _ => 0
                  }
                  for j = 0; j < len; j = j + 1 {
                    let k = match keys_props.get(j.to_string()) {
                      Some(v) => v
                      None => Undefined
                    }
                    match k {
                      Symbol(id, desc) => {
                        symbols_array[i.to_string()] = k
                        i = i + 1.0
                      }
                      _ => ()
                    }
                  }
                }
                _ => ()
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
        Object({ properties, .. }) | Function({ properties, .. }) => properties
        _ => {
          if obj_arg == JSValue::Null || obj_arg == JSValue::Undefined {
            ctx.throw_type_error("Cannot convert undefined or null to object")
          }
          // For primitives, return []
          let array_proto = match ctx.resolve("Array") {
            Function(f) => f.get("prototype")
            _ => proto
          }
          let empty_array = JSObject::new(
            properties=@hashmap.new(),
            prototype=array_proto,
          )
          empty_array["length"] = JSValue::Number(0.0)
          return JSValue::Object(empty_array)
        }
      }
      let array_proto = match ctx.resolve("Array") {
        Function(f) => f.get("prototype")
        _ => proto
      }
      let symbols_array = JSObject::new(
        properties=@hashmap.new(),
        prototype=array_proto,
      )
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
  let get_own_property_symbols_obj = JSFunction::new(
    name="getOwnPropertySymbols",
    body=get_own_property_symbols_fn,
    prototype=func_proto,
  )
  object_fn["getOwnPropertySymbols"] = JSValue::Function(
    get_own_property_symbols_obj,
  )

  // Object.getOwnPropertyDescriptor
  let get_own_property_descriptor_fn = Native(fn(ctx, _this_val, args) {
    if args is [obj_arg, prop_arg, ..] {
      // Proxy trap
      match obj_arg {
        Object({ proxy_target: Some(target), proxy_handler: Some(handler), .. })
        | Function(
          { proxy_target: Some(target), proxy_handler: Some(handler), .. }
        ) => {
          let trap = handler.get_property("getOwnPropertyDescriptor")
          match trap {
            Function(f) => {
              let trap_res = ctx.invoke(f, handler, [target, prop_arg]) catch {
                e => raise e
              }
              return trap_res
            }
            _ => ()
          }
        }
        _ => ()
      }

      // Check if obj_arg is global object
      let mut root_ctx = ctx
      while true {
        match root_ctx.parent {
          Some(p) => root_ctx = p
          None => break
        }
      }
      let is_global = match root_ctx.scope.get("globalThis") {
        Some(g) => g.strict_equal(obj_arg)
        None => false
      }
      let (
        obj_props,
        is_func,
        is_native_func,
        is_string_obj,
        is_global,
        is_frozen,
        is_sealed,
      ) = match obj_arg {
        Object(o) => {
          let properties = o.properties
          let is_frozen = o.is_frozen
          let is_sealed = o.is_sealed
          let is_str = match properties.get("PrimitiveValue") {
            Some(String(_)) => true
            _ => false
          }
          (properties, false, false, is_str, is_global, is_frozen, is_sealed)
        }
        Function(f) => {
          let properties = f.properties
          let is_frozen = f.is_frozen
          let is_sealed = f.is_sealed
          let is_native = match f.body {
            Native(_) => true
            _ => false
          }
          (properties, true, is_native, false, false, is_frozen, is_sealed)
        }
        _ => {
          if obj_arg == JSValue::Null || obj_arg == JSValue::Undefined {
            ctx.throw_type_error("Cannot convert undefined or null to object")
          }
          return JSValue::Undefined
        }
      }
      let prop = match prop_arg {
        _ => prop_arg.to_string()
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
        let len = match obj_props.get("length") {
          Some(Number(n)) => n.to_int()
          _ => 0
        }
        let idx = @strconv.parse_int(prop) catch { _ => -1 }
        if idx >= 0 && idx < len {
          let str_val = match obj_props.get("PrimitiveValue") {
            Some(String(s)) => s
            _ => ""
          }
          let char_code = str_val[idx].to_int()
          let c = match char_code.to_char() {
            Some(c) => c
            None => ' '
          }
          let char_str = String::make(1, c)
          let desc = JSObject::new(properties=@hashmap.new(), prototype=proto)
          desc["value"] = JSValue::String(char_str)
          desc["writable"] = JSValue::Boolean(false)
          desc["enumerable"] = JSValue::Boolean(true)
          desc["configurable"] = JSValue::Boolean(false)
          return JSValue::Object(desc)
        }
      }
      match obj_props.get(prop) {
        Some(val) => {
          let desc = JSObject::new(properties=@hashmap.new(), prototype=proto)
          // println("DEBUG: getOwnPropertyDescriptor prop=" + prop)
          match val {
            Internal(Accessor(getter, setter)) => {
              desc["get"] = getter
                .map(JSValue::Function(_))
                .unwrap_or(Undefined)
              desc["set"] = setter
                .map(JSValue::Function(_))
                .unwrap_or(Undefined)
              desc["enumerable"] = JSValue::Boolean(true)
              desc["configurable"] = JSValue::Boolean(not(is_sealed))
            }
            _ => {
              let is_symbol_to_string_tag = prop.contains("toStringTag")
              if is_symbol_to_string_tag {
                let d_props = @hashmap.new()
                d_props.set("writable", JSValue::Boolean(false))
                d_props.set("enumerable", JSValue::Boolean(false))
                d_props.set("configurable", JSValue::Boolean(true))
                d_props.set("value", val)
                return JSValue::Object(
                  JSObject::new(properties=d_props, prototype=proto),
                )
              }
              let is_symbol_iterator = prop.contains("iterator")
              if is_symbol_iterator {
                let d_props = @hashmap.new()
                d_props.set("writable", JSValue::Boolean(true))
                d_props.set("enumerable", JSValue::Boolean(false))
                d_props.set("configurable", JSValue::Boolean(true))
                d_props.set("value", val)
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
              if is_string_obj && prop == "length" {
                desc["writable"] = JSValue::Boolean(false)
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
                  | "Symbol") {
                  desc["enumerable"] = JSValue::Boolean(false)
                }
              }

              // Map.prototype methods (heuristic)
              if prop
                is ("get"
                | "set"
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
                // Check if it's on Map.prototype or a Map instance
                let is_map_related = obj_props.contains("MapData") ||
                  obj_props.get("Symbol(Symbol.toStringTag)") ==
                  Some(JSValue::String("Map"))
                if is_map_related {
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
  let get_own_property_descriptor_obj = JSFunction::new(
    name="getOwnPropertyDescriptor",
    body=get_own_property_descriptor_fn,
    prototype=func_proto,
  )
  object_fn["getOwnPropertyDescriptor"] = JSValue::Function(
    get_own_property_descriptor_obj,
  )

  // Object.getPrototypeOf
  let get_prototype_of_fn = Native(fn(_ctx, _this_val, args) {
    if args is [obj_arg, ..] {
      match obj_arg {
        Object({ prototype, .. }) | Function({ prototype, .. }) =>
          match prototype {
            Some(p) => p
            None => Null
          }
        _ => JSValue::Undefined // Should throw TypeError for non-object
      }
    } else {
      JSValue::Undefined // TypeError
    }
  })
  let get_prototype_of_obj = JSFunction::new(
    name="getPrototypeOf",
    body=get_prototype_of_fn,
    prototype=func_proto,
  )
  object_fn["getPrototypeOf"] = JSValue::Function(get_prototype_of_obj)

  // Object.getOwnPropertyNames
  let get_own_property_names_fn = Native(fn(ctx, _this_val, args) {
    if args is [obj_arg, ..] {
      // Proxy trap
      match obj_arg {
        Object({ proxy_target: Some(target), proxy_handler: Some(handler), .. })
        | Function(
          { proxy_target: Some(target), proxy_handler: Some(handler), .. }
        ) => {
          let trap = handler.get_property("ownKeys")
          match trap {
            Function(f) => {
              let keys_list = ctx.invoke(f, handler, [target]) catch {
                e => raise e
              }
              // Convert keys_list (array-like) to Array of names
              let array_proto = match ctx.resolve("Array") {
                Function(f) => f.get("prototype")
                _ => proto
              }
              let names_array = JSObject::new(
                properties=@hashmap.new(),
                prototype=array_proto,
              )
              let mut i = 0.0
              match keys_list {
                Object({ properties: keys_props, .. }) => {
                  let len = match keys_props.get("length") {
                    Some(Number(n)) => n.to_int()
                    _ => 0
                  }
                  for j = 0; j < len; j = j + 1 {
                    let k = match keys_props.get(j.to_string()) {
                      Some(v) => v.to_string()
                      None => ""
                    }
                    if not(k.has_prefix("Symbol(")) {
                      names_array[i.to_string()] = JSValue::String(k)
                      i = i + 1.0
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
      let obj_props = match obj_arg {
        Object({ properties, .. }) | Function({ properties, .. }) => properties
        _ => {
          if obj_arg == JSValue::Null || obj_arg == JSValue::Undefined {
            ctx.throw_type_error("Cannot convert undefined or null to object")
          }
          // For primitives, return their keys (e.g. string indices)
          let array_proto = match ctx.resolve("Array") {
            Function(f) => f.get("prototype")
            _ => proto
          }
          let names_array = JSObject::new(
            properties=@hashmap.new(),
            prototype=array_proto,
          )
          let mut i = 0.0
          match obj_arg {
            String(s) => {
              let len = s.length()
              for idx = 0; idx < len; idx = idx + 1 {
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
        Function(f) => f.get("prototype")
        _ => proto
      }
      let names_array = JSObject::new(
        properties=@hashmap.new(),
        prototype=array_proto,
      )
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
        for idx = 0; idx < len; idx = idx + 1 {
          names_array[i.to_string()] = JSValue::String(idx.to_string())
          i = i + 1.0
        }
      }
      for k, _ in obj_props {
        if not(k.has_prefix("Symbol(")) &&
          not(k.has_prefix("__")) &&
          k != "PrimitiveValue" {
          names_array[i.to_string()] = JSValue::String(k)
          i = i + 1.0
        }
      }
      names_array["length"] = JSValue::Number(i)
      JSValue::Object(names_array)
    } else {
      raise EvalError::Throw(
        JSValue::String("TypeError: Cannot convert undefined or null to object"),
      )
    }
  })
  let get_own_property_names_obj = JSFunction::new(
    name="getOwnPropertyNames",
    body=get_own_property_names_fn,
    prototype=func_proto,
  )
  object_fn["getOwnPropertyNames"] = JSValue::Function(
    get_own_property_names_obj,
  )
  JSValue::Function(object_fn)
}

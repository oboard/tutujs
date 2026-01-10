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
              if properties.contains("PrimitiveValue") {
                match properties.get("PrimitiveValue") {
                  Some(String(_)) => "[object String]"
                  Some(Number(_)) => "[object Number]"
                  Some(Boolean(_)) => "[object Boolean]"
                  _ => "[object Object]"
                }
              } else {
                "[object Object]"
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

      // hasOwnProperty
      let has_own_property_fn = Native(fn(_ctx, this_val, args) {
        if args is [prop, ..] {
          let key = prop.to_string()
          match this_val {
            Object({ properties, .. }) => Boolean(properties.contains(key))
            Function({ properties, .. }) => Boolean(properties.contains(key))
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
                      Object(po) => proto = po.prototype
                      Function(pf) => proto = pf.prototype
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
                      Object(po) => proto = po.prototype
                      Function(pf) => proto = pf.prototype
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
      let property_is_enumerable_fn = Native(fn(_ctx, this_val, args) {
        if args is [prop, ..] {
          let key = prop.to_string()
          match this_val {
            Object({ properties, .. }) | Function({ properties, .. }) => {
              // Hack: hide prototype, length, name, arguments, caller
              if key == "prototype" || key == "length" || key == "name" || key == "arguments" || key == "caller" {
                Boolean(false)
              } else {
                Boolean(properties.contains(key) && not(key.starts_with("__")))
              }
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
  let object_fn_body = Native(fn(_ctx, _this_val, args) {
    if args is [val, ..] {
      match val {
        Object(_) => val
        Null | Undefined => Object({ properties: {}, prototype: Some(proto) })
        _ => val // TODO: Box primitive
      }
    } else {
      Object({ properties: {}, prototype: Some(proto) })
    }
  })
  let object_fn = JSFunction::new(
    name="Object",
    body=object_fn_body,
    prototype=func_proto,
  )
  object_fn["prototype"] = proto

  // Object.keys
  let keys_fn = Native(fn(_ctx, _this_val, args) {
    if args is [Object({ properties, .. }), ..] {
      let keys_array = JSObject::{ properties: {}, prototype: Some(proto) } // Should be Array.prototype ideally
      let mut i = 0.0
      for k, _ in properties {
        keys_array[i.to_string()] = JSValue::String(k)
        i = i + 1.0
      }
      keys_array["length"] = JSValue::Number(i)
      JSValue::Object(keys_array)
    } else {
      JSValue::Undefined // TypeError
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
          JSValue::Object({ properties: {}, prototype: Some(proto_arg) })
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
  let define_property_fn = Native(fn(_ctx, _this_val, args) {
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

  // Object.freeze (Stub)
  let freeze_fn = Native(fn(_ctx, _this_val, args) {
    if args is [obj, ..] {
      obj
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

  // Object.preventExtensions
  let prevent_extensions_fn = Native(fn(_ctx, _this_val, args) {
    if args is [Object({ properties, .. } as o), ..] {
      // println("DEBUG: preventExtensions called")
      properties["__internal_extensible__"] = JSValue::Boolean(false)
      JSValue::Object(o)
    } else if args is [val, ..] {
      val
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
  JSValue::Function(object_fn)
}

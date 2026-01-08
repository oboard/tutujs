///|
pub fn init_object_prototype(object_proto_val : JSValue) -> Unit {
  match object_proto_val {
    Object(obj) => {
      // toString
      let to_string_fn = Native(fn(_ctx, this_val, _args) {
        JSValue::String(
          match this_val {
            Object(_) => "[object Object]"
            Function(_) => "[object Function]" // Functions are objects too but usually have specific tag
            String(_) => "[object String]" // Boxed string? No, primitive string. 
            // Primitive values don't have methods unless boxed. 
            // But if I call "str".toString(), it boxes it.
            // In my eval, MemberExpression on primitive boxes it? 
            // Currently I don't support boxing primitives on property access in eval.
            // So this_val will be Object if it's a method call on object.
            _ => "[object Object]"
          },
        )
      })
      let to_string_obj = JSFunction::new(name="toString", body=to_string_fn)
      obj["toString"] = JSValue::Function(to_string_obj)

      // valueOf
      let value_of_fn = Native(fn(_ctx, this_val, _args) { this_val })
      let value_of_obj = JSFunction::new(name="valueOf", body=value_of_fn)
      obj["valueOf"] = JSValue::Function(value_of_obj)

      // hasOwnProperty
      let has_own_property_fn = Native(fn(_ctx, this_val, args) {
        if args.length() > 0 {
          let key = args[0].to_string()
          match this_val {
            Object(o) => Boolean(o.properties.contains(key))
            Function(f) => Boolean(f.properties.contains(key))
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
      )
      obj["hasOwnProperty"] = JSValue::Function(has_own_property_obj)
    }
    _ => ()
  }
}

pub fn create_object_constructor(proto : JSValue, func_proto : JSValue) -> JSValue {
  let object_fn_body = Native(fn(_ctx, _this_val, args) {
    if args.length() > 0 {
      let val = args[0]
      match val {
        Object(_) => val
        Null | Undefined =>
          Object({
            properties: @hashmap.new(),
            prototype: Some(proto),
          })
        _ => val // TODO: Box primitive
      }
    } else {
      Object({ properties: @hashmap.new(), prototype: Some(proto) })
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
    if args.length() > 0 {
      match args[0] {
        Object(o) => {
          let keys_array = JSObject::{
            properties: @hashmap.new(),
            prototype: Some(proto), // Should be Array.prototype ideally
          }
          let mut i = 0.0
          for k, _ in o.properties {
            keys_array[i.to_string()] = JSValue::String(k)
            i = i + 1.0
          }
          keys_array["length"] = JSValue::Number(i)
          JSValue::Object(keys_array)
        }
        _ => JSValue::Undefined // TypeError in ES5+
      }
    } else {
      JSValue::Undefined // TypeError
    }
  })
  let keys_obj = JSFunction::new(name="keys", body=keys_fn)
  object_fn["keys"] = JSValue::Function(keys_obj)

  // Object.create
  let create_fn = Native(fn(_ctx, _this_val, args) {
    if args.length() > 0 {
      let proto_arg = args[0]
      match proto_arg {
        Object(_) | Null =>
          JSValue::Object({
            properties: @hashmap.new(),
            prototype: Some(proto_arg),
          })
        _ => JSValue::Undefined // TypeError
      }
    } else {
      JSValue::Undefined // TypeError
    }
  })
  let create_obj = JSFunction::new(name="create", body=create_fn)
  object_fn["create"] = JSValue::Function(create_obj)

  // Object.defineProperty (Simplified but handles accessors)
  let define_property_fn = Native(fn(_ctx, _this_val, args) {
    if args.length() >= 3 {
      let obj = args[0]
      let prop = args[1].to_string()
      let descriptor = args[2]
      match (obj, descriptor) {
        (Object(o), Object(desc)) => {
          if desc.properties.contains("get") || desc.properties.contains("set") {
             let getter = match desc["get"] {
               Function(f) => Some(f)
               _ => None
             }
             let setter = match desc["set"] {
               Function(f) => Some(f)
               _ => None
             }
             o[prop] = Internal(Accessor(getter, setter))
          } else if desc.properties.contains("value") {
            o[prop] = desc["value"]
          } else {
            // Default to undefined value if nothing specified
             if not(o.properties.contains(prop)) {
                o[prop] = Undefined
             }
          }
          // Ignore other descriptor properties like writable, enumerable, configurable for now
          obj
        }
        _ => JSValue::Undefined // TypeError
      }
    } else {
      JSValue::Undefined // TypeError
    }
  })
  let define_property_obj = JSFunction::new(name="defineProperty", body=define_property_fn)
  object_fn["defineProperty"] = JSValue::Function(define_property_obj)

  // Object.freeze (Stub)
  let freeze_fn = Native(fn(_ctx, _this_val, args) {
    if args.length() > 0 {
      args[0]
    } else {
      JSValue::Undefined
    }
  })
  let freeze_obj = JSFunction::new(name="freeze", body=freeze_fn)
  object_fn["freeze"] = JSValue::Function(freeze_obj)

  JSValue::Function(object_fn)
}

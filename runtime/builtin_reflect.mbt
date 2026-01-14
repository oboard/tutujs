///|
pub fn create_reflect_object(object_proto : JSValue) -> JSValue {
  let reflect_obj = JSObject::new(
    properties=@hashmap.new(),
    prototype=object_proto,
  )

  // Reflect.construct(target, argumentsList[, newTarget])
  let construct_fn = Native(fn(ctx, _this_val, args) {
    if args.length() < 2 {
      ctx.throw_type_error("Reflect.construct requires at least 2 arguments")
      return JSValue::Undefined
    }
    let target = args[0]
    let args_list = args[1]
    let _new_target = if args.length() > 2 { args[2] } else { target }
    let func = match target {
      Function(f) =>
        if f.is_constructor {
          f
        } else {
          ctx.throw_type_error(
            "Reflect.construct: target must be a constructor",
          )
          return JSValue::Undefined
        }
      _ => {
        ctx.throw_type_error("Reflect.construct: target must be a constructor")
        return JSValue::Undefined
      }
    }
    let nt_val = _new_target
    let _nt = match nt_val {
      Function(f) =>
        if f.is_constructor {
          f
        } else {
          ctx.throw_type_error(
            "Reflect.construct: newTarget must be a constructor",
          )
          return JSValue::Undefined
        }
      _ => {
        ctx.throw_type_error(
          "Reflect.construct: newTarget must be a constructor",
        )
        return JSValue::Undefined
      }
    }
    let args_array = match args_list {
      Object({ properties, .. }) => {
        let len = match properties.get("length") {
          Some(Number(n)) => n.to_int()
          _ => 0
        }
        let arr = []
        for i = 0; i < len; i = i + 1 {
          match properties.get(i.to_string()) {
            Some(v) => arr.push(v)
            None => arr.push(Undefined)
          }
        }
        arr
      }
      _ => {
        ctx.throw_type_error(
          "Reflect.construct: argumentsList must be an object",
        )
        return JSValue::Undefined
      }
    }
    let proto_val = nt_val.get_property("prototype")
    let proto = match proto_val {
      Object(_) as p => p
      _ =>
        match JSValue::Function(func).get_property("prototype") {
          Object(_) as p => p
          _ =>
            match ctx.resolve("Object") {
              Function(obj_ctor) => obj_ctor.get("prototype")
              _ => Null
            }
        }
    }
    let new_obj = JSValue::Object(
      JSObject::new(properties=@hashmap.new(), prototype=proto),
    )
    let res = ctx.invoke(func, new_obj, args_array) catch {
      EvalError::Return(v) => v
      e => raise e
    }
    match res {
      Object(_) | Function(_) => res
      _ => new_obj
    }
  })
  let construct_obj = JSFunction::new(name="construct", body=construct_fn)
  reflect_obj["construct"] = JSValue::Function(construct_obj)

  // Reflect.defineProperty(target, propertyKey, attributes)
  let define_property_fn = Native(fn(ctx, _this_val, args) {
    match (args, ctx.resolve("Object")) {
      (
        [_, _, _, ..],
        Function(
          {
            base: { properties: { "defineProperty": Function(f), .. }, .. },
            ..,
          }
        ),
      ) => {
        let _ = ctx.invoke(f, Undefined, args) catch {
          _ => return JSValue::Boolean(false)
        }
        JSValue::Boolean(true)
      }
      _ => JSValue::Boolean(false)
    }
  })
  reflect_obj["defineProperty"] = JSValue::Function(
    JSFunction::new(name="defineProperty", body=define_property_fn),
  )

  // Reflect.preventExtensions(target)
  let prevent_extensions_fn = Native(fn(ctx, _this_val, args) {
    if args is [target, ..] {
      match ctx.resolve("Object") {
        Function(obj_ctor) =>
          match obj_ctor.get("preventExtensions") {
            Function(f) => {
              let _ = ctx.invoke(f, Undefined, [target]) catch {
                _ => return JSValue::Boolean(false)
              }
              JSValue::Boolean(true)
            }
            _ => JSValue::Boolean(false)
          }
        _ => JSValue::Boolean(false)
      }
    } else {
      JSValue::Boolean(false)
    }
  })
  reflect_obj["preventExtensions"] = JSValue::Function(
    JSFunction::new(name="preventExtensions", body=prevent_extensions_fn),
  )

  // Reflect.isExtensible(target)
  let is_extensible_fn = Native(fn(ctx, _this_val, args) {
    if args is [target, ..] {
      match ctx.resolve("Object") {
        Function(obj_ctor) =>
          match obj_ctor.get("isExtensible") {
            Function(f) => {
              let res = ctx.invoke(f, Undefined, [target]) catch {
                _ => return JSValue::Boolean(false)
              }
              res
            }
            _ => JSValue::Boolean(false)
          }
        _ => JSValue::Boolean(false)
      }
    } else {
      JSValue::Boolean(false)
    }
  })
  reflect_obj["isExtensible"] = JSValue::Function(
    JSFunction::new(name="isExtensible", body=is_extensible_fn),
  )
  JSValue::Object(reflect_obj)
}

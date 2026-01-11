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
      return JSValue::Undefined // unreachable
    }
    let target = args[0]
    let args_list = args[1]
    let _new_target = if args.length() > 2 { args[2] } else { target }
    match target {
      Function(func) =>
        if not(func.is_constructor) {
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
    match _new_target {
      Function(func) =>
        if not(func.is_constructor) {
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
        // Convert array-like to array of values
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

    // Invoke constructor
    // We reuse logic from NewExpression in eval.mbt if possible, but here we need to invoke directly.
    // We can use ctx.invoke, but we need to pass 'this' as a new object?
    // Wait, invoke handles function call. NewExpression logic handles creating new object and passing it as 'this'.
    // We need 'construct' capability on JSFunction.

    // For now, let's duplicate the logic or extract it.
    // Ideally Context should have a 'construct' method.

    match target {
      Function(func) => {
        let proto = match _new_target {
          Function(f) =>
            match f.properties.get("prototype") {
              Some(Object(_) as p) => Some(p)
              _ =>
                // Fallback to target's prototype (intrinsicDefaultProto)
                match func.properties.get("prototype") {
                  Some(p) => Some(p)
                  None => Some(Null)
                }
            }
          _ => Some(Null)
        }
        let new_obj = match proto {
          Some(p) =>
            JSValue::Object(
              JSObject::new(properties=@hashmap.new(), prototype=p),
            )
          None => JSValue::Object(JSObject::new(properties=@hashmap.new()))
        }
        let res = ctx.invoke(func, new_obj, args_array) catch {
          EvalError::Return(v) => v // Constructors can return object to override 'this'
          e => raise e
        }
        match res {
          Object(_) | Function(_) => res
          _ => new_obj
        }
      }
      _ => Undefined
    }
  })
  let construct_obj = JSFunction::new(name="construct", body=construct_fn)
  reflect_obj.properties["construct"] = JSValue::Function(construct_obj)

  // Reflect.defineProperty(target, propertyKey, attributes)
  let define_property_fn = Native(fn(ctx, _this_val, args) {
    if args is [target, prop, desc, ..] {
      match ctx.resolve("Object") {
        Function(obj_ctor) =>
          match obj_ctor.get("defineProperty") {
            Function(f) => {
              let _ = ctx.invoke(f, Undefined, [target, prop, desc]) catch {
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
  reflect_obj.properties["defineProperty"] = JSValue::Function(
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
  reflect_obj.properties["preventExtensions"] = JSValue::Function(
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
  reflect_obj.properties["isExtensible"] = JSValue::Function(
    JSFunction::new(name="isExtensible", body=is_extensible_fn),
  )
  JSValue::Object(reflect_obj)
}

///|
pub fn create_set_constructor(
  set_proto : JSValue,
  func_proto : JSValue,
) -> JSValue {
  let ctor_fn = Native(fn(ctx, this_val, args) {
    match this_val {
      Object(obj) => {
        let set_data = LinkedMap::new()
        obj["SetData"] = JSValue::Internal(Set(set_data))
        if args.length() > 0 && not(args[0] is (Undefined | Null)) {
          let iterable = args[0]
          let adder_val = this_val.get_property("add")
          let adder = match adder_val {
            Object(f) =>
              if f.is_callable {
                f
              } else {
                ctx.throw_type_error("Set.prototype.add is not a function")
                abort("Unreachable")
              }
            _ => {
              ctx.throw_type_error("Set.prototype.add is not a function")
              abort("Unreachable")
            }
          }

          // General Iterator Protocol
          let iterator_sym = match ctx.resolve("Symbol") {
            Object(f) =>
              f.properties.get("iterator").unwrap_or(JSValue::Undefined)
            _ => JSValue::Undefined
          }
          let iterator_key = match iterator_sym {
            Symbol(_) => iterator_sym.to_property_key()
            _ => "Symbol.iterator"
          }
          let iterator_method_val = iterable.get_property(iterator_key)
          let iterator_method = match iterator_method_val {
            Object(f) =>
              if f.is_callable {
                iterator_method_val
              } else {
                iterable.get_property("Symbol.iterator")
              }
            _ => iterable.get_property("Symbol.iterator")
          }
          match iterator_method {
            Object(iter_fn) =>
              if iter_fn.is_callable {
                let iterator = match ctx.invoke(iter_fn, iterable, []) {
                  Object(obj) => JSValue::Object(obj)
                  _ => {
                    ctx.throw_type_error("Iterator is not an object")
                    return Undefined
                  }
                }
                let next_method = match iterator.get_property("next") {
                  Object(f) =>
                    if f.is_callable {
                      f
                    } else {
                      ctx.throw_type_error("iterator.next is not a function")
                      return Undefined
                    }
                  _ => {
                    ctx.throw_type_error("iterator.next is not a function")
                    return Undefined
                  }
                }
                while true {
                  let next_res = ctx.invoke(next_method, iterator, []) catch {
                    e => raise e
                  }
                  match next_res {
                    Object(res_obj) => {
                      let done = JSValue::Object(res_obj)
                        .get_property("done")
                        .is_truthy()
                      if done {
                        break
                      }
                      let value = JSValue::Object(res_obj).get_property("value")
                      try ctx.invoke(adder, this_val, [value]) |> ignore catch {
                        e => {
                          iterator_close(ctx, iterator)
                          raise e
                        }
                      }
                    }
                    _ => {
                      iterator_close(ctx, iterator)
                      ctx.throw_type_error("Iterator result is not an object")
                    }
                  }
                }
              } else {
                ctx.throw_type_error("Object is not iterable")
              }
            _ =>
              // Not iterable
              ctx.throw_type_error("Object is not iterable")
          }
          () |> ignore
        }
        this_val
      }
      _ => {
        ctx.throw_type_error("Set constructor called on non-object")
        Undefined
      }
    }
  })
  JSValue::Object(
    JSObject::new_function(
      name="Set",
      params=[], // length 0
      body=ctor_fn,
      prototype=func_proto,
      is_constructor=true,
      properties={ "prototype": set_proto },
    ),
  )
}

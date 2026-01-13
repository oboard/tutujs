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
          let adder_val = this_val.get_property_throw("add") catch {
            e => raise e
          }
          let adder = match adder_val {
            Function(f) => f
            _ => {
              ctx.throw_type_error("Set.prototype.add is not a function")
              abort("Unreachable")
            }
          }

          // General Iterator Protocol
          let iterator_sym = match ctx.resolve("Symbol") {
            Function(f) =>
              f.base.properties.get("iterator").unwrap_or(JSValue::Undefined)
            _ => JSValue::Undefined
          }
          let iterator_key = match iterator_sym {
            Symbol(_) => iterator_sym.to_property_key()
            _ => "Symbol.iterator"
          }
          let iterator_method_val = iterable.get_property(iterator_key)
          let iterator_method = match iterator_method_val {
            Function(_) => iterator_method_val
            _ => iterable.get_property("Symbol.iterator")
          }
          match iterator_method {
            Function(iter_fn) => {
              let iterator = match ctx.invoke(iter_fn, iterable, []) {
                Object(_) | Function(_) as obj => obj
                _ => {
                  ctx.throw_type_error("Iterator is not an object")
                  return Undefined
                }
              }
              let next_method = match iterator.get_property("next") {
                Function(f) => f
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
                  Object(_) | Function(_) as res_obj => {
                    let done = res_obj.get_property_throw("done").is_truthy() catch {
                        e => {
                          iterator_close(ctx, iterator)
                          raise e
                        }
                      }
                    if done {
                      break
                    }
                    let value = res_obj.get_property_throw("value") catch {
                      e => {
                        iterator_close(ctx, iterator)
                        raise e
                      }
                    }
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
  let ctor_obj = JSFunction::new(
    name="Set",
    params=[], // length 0
    body=ctor_fn,
    prototype=func_proto,
    is_constructor=true,
  )
  ctor_obj.base["prototype"] = set_proto
  JSValue::Function(ctor_obj)
}

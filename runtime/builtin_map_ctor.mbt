///|
pub fn create_map_constructor(
  map_proto : JSValue,
  func_proto : JSValue,
) -> JSValue {
  let ctor_fn = Native(fn(ctx, this_val, args) {
    match this_val {
      Object(obj) => {
        let map_data = LinkedMap::new()
        obj["MapData"] = JSValue::Internal(Map(map_data))
        if args.length() > 0 && not(args[0] is (Undefined | Null)) {
          let iterable = args[0]
          let adder_val = this_val.get_property_throwing("set") catch {
            _ => Undefined
          }
          let adder = match adder_val {
            Function(f) => f
            _ => {
              ctx.throw_type_error("Map.prototype.set is not a function")
              abort("Unreachable")
            }
          }

          // General Iterator Protocol
          let iterator_sym = match ctx.resolve("Symbol") {
            Function(f) =>
              f.inner.properties.get("iterator").unwrap_or(JSValue::Undefined)
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
                    let done = res_obj.get_property("done").is_truthy()
                    if done {
                      break
                    }
                    let value = res_obj.get_property("value")
                    match value {
                      Object(_) | Function(_) as item_obj => {
                        let key = item_obj.get_property("0")
                        let val = item_obj.get_property("1")
                        try
                          ctx.invoke(adder, this_val, [key, val]) |> ignore
                        catch {
                          e => {
                            iterator_close(ctx, iterator)
                            raise e
                          }
                        }
                      }
                      _ => {
                        iterator_close(ctx, iterator)
                        ctx.throw_type_error("Iterator value is not an object")
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
        ctx.throw_type_error("Map constructor called on non-object")
        Undefined
      }
    }
  })
  let ctor_obj = JSFunction::new(
    name="Map",
    params=[], // length 0
    body=ctor_fn,
    prototype=func_proto,
    is_constructor=true,
  )
  ctor_obj["prototype"] = map_proto
  JSValue::Function(ctor_obj)
}

///|
fn iterator_close(ctx : Context, iterator : JSValue) -> Unit {
  let return_val = iterator.get_property("return")
  match return_val {
    Function(f) => {
      let _ = ctx.invoke(f, iterator, []) catch { _ => Undefined }
      ()
    }
    _ => ()
  }
}

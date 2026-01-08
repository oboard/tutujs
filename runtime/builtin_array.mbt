///|
pub fn init_array_prototype(array_proto_val : JSValue) -> Unit {
  match array_proto_val {
    Object(obj) => {
      // push
      let push_fn = Native(fn(_ctx, this_val, args) {
        match this_val {
          Object(o) => {
            let mut len = match o["length"] {
              Number(n) => n
              _ => 0.0
            }
            for arg in args {
              o[len.to_string()] = arg
              len = len + 1.0
            }
            o["length"] = Number(len)
            Number(len)
          }
          _ => Number(0.0) // Should throw TypeError?
        }
      })
      let push_obj = JSFunction::new(name="push", body=push_fn)
      obj["push"] = JSValue::Function(push_obj)

      // pop
      let pop_fn = Native(fn(_ctx, this_val, _args) {
        match this_val {
          Object(o) => {
            let len = match o["length"] {
              Number(n) => n
              _ => 0.0
            }
            if len > 0.0 {
              let new_len = len - 1.0
              let val = o[new_len.to_string()]
              o.properties.remove(new_len.to_string())
              o["length"] = Number(new_len)
              val
            } else {
              o["length"] = Number(0.0)
              Undefined
            }
          }
          _ => Undefined
        }
      })
      let pop_obj = JSFunction::new(name="pop", body=pop_fn)
      obj["pop"] = JSValue::Function(pop_obj)

      // forEach
      let for_each_fn = Native(fn(ctx, this_val, args) {
        match this_val {
          Object(o) => {
            let len = match o["length"] {
              Number(n) => n.to_int()
              _ => 0
            }
            if args.length() > 0 {
              match args[0] {
                Function(callback) => {
                  let this_arg = if args.length() > 1 {
                    args[1]
                  } else {
                    JSValue::Undefined
                  }
                  for i = 0; i < len; i = i + 1 {
                    let key = i.to_string()
                    if o.properties.contains(key) {
                      let val = o[key]
                      let _ = ctx.invoke(callback, this_arg, [
                        val,
                        JSValue::Number(i.to_double()),
                        this_val,
                      ]) catch {
                        _ => JSValue::Undefined
                      }

                    }
                  }
                  JSValue::Undefined
                }
                _ => JSValue::Undefined // TypeError
              }
            } else {
              JSValue::Undefined // TypeError
            }
          }
          _ => JSValue::Undefined
        }
      })
      let for_each_obj = JSFunction::new(name="forEach", body=for_each_fn)
      obj["forEach"] = JSValue::Function(for_each_obj)

      // map
      let map_fn = Native(fn(ctx, this_val, args) {
        match this_val {
          Object(o) => {
            let len = match o["length"] {
              Number(n) => n.to_int()
              _ => 0
            }
            if args.length() > 0 {
              match args[0] {
                Function(callback) => {
                  let this_arg = if args.length() > 1 {
                    args[1]
                  } else {
                    JSValue::Undefined
                  }
                  let new_array = JSObject::{
                    properties: @hashmap.new(),
                    prototype: Some(array_proto_val),
                  }
                  new_array["length"] = JSValue::Number(len.to_double())
                  for i = 0; i < len; i = i + 1 {
                    let key = i.to_string()
                    if o.properties.contains(key) {
                      let val = o[key]
                      let mapped_val = ctx.invoke(callback, this_arg, [
                        val,
                        JSValue::Number(i.to_double()),
                        this_val,
                      ]) catch {
                        _ => JSValue::Undefined
                      }
                      new_array[key] = mapped_val
                    }
                  }
                  JSValue::Object(new_array)
                }
                _ => JSValue::Undefined
              }
            } else {
              JSValue::Undefined
            }
          }
          _ => JSValue::Undefined
        }
      })
      let map_obj = JSFunction::new(name="map", body=map_fn)
      obj["map"] = JSValue::Function(map_obj)

      // filter
      let filter_fn = Native(fn(ctx, this_val, args) {
        match this_val {
          Object(o) => {
            let len = match o["length"] {
              Number(n) => n.to_int()
              _ => 0
            }
            if args.length() > 0 {
              match args[0] {
                Function(callback) => {
                  let this_arg = if args.length() > 1 {
                    args[1]
                  } else {
                    JSValue::Undefined
                  }
                  let new_array = JSObject::{
                    properties: @hashmap.new(),
                    prototype: Some(array_proto_val),
                  }
                  let mut new_len = 0
                  for i = 0; i < len; i = i + 1 {
                    let key = i.to_string()
                    if o.properties.contains(key) {
                      let val = o[key]
                      let predicate = ctx.invoke(callback, this_arg, [
                        val,
                        JSValue::Number(i.to_double()),
                        this_val,
                      ]) catch {
                        _ => JSValue::Undefined
                      }
                      if predicate.is_truthy() {
                        new_array[new_len.to_string()] = val
                        new_len = new_len + 1
                      }
                    }
                  }
                  new_array["length"] = JSValue::Number(new_len.to_double())
                  JSValue::Object(new_array)
                }
                _ => JSValue::Undefined
              }
            } else {
              JSValue::Undefined
            }
          }
          _ => JSValue::Undefined
        }
      })
      let filter_obj = JSFunction::new(name="filter", body=filter_fn)
      obj["filter"] = JSValue::Function(filter_obj)

      // reduce
      let reduce_fn = Native(fn(ctx, this_val, args) {
        match this_val {
          Object(o) => {
            let len = match o["length"] {
              Number(n) => n.to_int()
              _ => 0
            }
            if args.length() > 0 {
              match args[0] {
                Function(callback) => {
                  let mut k = 0
                  let mut accumulator = JSValue::Undefined

                  // Initialize accumulator
                  if args.length() > 1 {
                    accumulator = args[1]
                  } else {
                    // No initial value, find first present element
                    let mut k_present = false
                    while k < len && not(k_present) {
                      let key = k.to_string()
                      if o.properties.contains(key) {
                        accumulator = o[key]
                        k_present = true
                      }
                      k = k + 1
                    }
                    if not(k_present) {
                      // TypeError: Reduce of empty array with no initial value
                      // For now return Undefined
                      return JSValue::Undefined
                    }
                  }
                  while k < len {
                    let key = k.to_string()
                    if o.properties.contains(key) {
                      let val = o[key]
                      accumulator = ctx.invoke(callback, JSValue::Undefined, [
                        accumulator,
                        val,
                        JSValue::Number(k.to_double()),
                        this_val,
                      ]) catch {
                        _ => JSValue::Undefined
                      }
                    }
                    k = k + 1
                  }
                  accumulator
                }
                _ => JSValue::Undefined
              }
            } else {
              JSValue::Undefined
            }
          }
          _ => JSValue::Undefined
        }
      })
      let reduce_obj = JSFunction::new(name="reduce", body=reduce_fn)
      obj["reduce"] = JSValue::Function(reduce_obj)

      // every
      let every_fn = Native(fn(ctx, this_val, args) {
        match this_val {
          Object(o) => {
            let len = match o["length"] {
              Number(n) => n.to_int()
              _ => 0
            }
            if args.length() > 0 {
              match args[0] {
                Function(callback) => {
                  let this_arg = if args.length() > 1 {
                    args[1]
                  } else {
                    JSValue::Undefined
                  }
                  for i = 0; i < len; i = i + 1 {
                    let key = i.to_string()
                    if o.properties.contains(key) {
                      let val = o[key]
                      let test_res = ctx.invoke(callback, this_arg, [
                        val,
                        JSValue::Number(i.to_double()),
                        this_val,
                      ]) catch {
                        _ => JSValue::Undefined
                      }
                      if not(test_res.is_truthy()) {
                        return JSValue::Boolean(false)
                      }
                    }
                  }
                  JSValue::Boolean(true)
                }
                _ => JSValue::Boolean(true) // Should be TypeError
              }
            } else {
              JSValue::Boolean(true) // Should be TypeError
            }
          }
          _ => JSValue::Boolean(true) // Should be TypeError
        }
      })
      let every_obj = JSFunction::new(name="every", body=every_fn)
      obj["every"] = JSValue::Function(every_obj)

      // some
      let some_fn = Native(fn(ctx, this_val, args) {
        match this_val {
          Object(
            { properties: { "length": Number(len), .. } as properties, .. }
          ) =>
            if args is [Function(callback), .. rest] {
              let this_arg = if rest is [this_arg, ..] {
                this_arg
              } else {
                JSValue::Undefined
              }
              for i = 0; i < len.to_int(); i = i + 1 {
                let key = i.to_string()
                if properties.get(key) is Some(val) {
                  let test_res = ctx.invoke(callback, this_arg, [
                    val,
                    JSValue::Number(i.to_double()),
                    this_val,
                  ]) catch {
                    _ => JSValue::Undefined
                  }
                  if test_res.is_truthy() {
                    return JSValue::Boolean(true)
                  }
                }
              }
              JSValue::Boolean(false)
            } else {
              JSValue::Boolean(false) // Should be TypeError
            }
          // Object(o) => {
          //   let len = match o["length"] {
          //     Number(n) => n.to_int()
          //     _ => 0
          //   }
          //   if args.length() > 0 {
          //     match args[0] {
          //       Function(callback) => {
          //         let this_arg = if args.length() > 1 {
          //           args[1]
          //         } else {
          //           JSValue::Undefined
          //         }
          //         for i = 0; i < len; i = i + 1 {
          //           let key = i.to_string()
          //           if o.properties.contains(key) {
          //             let val = o[key]
          //             let test_res = ctx.invoke(callback, this_arg, [
          //               val,
          //               JSValue::Number(i.to_double()),
          //               this_val,
          //             ]) catch {
          //               _ => JSValue::Undefined
          //             }
          //             if test_res.is_truthy() {
          //               return JSValue::Boolean(true)
          //             }
          //           }
          //         }
          //         JSValue::Boolean(false)
          //       }
          //       _ => JSValue::Boolean(false) // Should be TypeError
          //     }
          //   } else {
          //     JSValue::Boolean(false) // Should be TypeError
          //   }
          // }
          _ => JSValue::Boolean(false) // Should be TypeError
        }
      })
      let some_obj = JSFunction::new(name="some", body=some_fn)
      obj["some"] = JSValue::Function(some_obj)
    }
    _ => ()
  }
}

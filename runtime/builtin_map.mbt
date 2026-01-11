///|
pub fn create_map_constructor(
  map_proto : JSValue,
  func_proto : JSValue,
) -> JSValue {
  let ctor_fn = Native(fn(ctx, this_val, args) {
    match this_val {
      Object(obj) => {
        let map_data = @hashmap.new()
        obj.properties.set("MapData", JSValue::Internal(Map(map_data)))
        
        if args.length() > 0 && not(args[0] == Undefined || args[0] == Null) {
          let iterable = args[0]
          let adder = match this_val.get_property("set") {
             Function(f) => f
             _ => {
                 ctx.throw_type_error("Map.prototype.set is not a function")
                 return Undefined
             }
          }
          
          // Simple iteration for Array
          match iterable {
             Object(obj) => {
                // Check for array-like
                let len_prop = obj.properties.get("length")
                match len_prop {
                   Some(Number(len)) => {
                      let len = len.to_int()
                      let mut i = 0
                      while i < len {
                         let item = iterable.get_property(i.to_string())
                         match item {
                            Object(_) as item_obj => {
                               let key = item_obj.get_property("0")
                               let value = item_obj.get_property("1")
                               ctx.invoke(adder, this_val, [key, value]) |> ignore
                            }
                            _ => {
                               ctx.throw_type_error("Iterator value is not an object")
                               break
                            }
                         }
                         i = i + 1
                      }
                   }
                   _ => ()
                }
             }
             _ => {
                // Throw TypeError if not iterable?
                // For now, silently ignore non-objects or non-arrays as we don't have full iterator protocol
                ()
             }
          }
          ()
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
    params=["iterable"],
    body=ctor_fn,
    prototype=func_proto,
    is_constructor=true,
  )
  ctor_obj.properties.set("prototype", map_proto)
  JSValue::Function(ctor_obj)
}

///|
pub fn init_map_prototype(map_proto : JSValue, func_proto : JSValue) -> Unit {
  match map_proto {
    Object(proto) => {
      proto.properties.set("constructor", JSValue::Undefined) // Will be set later
      
      // size getter
      let size_getter = JSFunction::new(
        name="get size",
        body=Native(fn(ctx, this_val, _args) {
          match this_val {
             Object({ properties, .. }) => {
                match properties.get("MapData") {
                   Some(Internal(Map(m))) => JSValue::Number(m.length().to_double())
                   _ => {
                      ctx.throw_type_error("Method Map.prototype.size called on incompatible receiver")
                      Undefined
                   }
                }
             }
             _ => {
                ctx.throw_type_error("Method Map.prototype.size called on incompatible receiver")
                Undefined
             }
          }
        }),
        prototype=func_proto
      )
      let size_accessor = JSInternal::Accessor(Some(size_getter), None)
      proto.properties.set("size", JSValue::Internal(size_accessor))

      // set
      let set_fn = JSFunction::new(
        name="set",
        params=["key", "value"],
        body=Native(fn(ctx, this_val, args) {
           let key = if args.length() > 0 { args[0] } else { Undefined }
           let value = if args.length() > 1 { args[1] } else { Undefined }
           match this_val {
             Object({ properties, .. }) => {
                match properties.get("MapData") {
                   Some(Internal(Map(m))) => {
                      let key = if key == Number(-0.0) { Number(0.0) } else { key }
                      m.set(key, value)
                      this_val
                   }
                   _ => {
                      ctx.throw_type_error("Method Map.prototype.set called on incompatible receiver")
                      Undefined
                   }
                }
             }
             _ => {
                ctx.throw_type_error("Method Map.prototype.set called on incompatible receiver")
                Undefined
             }
           }
        }),
        prototype=func_proto
      )
      proto.properties.set("set", JSValue::Function(set_fn))

      // get
      let get_fn = JSFunction::new(
        name="get",
        params=["key"],
        body=Native(fn(ctx, this_val, args) {
           let key = if args.length() > 0 { args[0] } else { Undefined }
           match this_val {
             Object({ properties, .. }) => {
                match properties.get("MapData") {
                   Some(Internal(Map(m))) => {
                      let key = if key == Number(-0.0) { Number(0.0) } else { key }
                      match m.get(key) {
                         Some(v) => v
                         None => Undefined
                      }
                   }
                   _ => {
                      ctx.throw_type_error("Method Map.prototype.get called on incompatible receiver")
                      Undefined
                   }
                }
             }
             _ => {
                ctx.throw_type_error("Method Map.prototype.get called on incompatible receiver")
                Undefined
             }
           }
        }),
        prototype=func_proto
      )
      proto.properties.set("get", JSValue::Function(get_fn))

      // has
      let has_fn = JSFunction::new(
        name="has",
        params=["key"],
        body=Native(fn(ctx, this_val, args) {
           let key = if args.length() > 0 { args[0] } else { Undefined }
           match this_val {
             Object({ properties, .. }) => {
                match properties.get("MapData") {
                   Some(Internal(Map(m))) => {
                      let key = if key == Number(-0.0) { Number(0.0) } else { key }
                      Boolean(m.contains(key))
                   }
                   _ => {
                      ctx.throw_type_error("Method Map.prototype.has called on incompatible receiver")
                      Undefined
                   }
                }
             }
             _ => {
                ctx.throw_type_error("Method Map.prototype.has called on incompatible receiver")
                Undefined
             }
           }
        }),
        prototype=func_proto
      )
      proto.properties.set("has", JSValue::Function(has_fn))

      // delete
      let delete_fn = JSFunction::new(
        name="delete",
        params=["key"],
        body=Native(fn(ctx, this_val, args) {
           let key = if args.length() > 0 { args[0] } else { Undefined }
           match this_val {
             Object({ properties, .. }) => {
                match properties.get("MapData") {
                   Some(Internal(Map(m))) => {
                      let key = if key == Number(-0.0) { Number(0.0) } else { key }
                      if m.contains(key) {
                         m.remove(key)
                         Boolean(true)
                      } else {
                         Boolean(false)
                      }
                   }
                   _ => {
                      ctx.throw_type_error("Method Map.prototype.delete called on incompatible receiver")
                      Undefined
                   }
                }
             }
             _ => {
                ctx.throw_type_error("Method Map.prototype.delete called on incompatible receiver")
                Undefined
             }
           }
        }),
        prototype=func_proto
      )
      proto.properties.set("delete", JSValue::Function(delete_fn))

      // clear
      let clear_fn = JSFunction::new(
        name="clear",
        params=[],
        body=Native(fn(ctx, this_val, _args) {
           match this_val {
             Object({ properties, .. }) => {
                match properties.get("MapData") {
                   Some(Internal(Map(m))) => {
                      m.clear()
                      Undefined
                   }
                   _ => {
                      ctx.throw_type_error("Method Map.prototype.clear called on incompatible receiver")
                      Undefined
                   }
                }
             }
             _ => {
                ctx.throw_type_error("Method Map.prototype.clear called on incompatible receiver")
                Undefined
             }
           }
        }),
        prototype=func_proto
      )
      proto.properties.set("clear", JSValue::Function(clear_fn))
      
      // getOrInsertComputed
      let get_or_insert_computed_fn = JSFunction::new(
        name="getOrInsertComputed",
        params=["key", "callbackfn"],
        body=Native(fn(ctx, this_val, args) {
           let key = if args.length() > 0 { args[0] } else { Undefined }
           let callback = if args.length() > 1 { args[1] } else { Undefined }
           
           match this_val {
             Object({ properties, .. }) => {
                match properties.get("MapData") {
                   Some(Internal(Map(m))) => {
                      let key = if key == Number(-0.0) { Number(0.0) } else { key }
                      if m.contains(key) {
                         m.get(key).unwrap()
                      } else {
                         match callback {
                            Function(f) => {
                               let value = ctx.invoke(f, Undefined, [key])
                               m.set(key, value)
                               value
                            }
                            _ => {
                               ctx.throw_type_error("Callback must be a function")
                               Undefined
                            }
                         }
                      }
                   }
                   _ => {
                      ctx.throw_type_error("Method Map.prototype.getOrInsertComputed called on incompatible receiver")
                      Undefined
                   }
                }
             }
             _ => {
                ctx.throw_type_error("Method Map.prototype.getOrInsertComputed called on incompatible receiver")
                Undefined
             }
           }
        }),
        prototype=func_proto
      )
      proto.properties.set("getOrInsertComputed", JSValue::Function(get_or_insert_computed_fn))

      // entries
      let entries_fn = JSFunction::new(
        name="entries",
        params=[],
        body=Native(fn(ctx, _this_val, _args) {
           // Basic empty iterator
           let iter_proto = match ctx.scope.get("IteratorPrototype") {
              Some(p) => p
              None => match func_proto { // Use func_proto or object_proto as fallback
                 Object({ prototype, .. }) => prototype.unwrap_or(func_proto)
                 _ => func_proto
              }
           }
           let next_fn = Native(fn(_ctx, _this, _args) {
              let iter_proto_val = match iter_proto {
                 Object(_) => iter_proto
                 _ => JSValue::Null
              }
              let res = JSObject::new(
                 properties=@hashmap.new(),
                 prototype=iter_proto_val,
              )
              res.properties.set("value", Undefined)
              res.properties.set("done", Boolean(true))
              JSValue::Object(res)
           })
           let iter_proto_val_2 = match iter_proto {
              Object(_) => iter_proto
              _ => JSValue::Null
           }
           let iter = JSObject::new(
              properties=@hashmap.new(),
              prototype=iter_proto_val_2
           )
           // Prototype of iterator should be IteratorPrototype?
           // For now just object with next method
           let next_obj = JSFunction::new(name="next", body=next_fn, prototype=func_proto)
           iter.properties.set("next", JSValue::Function(next_obj))
           JSValue::Object(iter)
        }),
        prototype=func_proto
      )
      proto.properties.set("entries", JSValue::Function(entries_fn))

      // keys
      let keys_fn = JSFunction::new(
        name="keys",
        params=[],
        body=Native(fn(ctx, this_val, args) {
           // Reuse entries implementation for now (returns empty iterator)
           match this_val.get_property("entries") {
              Function(f) => ctx.invoke(f, this_val, args)
              _ => Undefined
           }
        }),
        prototype=func_proto
      )
      proto.properties.set("keys", JSValue::Function(keys_fn))

      // values
      let values_fn = JSFunction::new(
        name="values",
        params=[],
        body=Native(fn(ctx, this_val, args) {
           // Reuse entries implementation for now (returns empty iterator)
           match this_val.get_property("entries") {
              Function(f) => ctx.invoke(f, this_val, args)
              _ => Undefined
           }
        }),
        prototype=func_proto
      )
      proto.properties.set("values", JSValue::Function(values_fn))

      // forEach
      let for_each_fn = JSFunction::new(
        name="forEach",
        params=["callbackfn", "thisArg"],
        body=Native(fn(ctx, this_val, args) {
           let callback = if args.length() > 0 { args[0] } else { Undefined }
           let this_arg = if args.length() > 1 { args[1] } else { Undefined }
           
           match this_val {
             Object({ properties, .. }) => {
                match properties.get("MapData") {
                   Some(Internal(Map(m))) => {
                      match callback {
                         Function(f) => {
                            for k, v in m {
                               ctx.invoke(f, this_arg, [v, k, this_val]) |> ignore
                            }
                            Undefined
                         }
                         _ => {
                            ctx.throw_type_error("Callback must be a function")
                            Undefined
                         }
                      }
                   }
                   _ => {
                      ctx.throw_type_error("Method Map.prototype.forEach called on incompatible receiver")
                      Undefined
                   }
                }
             }
             _ => {
                ctx.throw_type_error("Method Map.prototype.forEach called on incompatible receiver")
                Undefined
             }
           }
        }),
        prototype=func_proto
      )
      proto.properties.set("forEach", JSValue::Function(for_each_fn))
      
      // Symbol.iterator -> entries
      proto.properties.set("Symbol.iterator", JSValue::Function(entries_fn))

      // Symbol.toStringTag
      proto.properties.set("Symbol.toStringTag", JSValue::String("Map"))
    }
    _ => ()
  }
}

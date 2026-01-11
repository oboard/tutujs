///|
pub fn create_map_constructor(
  map_proto : JSValue,
  func_proto : JSValue,
) -> JSValue {
  let ctor_fn = Native(fn(ctx, this_val, args) {
    match this_val {
      Object(obj) => {
        let map_data = LinkedMap::new()
        obj.properties.set("MapData", JSValue::Internal(Map(map_data)))
        if args.length() > 0 && not(args[0] is( Undefined | Null)) {
          let iterable = args[0]
          let adder_val = try {
             this_val.get_property_throw("set")
           } catch {
             e => raise e
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
             Function(f) => f.properties.get("iterator").unwrap_or(JSValue::Undefined)
             _ => JSValue::Undefined
          }
          let iterator_key = match iterator_sym {
             Symbol(_) => iterator_sym.to_string()
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
                Object(_) as obj => obj
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
                let next_res = ctx.invoke(next_method, iterator, [])
                match next_res {
                      Object(_) as res_obj => {
                         let done = try {
                            res_obj.get_property_throw("done")
                         } catch {
                            e => raise e
                         }
                         if done.is_truthy() { break }
                         
                         let value = try {
                            res_obj.get_property_throw("value")
                         } catch {
                            e => {
                               // Iterator Close
                               match iterator.get_property("return") {
                                  Function(ret_fn) => {
                                     try { ctx.invoke(ret_fn, iterator, []) |> ignore } catch { _ => () }
                                  }
                                  _ => ()
                               }
                               raise e
                            }
                         }
                         
                         match value {
                            Object(_) as item_obj => {
                               let key = try {
                                  item_obj.get_property_throw("0")
                               } catch {
                                  e => {
                                     // Iterator Close
                                     match iterator.get_property("return") {
                                        Function(ret_fn) => {
                                           try { ctx.invoke(ret_fn, iterator, []) |> ignore } catch { _ => () }
                                        }
                                        _ => ()
                                     }
                                     raise e
                                  }
                               }
                               let val = try {
                                  item_obj.get_property_throw("1")
                               } catch {
                                  e => {
                                     // Iterator Close
                                     match iterator.get_property("return") {
                                        Function(ret_fn) => {
                                           try { ctx.invoke(ret_fn, iterator, []) |> ignore } catch { _ => () }
                                        }
                                        _ => ()
                                     }
                                     raise e
                                  }
                               }
                               try {
                                   ctx.invoke(adder, this_val, [key, val]) |> ignore
                               } catch {
                          e => {
                            // Iterator Close
                            match iterator.get_property("return") {
                              Function(ret_fn) => {
                                try { ctx.invoke(ret_fn, iterator, []) |> ignore } catch { _ => () }
                              }
                              _ => ()
                            }
                            raise e
                          }
                        }
                      }
                      _ => {
                        // Iterator Close
                        match iterator.get_property("return") {
                          Function(ret_fn) => {
                            try { ctx.invoke(ret_fn, iterator, []) |> ignore } catch { _ => () }
                          }
                          _ => ()
                        }
                        ctx.throw_type_error("Iterator value is not an object")
                        break
                      }
                    }
                  }
                  _ => {
                    ctx.throw_type_error("Iterator result is not an object")
                    break
                  }
                }
              }
            }
            _ => {
              // Not iterable
              ctx.throw_type_error("Object is not iterable")
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
    params=[], // length 0
    body=ctor_fn,
    prototype=func_proto,
    is_constructor=true,
  )
  ctor_obj.properties.set("prototype", map_proto)
  JSValue::Function(ctor_obj)
}

///|
pub fn init_map_prototype(
  ctx : Context,
  map_proto : JSValue,
  func_proto : JSValue,
) -> Unit {
  match map_proto {
    Object(proto) => {
      proto.properties.set("constructor", JSValue::Undefined) // Will be set later

      // size getter
      let size_getter = JSFunction::new(
        name="get size",
        body=Native(fn(ctx, this_val, _args) {
          match this_val {
            Object({ properties, .. }) =>
              match properties.get("MapData") {
                Some(Internal(Map(m))) =>
                  JSValue::Number(m.length().to_double())
                _ => {
                  ctx.throw_type_error(
                    "Method Map.prototype.size called on incompatible receiver",
                  )
                  Undefined
                }
              }
            _ => {
              ctx.throw_type_error(
                "Method Map.prototype.size called on incompatible receiver",
              )
              Undefined
            }
          }
        }),
        prototype=func_proto,
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
            Object({ properties, .. }) =>
              match properties.get("MapData") {
                Some(Internal(Map(m))) => {
                  let key = if key == Number(-0.0) { Number(0.0) } else { key }
                  m.set(key, value)
                  this_val
                }
                _ => {
                  ctx.throw_type_error(
                    "Method Map.prototype.set called on incompatible receiver",
                  )
                  Undefined
                }
              }
            _ => {
              ctx.throw_type_error(
                "Method Map.prototype.set called on incompatible receiver",
              )
              Undefined
            }
          }
        }),
        prototype=func_proto,
      )
      proto.properties.set("set", JSValue::Function(set_fn))

      // get
      let get_fn = JSFunction::new(
        name="get",
        params=["key"],
        body=Native(fn(ctx, this_val, args) {
          let key = if args.length() > 0 { args[0] } else { Undefined }
          match this_val {
            Object({ properties, .. }) =>
              match properties.get("MapData") {
                Some(Internal(Map(m))) => {
                  let key = if key == Number(-0.0) { Number(0.0) } else { key }
                  match m.get(key) {
                    Some(v) => v
                    None => Undefined
                  }
                }
                _ => {
                  ctx.throw_type_error(
                    "Method Map.prototype.get called on incompatible receiver",
                  )
                  Undefined
                }
              }
            _ => {
              ctx.throw_type_error(
                "Method Map.prototype.get called on incompatible receiver",
              )
              Undefined
            }
          }
        }),
        prototype=func_proto,
      )
      proto.properties.set("get", JSValue::Function(get_fn))

      // has
      let has_fn = JSFunction::new(
        name="has",
        params=["key"],
        body=Native(fn(ctx, this_val, args) {
          let key = if args.length() > 0 { args[0] } else { Undefined }
          match this_val {
            Object({ properties, .. }) =>
              match properties.get("MapData") {
                Some(Internal(Map(m))) => {
                  let key = if key == Number(-0.0) { Number(0.0) } else { key }
                  Boolean(m.contains(key))
                }
                _ => {
                  ctx.throw_type_error(
                    "Method Map.prototype.has called on incompatible receiver",
                  )
                  Undefined
                }
              }
            _ => {
              ctx.throw_type_error(
                "Method Map.prototype.has called on incompatible receiver",
              )
              Undefined
            }
          }
        }),
        prototype=func_proto,
      )
      proto.properties.set("has", JSValue::Function(has_fn))

      // delete
      let delete_fn = JSFunction::new(
        name="delete",
        params=["key"],
        body=Native(fn(ctx, this_val, args) {
          let key = if args.length() > 0 { args[0] } else { Undefined }
          match this_val {
            Object({ properties, .. }) =>
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
                  ctx.throw_type_error(
                    "Method Map.prototype.delete called on incompatible receiver",
                  )
                  Undefined
                }
              }
            _ => {
              ctx.throw_type_error(
                "Method Map.prototype.delete called on incompatible receiver",
              )
              Undefined
            }
          }
        }),
        prototype=func_proto,
      )
      proto.properties.set("delete", JSValue::Function(delete_fn))

      // clear
      let clear_fn = JSFunction::new(
        name="clear",
        params=[],
        body=Native(fn(ctx, this_val, _args) {
          match this_val {
            Object({ properties, .. }) =>
              match properties.get("MapData") {
                Some(Internal(Map(m))) => {
                  m.clear()
                  Undefined
                }
                _ => {
                  ctx.throw_type_error(
                    "Method Map.prototype.clear called on incompatible receiver",
                  )
                  Undefined
                }
              }
            _ => {
              ctx.throw_type_error(
                "Method Map.prototype.clear called on incompatible receiver",
              )
              Undefined
            }
          }
        }),
        prototype=func_proto,
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
            Object({ properties, .. }) =>
              match properties.get("MapData") {
                Some(Internal(Map(m))) => {
                  match callback {
                    Function(f) => {
                      let key = if key == Number(-0.0) { Number(0.0) } else { key }
                      if m.contains(key) {
                        m.get(key).unwrap()
                      } else {
                        let value = ctx.invoke(f, Undefined, [key])
                        m.set(key, value)
                        value
                      }
                    }
                    _ => {
                      ctx.throw_type_error("Callback must be a function")
                      Undefined
                    }
                  }
                }
                _ => {
                  ctx.throw_type_error(
                    "Method Map.prototype.getOrInsertComputed called on incompatible receiver",
                  )
                  Undefined
                }
              }
            _ => {
              ctx.throw_type_error(
                "Method Map.prototype.getOrInsertComputed called on incompatible receiver",
              )
              Undefined
            }
          }
        }),
        prototype=func_proto,
      )
      proto.properties.set(
        "getOrInsertComputed",
        JSValue::Function(get_or_insert_computed_fn),
      )

      // Iterator Setup
      let iterator_proto = match ctx.scope.get("IteratorPrototype") {
        Some(p) => p
        None => func_proto
      }
      let map_iter_proto = JSObject::new(
        properties=@hashmap.new(),
        prototype=iterator_proto,
      )
      map_iter_proto.properties.set(
        "Symbol.toStringTag",
        JSValue::String("Map Iterator"),
      )
      let map_iter_proto_val = JSValue::Object(map_iter_proto)
      let map_iter_next_fn = Native(fn(ctx, this_val, _args) {
        match this_val {
          Object({ properties, .. }) =>
            match properties.get("MapData") {
              Some(Internal(MapIterator(_m, cursor, kind))) => {
                // Skip removed entries
                let mut current = cursor.val
                while true {
                  match current {
                    Some(entry) =>
                      if entry.removed {
                        current = entry.next
                        continue
                      }
                    None => ()
                  }
                  break
                }
                match current {
                  Some(entry) => {
                    cursor.val = entry.next
                    let value = match kind {
                      "key" => entry.key
                      "value" => entry.value
                      "key+value" => {
                        let array_proto = match ctx.scope.get("Array") {
                          Some(Function({ properties, .. })) =>
                            properties.get("prototype").unwrap_or(JSValue::Null)
                          _ => JSValue::Null
                        }
                        let arr = JSObject::new(
                          properties=@hashmap.new(),
                          prototype=array_proto,
                        )
                        arr.properties.set("0", entry.key)
                        arr.properties.set("1", entry.value)
                        arr.properties.set("length", JSValue::Number(2.0))
                        JSValue::Object(arr)
                      }
                      _ => Undefined
                    }
                    let object_proto = match ctx.scope.get("Object") {
                      Some(Function({ properties, .. })) =>
                        properties.get("prototype").unwrap_or(JSValue::Null)
                      _ => JSValue::Null
                    }
                    let res = JSObject::new(
                      properties=@hashmap.new(),
                      prototype=object_proto,
                    )
                    res.properties.set("value", value)
                    res.properties.set("done", Boolean(false))
                    JSValue::Object(res)
                  }
                  None => {
                    let object_proto = match ctx.scope.get("Object") {
                      Some(Function({ properties, .. })) =>
                        properties.get("prototype").unwrap_or(JSValue::Null)
                      _ => JSValue::Null
                    }
                    let res = JSObject::new(
                      properties=@hashmap.new(),
                      prototype=object_proto,
                    )
                    res.properties.set("value", Undefined)
                    res.properties.set("done", Boolean(true))
                    JSValue::Object(res)
                  }
                }
              }
              _ => {
                ctx.throw_type_error(
                  "Method Map Iterator.prototype.next called on incompatible receiver",
                )
                Undefined
              }
            }
          _ => {
            ctx.throw_type_error(
              "Method Map Iterator.prototype.next called on incompatible receiver",
            )
            Undefined
          }
        }
      })
      let map_iter_next = JSFunction::new(
        name="next",
        body=map_iter_next_fn,
        prototype=func_proto,
      )
      map_iter_proto.properties.set("next", JSValue::Function(map_iter_next))
      let create_map_iter = fn(_ctx : Context, m : LinkedMap, kind : String) {
        let iter = JSObject::new(
          properties=@hashmap.new(),
          prototype=map_iter_proto_val,
        )
        iter.properties.set(
          "MapData",
          JSValue::Internal(MapIterator(m, Ref::new(m.head), kind)),
        )
        JSValue::Object(iter)
      }

      // entries
      let entries_fn = JSFunction::new(
        name="entries",
        params=[],
        body=Native(fn(ctx, this_val, _args) {
          match this_val {
            Object({ properties, .. }) =>
              match properties.get("MapData") {
                Some(Internal(Map(m))) => create_map_iter(ctx, m, "key+value")
                _ => {
                  ctx.throw_type_error(
                    "Method Map.prototype.entries called on incompatible receiver",
                  )
                  Undefined
                }
              }
            _ => {
              ctx.throw_type_error(
                "Method Map.prototype.entries called on incompatible receiver",
              )
              Undefined
            }
          }
        }),
        prototype=func_proto,
      )
      proto.properties.set("entries", JSValue::Function(entries_fn))

      // keys
      let keys_fn = JSFunction::new(
        name="keys",
        params=[],
        body=Native(fn(ctx, this_val, _args) {
          match this_val {
            Object({ properties, .. }) =>
              match properties.get("MapData") {
                Some(Internal(Map(m))) => create_map_iter(ctx, m, "key")
                _ => {
                  ctx.throw_type_error(
                    "Method Map.prototype.keys called on incompatible receiver",
                  )
                  Undefined
                }
              }
            _ => {
              ctx.throw_type_error(
                "Method Map.prototype.keys called on incompatible receiver",
              )
              Undefined
            }
          }
        }),
        prototype=func_proto,
      )
      proto.properties.set("keys", JSValue::Function(keys_fn))

      // values
      let values_fn = JSFunction::new(
        name="values",
        params=[],
        body=Native(fn(ctx, this_val, _args) {
          match this_val {
            Object({ properties, .. }) =>
              match properties.get("MapData") {
                Some(Internal(Map(m))) => create_map_iter(ctx, m, "value")
                _ => {
                  ctx.throw_type_error(
                    "Method Map.prototype.values called on incompatible receiver",
                  )
                  Undefined
                }
              }
            _ => {
              ctx.throw_type_error(
                "Method Map.prototype.values called on incompatible receiver",
              )
              Undefined
            }
          }
        }),
        prototype=func_proto,
      )
      proto.properties.set("values", JSValue::Function(values_fn))

      // forEach
      let for_each_fn = JSFunction::new(
        name="forEach",
        params=["callbackfn"], // length 1
        body=Native(fn(ctx, this_val, args) {
          let callback = if args.length() > 0 { args[0] } else { Undefined }
          let this_arg = if args.length() > 1 { args[1] } else { Undefined }
          match this_val {
            Object({ properties, .. }) =>
              match properties.get("MapData") {
                Some(Internal(Map(m))) =>
                  match callback {
                    Function(f) => {
                      let mut current = m.head
                      while true {
                        match current {
                          Some(entry) => {
                            ctx.invoke(f, this_arg, [
                              entry.value,
                              entry.key,
                              this_val,
                            ])
                            |> ignore
                            current = entry.next
                          }
                          None => break
                        }
                      }
                      Undefined
                    }
                    _ => {
                      ctx.throw_type_error("Callback must be a function")
                      Undefined
                    }
                  }
                _ => {
                  ctx.throw_type_error(
                    "Method Map.prototype.forEach called on incompatible receiver",
                  )
                  Undefined
                }
              }
            _ => {
              ctx.throw_type_error(
                "Method Map.prototype.forEach called on incompatible receiver",
              )
              Undefined
            }
          }
        }),
        prototype=func_proto,
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

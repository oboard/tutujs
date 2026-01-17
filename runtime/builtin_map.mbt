///|
pub fn init_map_prototype(
  ctx : Context,
  map_proto : JSValue,
  func_proto : JSValue,
) -> Unit {
  match map_proto {
    Object(proto) => {
      proto["constructor"] = JSValue::Undefined // Will be set later

      // size getter
      let size_getter = JSObject::new_function(
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
      proto["size"] = JSValue::Internal(size_accessor)

      // set
      let set_fn = JSObject::new_function(
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
      proto["set"] = JSValue::Object(set_fn)

      // get
      let get_fn = JSObject::new_function(
        name="get",
        params=["key"],
        body=Native(fn(ctx, this_val, args) {
          let key = if args.length() > 0 { args[0] } else { Undefined }
          match this_val {
            Object({ properties: { "MapData": Internal(Map(m)), .. }, .. }) => {
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
        }),
        prototype=func_proto,
      )
      proto["get"] = JSValue::Object(get_fn)

      // has
      let has_fn = JSObject::new_function(
        name="has",
        params=["key"],
        body=Native(fn(ctx, this_val, args) {
          let key = if args.length() > 0 { args[0] } else { Undefined }
          match this_val {
            Object({ properties: { "MapData": Internal(Map(m)), .. }, .. }) => {
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
        }),
        prototype=func_proto,
      )
      proto["has"] = JSValue::Object(has_fn)

      // delete
      let delete_fn = JSObject::new_function(
        name="delete",
        params=["key"],
        body=Native(fn(ctx, this_val, args) {
          let key = if args.length() > 0 { args[0] } else { Undefined }
          match this_val {
            Object({ properties: { "MapData": Internal(Map(m)), .. }, .. }) => {
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
        }),
        prototype=func_proto,
      )
      proto["delete"] = JSValue::Object(delete_fn)

      // clear
      let clear_fn = JSObject::new_function(
        name="clear",
        params=[],
        body=Native(fn(ctx, this_val, _args) {
          match this_val {
            Object({ properties: { "MapData": Internal(Map(m)), .. }, .. }) =>
              m.clear()
            _ =>
              ctx.throw_type_error(
                "Method Map.prototype.clear called on incompatible receiver",
              )
          }
          Undefined
        }),
        prototype=func_proto,
      )
      proto["clear"] = JSValue::Object(clear_fn)

      // getOrInsertComputed
      let get_or_insert_computed_fn = JSObject::new_function(
        name="getOrInsertComputed",
        params=["key", "callbackfn"],
        body=Native(fn(ctx, this_val, args) {
          let key = if args.length() > 0 { args[0] } else { Undefined }
          let callback = if args.length() > 1 { args[1] } else { Undefined }
          match this_val {
            Object({ properties: { "MapData": Internal(Map(m)), .. }, .. }) =>
              match callback {
                Object(f) => {
                  if not(f.is_callable) {
                    ctx.throw_type_error("Callback must be a function")
                    return Undefined
                  }
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
      proto["getOrInsertComputed"] = JSValue::Object(get_or_insert_computed_fn)

      // Iterator Setup
      let iterator_proto = match ctx.scope.get("IteratorPrototype") {
        Some(p) => p
        None => func_proto
      }
      let map_iter_proto = JSObject::new(
        properties={},
        prototype=iterator_proto,
      )
      map_iter_proto["Symbol.toStringTag"] = JSValue::String("Map Iterator")
      let map_iter_proto_val = JSValue::Object(map_iter_proto)
      let map_iter_next_fn = Native(fn(ctx, this_val, _args) {
        match this_val {
          Object(
            {
              properties: {
                "MapData": Internal(MapIterator(_m, cursor, kind)),
                ..
              },
              ..,
            }
          ) => {
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
                      Some(Object({ properties, .. })) =>
                        properties.get("prototype").unwrap_or(JSValue::Null)
                      _ => JSValue::Null
                    }
                    let arr = JSObject::new(
                      properties={},
                      prototype=array_proto,
                    )
                    arr["0"] = entry.key
                    arr["1"] = entry.value
                    arr["length"] = JSValue::Number(2.0)
                    JSValue::Object(arr)
                  }
                  _ => Undefined
                }
                let object_proto = match ctx.scope.get("Object") {
                  Some(Object({ properties, .. })) =>
                    properties.get("prototype").unwrap_or(JSValue::Null)
                  _ => JSValue::Null
                }
                let res = JSObject::new(properties={}, prototype=object_proto)
                res["value"] = value
                res["done"] = Boolean(false)
                JSValue::Object(res)
              }
              None => {
                let object_proto = match ctx.scope.get("Object") {
                  Some(Object({ properties, .. })) =>
                    properties.get("prototype").unwrap_or(JSValue::Null)
                  _ => JSValue::Null
                }
                let res = JSObject::new(properties={}, prototype=object_proto)
                res["value"] = Undefined
                res["done"] = Boolean(true)
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
      })
      let map_iter_next = JSObject::new_function(
        name="next",
        body=map_iter_next_fn,
        prototype=func_proto,
      )
      map_iter_proto["next"] = JSValue::Object(map_iter_next)

      // Symbol.iterator -> this
      let map_iter_sym_iter_fn = Native(fn(_ctx, this_val, _args) { this_val })
      let map_iter_sym_iter = JSObject::new_function(
        name="[Symbol.iterator]",
        body=map_iter_sym_iter_fn,
        prototype=func_proto,
      )
      map_iter_proto["Symbol(Symbol.iterator)"] = JSValue::Object(
        map_iter_sym_iter,
      )

      // Symbol.toStringTag
      map_iter_proto["Symbol(Symbol.toStringTag)"] = JSValue::String(
        "Map Iterator",
      )
      let create_map_iter = fn(_ctx : Context, m : LinkedMap, kind : String) {
        let iter = JSObject::new(properties={}, prototype=map_iter_proto_val)
        iter["MapData"] = JSValue::Internal(
          MapIterator(m, Ref::new(m.head), kind),
        )
        JSValue::Object(iter)
      }

      // entries
      let entries_fn = JSObject::new_function(
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
      proto["entries"] = JSValue::Object(entries_fn)

      // keys
      let keys_fn = JSObject::new_function(
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
      proto["keys"] = JSValue::Object(keys_fn)

      // values
      let values_fn = JSObject::new_function(
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
      proto["values"] = JSValue::Object(values_fn)

      // forEach
      let for_each_fn = JSObject::new_function(
        name="forEach",
        params=["callbackfn"], // length 1
        body=Native(fn(ctx, this_val, args) {
          let callback = if args.length() > 0 { args[0] } else { Undefined }
          let this_arg = if args.length() > 1 { args[1] } else { Undefined }
          match this_val {
            Object({ properties: { "MapData": Internal(Map(m)), .. }, .. }) =>
              match callback {
                Object(f) => {
                  if not(f.is_callable) {
                    ctx.throw_type_error("Callback must be a function")
                    return Undefined
                  }
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
        }),
        prototype=func_proto,
      )
      proto["forEach"] = JSValue::Object(for_each_fn)

      // Symbol.iterator -> entries
      proto["Symbol(Symbol.iterator)"] = JSValue::Object(entries_fn)

      // Symbol.toStringTag
      proto["Symbol(Symbol.toStringTag)"] = JSValue::String("Map")
    }
    _ => ()
  }
}

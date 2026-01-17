///|
pub fn init_set_prototype(
  ctx : Context,
  set_proto : JSValue,
  func_proto : JSValue,
) -> Unit {
  match set_proto {
    Object(proto) => {
      proto["constructor"] = JSValue::Undefined // Will be set later

      // size getter
      let size_getter = JSObject::new_function(
        name="get size",
        body=Native(fn(ctx, this_val, _args) {
          match this_val {
            Object({ properties: { "SetData": Internal(Set(m)), .. }, .. }) =>
              JSValue::Number(m.length().to_double())
            _ => {
              ctx.throw_type_error(
                "Method Set.prototype.size called on incompatible receiver",
              )
              Undefined
            }
          }
        }),
        prototype=func_proto,
      )
      let size_accessor = JSInternal::Accessor(Some(size_getter), None)
      proto["size"] = JSValue::Internal(size_accessor)

      // add
      let add_fn = JSObject::new_function(
        name="add",
        params=["value"],
        body=Native(fn(ctx, this_val, args) {
          let value = if args.length() > 0 { args[0] } else { Undefined }
          match this_val {
            Object({ properties: { "SetData": Internal(Set(m)), .. }, .. }) => {
              let value = if value == Number(-0.0) {
                Number(0.0)
              } else {
                value
              }
              m.set(value, Undefined)
              this_val
            }
            _ => {
              ctx.throw_type_error(
                "Method Set.prototype.add called on incompatible receiver",
              )
              Undefined
            }
          }
        }),
        prototype=func_proto,
      )
      proto["add"] = JSValue::Object(add_fn)

      // has
      let has_fn = JSObject::new_function(
        name="has",
        params=["value"],
        body=Native(fn(ctx, this_val, args) {
          let value = if args.length() > 0 { args[0] } else { Undefined }
          match this_val {
            Object({ properties: { "SetData": Internal(Set(m)), .. }, .. }) => {
              let value = if value == Number(-0.0) {
                Number(0.0)
              } else {
                value
              }
              Boolean(m.contains(value))
            }
            _ => {
              ctx.throw_type_error(
                "Method Set.prototype.has called on incompatible receiver",
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
        params=["value"],
        body=Native(fn(ctx, this_val, args) {
          let value = if args.length() > 0 { args[0] } else { Undefined }
          match this_val {
            Object({ properties: { "SetData": Internal(Set(m)), .. }, .. }) => {
              let value = if value == Number(-0.0) {
                Number(0.0)
              } else {
                value
              }
              Boolean(
                if m.contains(value) {
                  m.remove(value)
                  true
                } else {
                  false
                },
              )
            }
            _ => {
              ctx.throw_type_error(
                "Method Set.prototype.delete called on incompatible receiver",
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
            Object({ properties: { "SetData": Internal(Set(m)), .. }, .. }) => {
              m.clear()
              Undefined
            }
            _ => {
              ctx.throw_type_error(
                "Method Set.prototype.clear called on incompatible receiver",
              )
              Undefined
            }
          }
        }),
        prototype=func_proto,
      )
      proto["clear"] = JSValue::Object(clear_fn)

      // Iterator Setup
      let iterator_proto = match ctx.scope.get("IteratorPrototype") {
        Some(p) => p
        None => func_proto
      }
      let set_iter_proto = JSObject::new(
        properties={},
        prototype=iterator_proto,
      )
      set_iter_proto["Symbol.toStringTag"] = JSValue::String("Set Iterator")
      let set_iter_proto_val = JSValue::Object(set_iter_proto)
      let set_iter_next_fn = Native(fn(ctx, this_val, _args) {
        match this_val {
          Object(
            {
              properties: {
                "SetData": Internal(SetIterator(_m, cursor, kind)),
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
                  "key" | "value" => entry.key
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
                    arr["1"] = entry.key // Set entries are [value, value]
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
              "Method Set Iterator.prototype.next called on incompatible receiver",
            )
            Undefined
          }
        }
      })
      let set_iter_next = JSObject::new_function(
        name="next",
        body=set_iter_next_fn,
        prototype=func_proto,
      )
      set_iter_proto["next"] = JSValue::Object(set_iter_next)

      // Symbol.iterator -> this
      let set_iter_sym_iter_fn = Native(fn(_ctx, this_val, _args) { this_val })
      let set_iter_sym_iter = JSObject::new_function(
        name="[Symbol.iterator]",
        body=set_iter_sym_iter_fn,
        prototype=func_proto,
      )
      set_iter_proto["Symbol(Symbol.iterator)"] = JSValue::Object(
        set_iter_sym_iter,
      )

      // Symbol.toStringTag
      set_iter_proto["Symbol(Symbol.toStringTag)"] = JSValue::String(
        "Set Iterator",
      )
      let create_set_iter = fn(_ctx : Context, m : LinkedMap, kind : String) {
        let iter = JSObject::new(properties={}, prototype=set_iter_proto_val)
        iter["SetData"] = JSValue::Internal(
          SetIterator(m, Ref::new(m.head), kind),
        )
        JSValue::Object(iter)
      }

      // entries
      let entries_fn = JSObject::new_function(
        name="entries",
        params=[],
        body=Native(fn(ctx, this_val, _args) {
          match this_val {
            Object({ properties: { "SetData": Internal(Set(m)), .. }, .. }) =>
              create_set_iter(ctx, m, "key+value")
            _ => {
              ctx.throw_type_error(
                "Method Set.prototype.entries called on incompatible receiver",
              )
              Undefined
            }
          }
        }),
        prototype=func_proto,
      )
      proto["entries"] = JSValue::Object(entries_fn)

      // values
      let values_fn = JSObject::new_function(
        name="values",
        params=[],
        body=Native(fn(ctx, this_val, _args) {
          match this_val {
            Object({ properties: { "SetData": Internal(Set(m)), .. }, .. }) =>
              create_set_iter(ctx, m, "value")
            _ => {
              ctx.throw_type_error(
                "Method Set.prototype.values called on incompatible receiver",
              )
              Undefined
            }
          }
        }),
        prototype=func_proto,
      )
      proto["values"] = JSValue::Object(values_fn)
      proto["keys"] = JSValue::Object(values_fn)

      // forEach
      let for_each_fn = JSObject::new_function(
        name="forEach",
        params=["callbackfn"], // length 1
        body=Native(fn(ctx, this_val, args) {
          let callback = if args.length() > 0 { args[0] } else { Undefined }
          let this_arg = if args.length() > 1 { args[1] } else { Undefined }
          match (this_val, callback) {
            (
              Object({ properties: { "SetData": Internal(Set(m)), .. }, .. }),
              Object(f),
            ) =>
              if f.is_callable {
                let mut current = m.head
                while true {
                  match current {
                    Some(entry) => {
                      ctx.invoke(f, this_arg, [entry.key, entry.key, this_val])
                      |> ignore
                      current = entry.next
                    }
                    None => break
                  }
                }
                Undefined
              } else {
                ctx.throw_type_error(
                  "Set.prototype.forEach callback must be a function",
                )
                Undefined
              }
            _ => {
              ctx.throw_type_error(
                "Method Set.prototype.forEach called on incompatible receiver",
              )
              Undefined
            }
          }
        }),
        prototype=func_proto,
      )
      proto["forEach"] = JSValue::Object(for_each_fn)

      // Symbol.iterator -> values
      proto["Symbol(Symbol.iterator)"] = JSValue::Object(values_fn)

      // Symbol.toStringTag
      proto["Symbol(Symbol.toStringTag)"] = JSValue::String("Set")
    }
    _ => ()
  }
}

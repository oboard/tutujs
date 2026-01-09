///|
pub fn init_array_prototype(array_proto_val : JSValue) -> Unit {
  match array_proto_val {
    Object(obj) => {
      // push
      let push_fn = Native(fn(_ctx, this_val, args) {
        match this_val {
          Object(
            { properties: { "length": Number(len), .. } as properties, .. }
          ) => {
            let mut len = len
            for arg in args {
              properties[len.to_string()] = arg
              len = len + 1.0
            }
            properties["length"] = Number(len)
            Number(len)
          }
          Object({ properties, .. }) => {
            let mut len = 0.0
            for arg in args {
              properties[len.to_string()] = arg
              len = len + 1.0
            }
            properties["length"] = Number(len)
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
          Object(
            { properties: { "length": Number(len), .. } as properties, .. }
          ) =>
            if len > 0.0 {
              let new_len = len - 1.0
              let key = new_len.to_string()
              let val = match properties.get(key) {
                Some(v) => v
                None => Undefined
              }
              properties.remove(key)
              properties["length"] = Number(new_len)
              val
            } else {
              properties["length"] = Number(0.0)
              Undefined
            }
          Object({ properties, .. }) => {
            properties["length"] = Number(0.0)
            Undefined
          }
          _ => Undefined
        }
      })
      let pop_obj = JSFunction::new(name="pop", body=pop_fn)
      obj["pop"] = JSValue::Function(pop_obj)

      // forEach
      let for_each_fn = Native(fn(ctx, this_val, args) raise EvalError {
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
            } else {
              raise EvalError::Throw(
                String("TypeError: forEach() expects a function as first argument"),
              )
            }
          _ => JSValue::Undefined
        }
      })
      let for_each_obj = JSFunction::new(name="forEach", body=for_each_fn)
      obj["forEach"] = JSValue::Function(for_each_obj)

      // map
      let map_fn = Native(fn(ctx, this_val, args) raise EvalError {
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
              let new_array = JSObject::{
                properties: {},
                prototype: Some(array_proto_val),
              }
              new_array["length"] = JSValue::Number(len)
              for i = 0; i < len.to_int(); i = i + 1 {
                let key = i.to_string()
                if properties.get(key) is Some(val) {
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
            } else {
              raise EvalError::Throw(
                String("TypeError: map() expects a function as first argument"),
              )
            }
          _ => JSValue::Undefined
        }
      })
      let map_obj = JSFunction::new(name="map", body=map_fn)
      obj["map"] = JSValue::Function(map_obj)

      // filter
      let filter_fn = Native(fn(ctx, this_val, args) raise EvalError {
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
              let new_array = JSObject::{
                properties: {},
                prototype: Some(array_proto_val),
              }
              let mut new_len = 0.0
              for i = 0; i < len.to_int(); i = i + 1 {
                let key = i.to_string()
                if properties.get(key) is Some(val) {
                  let predicate = ctx.invoke(callback, this_arg, [
                    val,
                    JSValue::Number(i.to_double()),
                    this_val,
                  ]) catch {
                    _ => JSValue::Undefined
                  }
                  if predicate.is_truthy() {
                    new_array[new_len.to_string()] = val
                    new_len = new_len + 1.0
                  }
                }
              }
              new_array["length"] = JSValue::Number(new_len)
              JSValue::Object(new_array)
            } else {
              raise EvalError::Throw(
                String("TypeError: filter() expects a function as first argument"),
              )
            }
          _ => JSValue::Undefined
        }
      })
      let filter_obj = JSFunction::new(name="filter", body=filter_fn)
      obj["filter"] = JSValue::Function(filter_obj)

      // reduce
      let reduce_fn = Native(fn(ctx, this_val, args) raise EvalError {
        match this_val {
          Object(
            { properties: { "length": Number(len), .. } as properties, .. }
          ) =>
            if args is [Function(callback), .. rest] {
              let len = len.to_int()
              let mut k = 0
              let mut accumulator = JSValue::Undefined

              // Initialize accumulator
              if rest is [initial_val, ..] {
                accumulator = initial_val
              } else {
                // No initial value, find first present element
                let mut k_present = false
                while k < len && not(k_present) {
                  let key = k.to_string()
                  if properties.get(key) is Some(val) {
                    accumulator = val
                    k_present = true
                  }
                  k = k + 1
                }
                if not(k_present) {
                  raise EvalError::Throw(
                    String("TypeError: Reduce of empty array with no initial value"),
                  )
                }
              }
              while k < len {
                let key = k.to_string()
                if properties.get(key) is Some(val) {
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
            } else {
              raise EvalError::Throw(
                String("TypeError: reduce() expects a function as first argument"),
              )
            }
          _ => JSValue::Undefined
        }
      })
      let reduce_obj = JSFunction::new(name="reduce", body=reduce_fn)
      obj["reduce"] = JSValue::Function(reduce_obj)

      // every
      let every_fn = Native(fn(ctx, this_val, args) raise EvalError {
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
              JSValue::Boolean(
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
                    if not(test_res.is_truthy()) {
                      break false
                    }
                  }
                } else {
                  true
                },
              )
            } else {
              raise EvalError::Throw(
                String("TypeError: every() expects a function as first argument"),
              )
            }
          _ => JSValue::Boolean(true)
        }
      })
      let every_obj = JSFunction::new(name="every", body=every_fn)
      obj["every"] = JSValue::Function(every_obj)

      // some
      let some_fn = Native(fn(ctx, this_val, args) raise EvalError {
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
              JSValue::Boolean(
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
                      break true
                    }
                  }
                } else {
                  false
                },
              )
            } else {
              raise EvalError::Throw(
                String("TypeError: some() expects a function as first argument"),
              )
            }
          _ => JSValue::Boolean(false) // Should be TypeError
        }
      })
      let some_obj = JSFunction::new(name="some", body=some_fn)
      obj["some"] = JSValue::Function(some_obj)
      // join
      let join_fn = Native(fn(_ctx, this_val, args) {
        match this_val {
          Object(
            { properties: { "length": Number(len), .. } as properties, .. }
          ) => {
            let separator = if args is [String(sep), ..] {
              sep.to_string()
            } else {
              ","
            }
            let mut result = ""
            for i = 0; i < len.to_int(); i = i + 1 {
              if i > 0 {
                result = result + separator
              }
              let key = i.to_string()
              match properties.get(key) {
                Some(Undefined) | Some(Null) | None => ()
                Some(val) => result = result + val.to_string()
              }
            }
            JSValue::String(result)
          }
          _ => JSValue::String("")
        }
      })
      let join_obj = JSFunction::new(name="join", body=join_fn)
      obj["join"] = JSValue::Function(join_obj)

      // toString
      let to_string_fn = Native(fn(ctx, this_val, _args) {
        match this_val.get_property("join") {
          Function(join_func) => {
            ctx.invoke(join_func, this_val, []) catch {
              _ => JSValue::String("[object Array]")
            }
          }
          _ => JSValue::String("[object Object]")
        }
      })
      let to_string_obj = JSFunction::new(name="toString", body=to_string_fn)
      obj["toString"] = JSValue::Function(to_string_obj)

      // indexOf
      let index_of_fn = Native(fn(_ctx, this_val, args) {
        match this_val {
          Object(
            { properties: { "length": Number(len), .. } as properties, .. }
          ) => {
            let search_element = if args is [val, ..] {
              val
            } else {
              JSValue::Undefined
            }
            let from_index = if args is [_, Number(n), ..] {
              n.to_int()
            } else {
              0
            }
            let len_int = len.to_int()
            let mut k = from_index
            if k < 0 {
              k = len_int + k
            }
            if k < 0 {
              k = 0
            }
            let mut result = -1.0
            let mut found = false
            while k < len_int && not(found) {
              let key = k.to_string()
              match properties.get(key) {
                Some(val) =>
                  if val.strict_equal(search_element) {
                    result = k.to_double()
                    found = true
                  }
                None => ()
              }
              k = k + 1
            }
            JSValue::Number(result)
          }
          _ => JSValue::Number(-1.0)
        }
      })
      let index_of_obj = JSFunction::new(name="indexOf", body=index_of_fn)
      obj["indexOf"] = JSValue::Function(index_of_obj)

      // shift
      let shift_fn = Native(fn(_ctx, this_val, _args) {
        match this_val {
          Object(
            { properties: { "length": Number(len), .. } as properties, .. }
          ) => {
            let len_int = len.to_int()
            if len_int == 0 {
              properties["length"] = Number(0.0)
              JSValue::Undefined
            } else {
              let first = match properties.get("0") {
                Some(v) => v
                None => Undefined
              }
              for i = 1; i < len_int; i = i + 1 {
                let from_key = i.to_string()
                let to_key = (i - 1).to_string()
                match properties.get(from_key) {
                  Some(val) => properties[to_key] = val
                  None => properties.remove(to_key)
                }
              }
              properties.remove((len_int - 1).to_string())
              properties["length"] = Number((len_int - 1).to_double())
              first
            }
          }
          _ => JSValue::Undefined
        }
      })
      let shift_obj = JSFunction::new(name="shift", body=shift_fn)
      obj["shift"] = JSValue::Function(shift_obj)

      // unshift
      let unshift_fn = Native(fn(_ctx, this_val, args) {
        match this_val {
          Object(
            { properties: { "length": Number(len), .. } as properties, .. }
          ) => {
            let len_int = len.to_int()
            let arg_count = args.length()
            if arg_count > 0 {
              for i = len_int - 1; i >= 0; i = i - 1 {
                let from_key = i.to_string()
                let to_key = (i + arg_count).to_string()
                match properties.get(from_key) {
                  Some(val) => properties[to_key] = val
                  None => properties.remove(to_key)
                }
              }
              for i = 0; i < arg_count; i = i + 1 {
                properties[i.to_string()] = args[i]
              }
              let new_len = (len_int + arg_count).to_double()
              properties["length"] = Number(new_len)
              Number(new_len)
            } else {
              Number(len)
            }
          }
          _ => Number(0.0)
        }
      })
      let unshift_obj = JSFunction::new(name="unshift", body=unshift_fn)
      obj["unshift"] = JSValue::Function(unshift_obj)

      // slice
      let slice_fn = Native(fn(_ctx, this_val, args) {
        match this_val {
          Object(
            { properties: { "length": Number(len), .. } as properties, .. }
          ) => {
            let len_int = len.to_int()
            let start = if args is [Number(n), ..] { n.to_int() } else { 0 }
            let end = if args is [_, Number(n), ..] {
              n.to_int()
            } else {
              len_int
            }
            let mut k = start
            if k < 0 {
              k = len_int + k
            }
            if k < 0 {
              k = 0
            }
            let mut end_k = end
            if end_k < 0 {
              end_k = len_int + end_k
            }
            if end_k < 0 {
              end_k = 0
            }
            if end_k > len_int {
              end_k = len_int
            }
            let new_array = JSObject::{
              properties: {},
              prototype: Some(array_proto_val),
            }
            let mut n = 0
            while k < end_k {
              let key = k.to_string()
              match properties.get(key) {
                Some(val) => new_array[n.to_string()] = val
                None => ()
              }
              k = k + 1
              n = n + 1
            }
            new_array["length"] = JSValue::Number(n.to_double())
            JSValue::Object(new_array)
          }
          _ => JSValue::Undefined
        }
      })
      let slice_obj = JSFunction::new(name="slice", body=slice_fn)
      obj["slice"] = JSValue::Function(slice_obj)

      // reverse
      let reverse_fn = Native(fn(_ctx, this_val, _args) {
        match this_val {
          Object(
            { properties: { "length": Number(len), .. } as properties, .. }
          ) => {
            let len_int = len.to_int()
            let middle = len_int / 2
            for i = 0; i < middle; i = i + 1 {
              let lower = i.to_string()
              let upper = (len_int - 1 - i).to_string()
              let lower_val = properties.get(lower)
              let upper_val = properties.get(upper)
              match (lower_val, upper_val) {
                (Some(vl), Some(vu)) => {
                  properties[lower] = vu
                  properties[upper] = vl
                }
                (Some(vl), None) => {
                  properties.remove(lower)
                  properties[upper] = vl
                }
                (None, Some(vu)) => {
                  properties[lower] = vu
                  properties.remove(upper)
                }
                (None, None) => ()
              }
            }
            this_val
          }
          _ => this_val
        }
      })
      let reverse_obj = JSFunction::new(name="reverse", body=reverse_fn)
      obj["reverse"] = JSValue::Function(reverse_obj)

      // sort
      let sort_fn = Native(fn(ctx, this_val, args) {
        match this_val {
          Object(
            { properties: { "length": Number(len), .. } as properties, .. }
          ) => {
            let len_int = len.to_int()
            let arr = []
            for i = 0; i < len_int; i = i + 1 {
              let key = i.to_string()
              match properties.get(key) {
                Some(val) => arr.push(val)
                None => arr.push(JSValue::Undefined)
              }
            }
            let compare_fn = if args is [Function(f), ..] {
              Some(f)
            } else {
              None
            }
            arr.sort_by(fn(a, b) {
              if a == JSValue::Undefined && b == JSValue::Undefined {
                return 0
              }
              if a == JSValue::Undefined {
                return 1
              }
              if b == JSValue::Undefined {
                return -1
              }
              match compare_fn {
                Some(f) => {
                  let res = ctx.invoke(f, JSValue::Undefined, [a, b]) catch {
                    _ => JSValue::Number(0.0)
                  }
                  res.to_number().to_int()
                }
                None => {
                  let sa = a.to_string()
                  let sb = b.to_string()
                  if sa < sb {
                    -1
                  } else if sa > sb {
                    1
                  } else {
                    0
                  }
                }
              }
            })
            for i = 0; i < len_int; i = i + 1 {
              properties[i.to_string()] = arr[i]
            }
            this_val
          }
          _ => this_val
        }
      })
      let sort_obj = JSFunction::new(name="sort", body=sort_fn)
      obj["sort"] = JSValue::Function(sort_obj)

      // splice
      let splice_fn = Native(fn(_ctx, this_val, args) {
        match this_val {
          Object(
            { properties: { "length": Number(len), .. } as properties, .. }
          ) => {
            let len_int = len.to_int()
            let start_arg = if args is [val, ..] {
              val
            } else {
              JSValue::Undefined
            }
            let start = match start_arg {
              Number(n) => n.to_int()
              _ => 0
            }
            let mut actual_start = start
            if actual_start < 0 {
              actual_start = len_int + actual_start
            }
            if actual_start < 0 {
              actual_start = 0
            }
            if actual_start > len_int {
              actual_start = len_int
            }
            let delete_count_arg = if args.length() >= 2 {
              Some(args[1])
            } else {
              None
            }
            let delete_count = match delete_count_arg {
              Some(Number(n)) => {
                let n = n.to_int()
                if n < 0 {
                  0
                } else if n > len_int - actual_start {
                  len_int - actual_start
                } else {
                  n
                }
              }
              Some(_) => 0
              None => len_int - actual_start
            }
            let items = []
            if args.length() > 2 {
              for i = 2; i < args.length(); i = i + 1 {
                items.push(args[i])
              }
            }
            let deleted_elements = JSObject::{
              properties: {},
              prototype: Some(array_proto_val),
            }
            for k = 0; k < delete_count; k = k + 1 {
              let from = (actual_start + k).to_string()
              match properties.get(from) {
                Some(val) => deleted_elements[k.to_string()] = val
                None => ()
              }
            }
            deleted_elements["length"] = JSValue::Number(
              delete_count.to_double(),
            )
            let item_count = items.length()
            if item_count < delete_count {
              for k = actual_start; k < len_int - delete_count; k = k + 1 {
                let from = (k + delete_count).to_string()
                let to = (k + item_count).to_string()
                match properties.get(from) {
                  Some(val) => properties[to] = val
                  None => properties.remove(to)
                }
              }
              for k = len_int - delete_count + item_count
                  k < len_int
                  k = k + 1 {
                properties.remove(k.to_string())
              }
            } else if item_count > delete_count {
              let tail_len = len_int - (actual_start + delete_count)
              for k = tail_len - 1; k >= 0; k = k - 1 {
                let from_idx = actual_start + delete_count + k
                let to_idx = actual_start + item_count + k
                let from = from_idx.to_string()
                let to = to_idx.to_string()
                match properties.get(from) {
                  Some(val) => properties[to] = val
                  None => properties.remove(to)
                }
              }
            }
            for k = 0; k < item_count; k = k + 1 {
              properties[(actual_start + k).to_string()] = items[k]
            }
            let new_len = len_int - delete_count + item_count
            properties["length"] = JSValue::Number(new_len.to_double())
            JSValue::Object(deleted_elements)
          }
          _ => JSValue::Undefined
        }
      })
      let splice_obj = JSFunction::new(name="splice", body=splice_fn)
      obj["splice"] = JSValue::Function(splice_obj)

      // values
      let values_fn = Native(fn(_ctx, this_val, _args) {
        let index_box = [0]
        let next_fn = Native(fn(_ctx, _iter_this, _iter_args) {
          let idx = index_box[0]
          match this_val {
            Object({ properties, .. }) => {
              let len = match properties.get("length") {
                Some(Number(n)) => n.to_int()
                _ => 0
              }
              if idx < len {
                let val = match properties.get(idx.to_string()) {
                  Some(v) => v
                  None => JSValue::Undefined
                }
                index_box[0] = idx + 1
                let res = JSObject::{ properties: {}, prototype: None }
                res["value"] = val
                res["done"] = JSValue::Boolean(false)
                JSValue::Object(res)
              } else {
                let res = JSObject::{ properties: {}, prototype: None }
                res["value"] = JSValue::Undefined
                res["done"] = JSValue::Boolean(true)
                JSValue::Object(res)
              }
            }
            _ => {
              let res = JSObject::{ properties: {}, prototype: None }
              res["value"] = JSValue::Undefined
              res["done"] = JSValue::Boolean(true)
              JSValue::Object(res)
            }
          }
        })
        let iter_obj = JSObject::{ properties: {}, prototype: None }
        let next_func_obj = JSFunction::new(name="next", body=next_fn)
        iter_obj["next"] = JSValue::Function(next_func_obj)
        JSValue::Object(iter_obj)
      })
      let values_obj = JSFunction::new(name="values", body=values_fn)
      obj["values"] = JSValue::Function(values_obj)
    }
    _ => ()
  }
}

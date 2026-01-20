///|
pub fn init_array_prototype(
  array_proto_val : JSValue,
  func_proto : JSValue,
) -> Unit {
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
      let push_obj = JSObject::new_function(
        name="push",
        body=push_fn,
        prototype=func_proto,
      )
      obj["push"] = JSValue::Object(push_obj)

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
      let pop_obj = JSObject::new_function(
        name="pop",
        body=pop_fn,
        prototype=func_proto,
      )
      obj["pop"] = JSValue::Object(pop_obj)

      // forEach
      let for_each_fn = Native(fn(ctx, this_val, args) raise EvalError {
        match this_val {
          Object(
            { properties: { "length": Number(len), .. } as properties, .. }
          ) =>
            if args.0 is [Object(callback), .. rest] {
              if not(callback.is_callable) {
                raise EvalError::Throw(
                  String(
                    "TypeError: forEach() expects a function as first argument",
                  ),
                )
              }
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
                String(
                  "TypeError: forEach() expects a function as first argument",
                ),
              )
            }
          _ => JSValue::Undefined
        }
      })
      let for_each_obj = JSObject::new_function(
        name="forEach",
        body=for_each_fn,
      )
      obj["forEach"] = JSValue::Object(for_each_obj)

      // map
      let map_fn = Native(fn(ctx, this_val, args) raise EvalError {
        match this_val {
          Object(
            { properties: { "length": Number(len), .. } as properties, .. }
          ) =>
            if args.0 is [Object(callback), .. rest] {
              if not(callback.is_callable) {
                raise EvalError::Throw(
                  String(
                    "TypeError: map() expects a function as first argument",
                  ),
                )
              }
              let this_arg = if rest is [this_arg, ..] {
                this_arg
              } else {
                JSValue::Undefined
              }
              let new_array = JSObject::new(
                properties={},
                prototype=array_proto_val,
              )
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
      let map_obj = JSObject::new_function(
        name="map",
        body=map_fn,
        prototype=func_proto,
      )
      obj["map"] = JSValue::Object(map_obj)

      // filter
      let filter_fn = Native(fn(ctx, this_val, args) raise EvalError {
        match this_val {
          Object(
            { properties: { "length": Number(len), .. } as properties, .. }
          ) =>
            if args.0 is [Object(callback), .. rest] {
              if not(callback.is_callable) {
                raise EvalError::Throw(
                  String(
                    "TypeError: every() expects a function as first argument",
                  ),
                )
              }
              let this_arg = if rest is [this_arg, ..] {
                this_arg
              } else {
                JSValue::Undefined
              }
              let new_array = JSObject::new(
                properties={},
                prototype=array_proto_val,
              )
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
                String(
                  "TypeError: filter() expects a function as first argument",
                ),
              )
            }
          _ => JSValue::Undefined
        }
      })
      let filter_obj = JSObject::new_function(
        name="filter",
        body=filter_fn,
        prototype=func_proto,
      )
      obj["filter"] = JSValue::Object(filter_obj)

      // reduce
      let reduce_fn = Native(fn(ctx, this_val, args) raise EvalError {
        match this_val {
          Object(
            { properties: { "length": Number(len), .. } as properties, .. }
          ) =>
            if args.0 is [Object(callback), .. rest] {
              if not(callback.is_callable) {
                raise EvalError::Throw(
                  String(
                    "TypeError: reduce() expects a function as first argument",
                  ),
                )
              }
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
                    String(
                      "TypeError: Reduce of empty array with no initial value",
                    ),
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
                String(
                  "TypeError: reduce() expects a function as first argument",
                ),
              )
            }
          _ => JSValue::Undefined
        }
      })
      let reduce_obj = JSObject::new_function(
        name="reduce",
        body=reduce_fn,
        prototype=func_proto,
      )
      obj["reduce"] = JSValue::Object(reduce_obj)

      // every
      let every_fn = Native(fn(ctx, this_val, args) raise EvalError {
        match this_val {
          Object(
            { properties: { "length": Number(len), .. } as properties, .. }
          ) =>
            if args.0 is [Object(callback), .. rest] {
              if not(callback.is_callable) {
                raise EvalError::Throw(
                  String(
                    "TypeError: some() expects a function as first argument",
                  ),
                )
              }
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
                String(
                  "TypeError: every() expects a function as first argument",
                ),
              )
            }
          _ => JSValue::Boolean(true)
        }
      })
      let every_obj = JSObject::new_function(
        name="every",
        body=every_fn,
        prototype=func_proto,
      )
      obj["every"] = JSValue::Object(every_obj)

      // some
      let some_fn = Native(fn(ctx, this_val, args) raise EvalError {
        match this_val {
          Object(
            { properties: { "length": Number(len), .. } as properties, .. }
          ) =>
            if args.0 is [Object(callback), .. rest] {
              if not(callback.is_callable) {
                raise EvalError::Throw(
                  String(
                    "TypeError: some() expects a function as first argument",
                  ),
                )
              }
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
      let some_obj = JSObject::new_function(
        name="some",
        body=some_fn,
        prototype=func_proto,
      )
      obj["some"] = JSValue::Object(some_obj)
      // join
      let join_fn = Native(fn(_ctx, this_val, args) {
        match this_val {
          Object(
            { properties: { "length": Number(len), .. } as properties, .. }
          ) => {
            let separator = if args.0 is [String(sep), ..] {
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
      let join_obj = JSObject::new_function(
        name="join",
        body=join_fn,
        prototype=func_proto,
      )
      obj["join"] = JSValue::Object(join_obj)

      // toString
      let to_string_fn = Native(fn(ctx, this_val, _args) {
        match this_val.get_property("join") {
          Object(join_func) =>
            if join_func.is_callable {
              ctx.invoke(join_func, this_val, []) catch {
                _ => JSValue::String("[object Array]")
              }
            } else {
              JSValue::String("[object Object]")
            }
          _ => JSValue::String("[object Object]")
        }
      })
      let to_string_obj = JSObject::new_function(
        name="toString",
        body=to_string_fn,
        prototype=func_proto,
      )
      obj["toString"] = JSValue::Object(to_string_obj)

      // indexOf
      let index_of_fn = Native(fn(_ctx, this_val, args) {
        match this_val {
          Object(
            { properties: { "length": Number(len), .. } as properties, .. }
          ) => {
            let search_element = if args.0 is [val, ..] {
              val
            } else {
              JSValue::Undefined
            }
            let from_index = if args.0 is [_, Number(n), ..] {
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
      let index_of_obj = JSObject::new_function(
        name="indexOf",
        body=index_of_fn,
        prototype=func_proto,
      )
      obj["indexOf"] = JSValue::Object(index_of_obj)

      // flatMap
      let flat_map_fn = Native(fn(ctx, this_val, args) raise EvalError {
        match this_val {
          Object(
            { properties: { "length": Number(len), .. } as properties, .. }
          ) =>
            if args.0 is [Object(callback), .. rest] {
              if not(callback.is_callable) {
                raise EvalError::Throw(
                  String(
                    "TypeError: flatMap() expects a function as first argument",
                  ),
                )
              }
              let this_arg = if rest is [this_arg, ..] {
                this_arg
              } else {
                JSValue::Undefined
              }

              // First, map each element using the callback
              let mapped_results : Array[JSValue] = []
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
                  mapped_results.push(mapped_val)
                }
              }

              // Then, flatten the results by one level
              let flattened_results : Array[JSValue] = []
              for mapped_val in mapped_results {
                match mapped_val {
                  Object(arr_obj) =>
                    // Check if it's array-like (has length property)
                    match arr_obj.properties.get("length") {
                      Some(Number(arr_len)) =>
                        // It's array-like, flatten it
                        for j = 0; j < arr_len.to_int(); j = j + 1 {
                          let arr_key = j.to_string()
                          match arr_obj.properties.get(arr_key) {
                            Some(element) => flattened_results.push(element)
                            None => ()
                          }
                        }
                      _ =>
                        // Not array-like, add as single element
                        flattened_results.push(mapped_val)
                    }
                  _ =>
                    // Not an object, add as single element
                    flattened_results.push(mapped_val)
                }
              }

              // Create the result array
              let proto = match ctx.resolve("Array") {
                Object(f) => f.properties.get("prototype")
                _ => None
              }
              let result_obj = match proto {
                Some(p) => JSObject::new(properties={}, prototype=p)
                None => JSObject::new(properties={})
              }

              // Set the flattened elements
              for k = 0; k < flattened_results.length(); k = k + 1 {
                result_obj[k.to_string()] = flattened_results[k]
              }
              result_obj["length"] = JSValue::Number(
                flattened_results.length().to_double(),
              )
              JSValue::Object(result_obj)
            } else {
              raise EvalError::Throw(
                String(
                  "TypeError: flatMap() expects a function as first argument",
                ),
              )
            }
          _ => JSValue::Undefined
        }
      })
      let flat_map_obj = JSObject::new_function(
        name="flatMap",
        body=flat_map_fn,
        prototype=func_proto,
      )
      obj["flatMap"] = JSValue::Object(flat_map_obj)

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
      let shift_obj = JSObject::new_function(
        name="shift",
        body=shift_fn,
        prototype=func_proto,
      )
      obj["shift"] = JSValue::Object(shift_obj)

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
      let unshift_obj = JSObject::new_function(
        name="unshift",
        body=unshift_fn,
        prototype=func_proto,
      )
      obj["unshift"] = JSValue::Object(unshift_obj)

      // slice
      let slice_fn = Native(fn(_ctx, this_val, args) {
        match this_val {
          Object(
            { properties: { "length": Number(len), .. } as properties, .. }
          ) => {
            let len_int = len.to_int()
            let start = if args.0 is [Number(n), ..] { n.to_int() } else { 0 }
            let end = if args.0 is [_, Number(n), ..] {
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
            let new_array = JSObject::new(
              properties={},
              prototype=array_proto_val,
            )
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
      let slice_obj = JSObject::new_function(
        name="slice",
        body=slice_fn,
        prototype=func_proto,
      )
      obj["slice"] = JSValue::Object(slice_obj)

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
      let reverse_obj = JSObject::new_function(
        name="reverse",
        body=reverse_fn,
        prototype=func_proto,
      )
      obj["reverse"] = JSValue::Object(reverse_obj)

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
            let compare_fn = if args[0]
              is Object({ is_callable: true, .. } as f) {
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
                  match res {
                    Number(n) => n.to_int()
                    _ => 0
                  }
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
              let key = i.to_string()
              if arr[i] == JSValue::Undefined {
                properties.remove(key)
              } else {
                properties[key] = arr[i]
              }
            }
            this_val
          }
          _ => this_val
        }
      })
      let sort_obj = JSObject::new_function(
        name="sort",
        body=sort_fn,
        prototype=func_proto,
      )
      obj["sort"] = JSValue::Object(sort_obj)

      // splice
      let splice_fn = Native(fn(_ctx, this_val, args) {
        match this_val {
          Object(
            { properties: { "length": Number(len), .. } as properties, .. }
          ) => {
            let len_int = len.to_int()
            let start = if args.0 is [Number(n), ..] { n.to_int() } else { 0 }
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
            let delete_count = if args.0 is [_, Number(n), ..] {
              n.to_int()
            } else if args.length() >= 2 {
              0 // Should handle non-number
            } else {
              len_int - actual_start
            }
            let mut delete_count = delete_count
            if delete_count < 0 {
              delete_count = 0
            }
            if delete_count > len_int - actual_start {
              delete_count = len_int - actual_start
            }
            let items = if args.length() > 2 {
              let items = []
              for i = 2; i < args.length(); i = i + 1 {
                items.push(args[i])
              }
              items
            } else {
              []
            }
            let deleted_elements = JSObject::new(
              properties={},
              prototype=array_proto_val,
            )
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
      let splice_obj = JSObject::new_function(
        name="splice",
        body=splice_fn,
        prototype=func_proto,
      )
      obj["splice"] = JSValue::Object(splice_obj)

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
                let res = JSObject::new(properties={})
                res["value"] = val
                res["done"] = JSValue::Boolean(false)
                JSValue::Object(res)
              } else {
                let res = JSObject::new(properties={})
                res["value"] = JSValue::Undefined
                res["done"] = JSValue::Boolean(true)
                JSValue::Object(res)
              }
            }
            _ => {
              let res = JSObject::new(properties={})
              res["value"] = JSValue::Undefined
              res["done"] = JSValue::Boolean(true)
              JSValue::Object(res)
            }
          }
        })
        let iter_obj = JSObject::new(properties={})
        let next_func_obj = JSObject::new_function(
          name="next",
          body=next_fn,
          prototype=func_proto,
        )
        iter_obj["next"] = JSValue::Object(next_func_obj)
        JSValue::Object(iter_obj)
      })
      let values_obj = JSObject::new_function(
        name="values",
        body=values_fn,
        prototype=func_proto,
      )
      obj["values"] = JSValue::Object(values_obj)
      obj["Symbol(Symbol.iterator)"] = JSValue::Object(values_obj)

      // keys
      let keys_fn = Native(fn(_ctx, this_val, _args) {
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
                index_box[0] = idx + 1
                let res = JSObject::new(properties={})
                res["value"] = JSValue::Number(idx.to_double())
                res["done"] = JSValue::Boolean(false)
                JSValue::Object(res)
              } else {
                let res = JSObject::new(properties={})
                res["value"] = JSValue::Undefined
                res["done"] = JSValue::Boolean(true)
                JSValue::Object(res)
              }
            }
            _ => {
              let res = JSObject::new(properties={})
              res["value"] = JSValue::Undefined
              res["done"] = JSValue::Boolean(true)
              JSValue::Object(res)
            }
          }
        })
        let iter_obj = JSObject::new(properties={})
        let next_func_obj = JSObject::new_function(
          name="next",
          body=next_fn,
          prototype=func_proto,
        )
        iter_obj["next"] = JSValue::Object(next_func_obj)
        JSValue::Object(iter_obj)
      })
      let keys_obj = JSObject::new_function(
        name="keys",
        body=keys_fn,
        prototype=func_proto,
      )
      obj["keys"] = JSValue::Object(keys_obj)

      // entries
      let entries_fn = Native(fn(_ctx, this_val, _args) {
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

                // Create [index, value] array
                let entry_arr = JSObject::new(
                  properties={},
                  prototype=array_proto_val,
                )
                entry_arr["0"] = JSValue::Number(idx.to_double())
                entry_arr["1"] = val
                entry_arr["length"] = JSValue::Number(2.0)
                let res = JSObject::new(properties={})
                res["value"] = JSValue::Object(entry_arr)
                res["done"] = JSValue::Boolean(false)
                JSValue::Object(res)
              } else {
                let res = JSObject::new(properties={})
                res["value"] = JSValue::Undefined
                res["done"] = JSValue::Boolean(true)
                JSValue::Object(res)
              }
            }
            _ => {
              let res = JSObject::new(properties={})
              res["value"] = JSValue::Undefined
              res["done"] = JSValue::Boolean(true)
              JSValue::Object(res)
            }
          }
        })
        let iter_obj = JSObject::new(properties={})
        let next_func_obj = JSObject::new_function(
          name="next",
          body=next_fn,
          prototype=func_proto,
        )
        iter_obj["next"] = JSValue::Object(next_func_obj)
        JSValue::Object(iter_obj)
      })
      let entries_obj = JSObject::new_function(
        name="entries",
        body=entries_fn,
        prototype=func_proto,
      )
      obj["entries"] = JSValue::Object(entries_obj)
    }
    _ => ()
  }
}

///|
pub fn init_array_constructor(array_ctor : JSValue) -> Unit {
  // println("DEBUG: init_array_constructor called")
  match array_ctor {
    Object(obj) => {
      let func_proto = obj.prototype
      let func_proto_val = func_proto.unwrap_or(JSValue::Undefined)
      // isArray
      let is_array_fn = Native(fn(_ctx, _this_val, args) {
        JSValue::Boolean(
          match args.0 {
            [Object({ properties: { "length": Number(_), .. }, .. }), ..] =>
              true
            _ => false
          },
        )
      })
      let is_array_obj = JSObject::new_function(
        name="isArray",
        body=is_array_fn,
        prototype=func_proto_val,
      )
      obj["isArray"] = JSValue::Object(is_array_obj)

      // from
      let from_fn = Native(fn(ctx, this_val, args) raise EvalError {
        let items = args[0]
        let map_fn : JSObject? = if args.0 is [_, arg_map_fn, ..] {
          match arg_map_fn {
            Object(f) =>
              if f.is_callable {
                Some(f)
              } else {
                let msg = "Array.from map function must be callable"
                let err = match ctx.resolve("TypeError") {
                  Object(f) =>
                    if f.is_callable {
                      ctx.invoke(f, JSValue::Undefined, [JSValue::String(msg)]) catch {
                        _ => JSValue::String("TypeError: " + msg)
                      }
                    } else {
                      JSValue::String("TypeError: " + msg)
                    }
                  _ => JSValue::String("TypeError: " + msg)
                }
                raise EvalError::Throw(err)
              }
            Undefined => None
            _ => {
              let msg = "Array.from map function must be callable"
              let err = match ctx.resolve("TypeError") {
                Object(f) =>
                  if f.is_callable {
                    ctx.invoke(f, JSValue::Undefined, [JSValue::String(msg)]) catch {
                      _ => JSValue::String("TypeError: " + msg)
                    }
                  } else {
                    JSValue::String("TypeError: " + msg)
                  }
                _ => JSValue::String("TypeError: " + msg)
              }
              raise EvalError::Throw(err)
            }
          }
        } else {
          None
        }
        let this_arg = args[2]
        match items {
          Null | Undefined =>
            raise EvalError::Throw(
              String(
                "TypeError: Array.from requires an array-like object - cannot convert null or undefined to object",
              ),
            )
          _ => ()
        }

        // Check for iterator
        let iterator_method = match ctx.resolve("Symbol") {
          Object(f) =>
            match f.properties.get("iterator") {
              Some(sym) => items.get_property(sym.to_property_key())
              None => JSValue::Undefined
            }
          _ => JSValue::Undefined
        }
        if iterator_method is Object(iter_fn) && iter_fn.is_callable {
          let iterator = ctx.invoke(iter_fn, items, []) catch { e => raise e }
          // Check if iterator is an object as required by spec
          match iterator {
            Object(_) => ()
            _ =>
              raise EvalError::Throw(
                JSValue::String("TypeError: Iterator result must be an object"),
              )
          }
          let new_array_val = match this_val {
            Object(ctor) => {
              let is_ctor = match ctor.call_info {
                Some({ is_constructor: true, .. }) => true
                _ => false
              }
              if is_ctor {
                let proto = match ctor.properties.get("prototype") {
                  Some(p) => p
                  None =>
                    match ctx.resolve("Object") {
                      Object(f) => f.properties.get("prototype").unwrap()
                      _ => JSValue::Undefined
                    }
                }
                let obj = JSObject::new(properties={}, prototype=proto)
                let this_obj = JSValue::Object(obj)
                let res = ctx.invoke(ctor, this_obj, []) catch { _ => this_obj }
                match res {
                  Object(_) => res
                  _ => this_obj
                }
              } else {
                let proto = match ctx.resolve("Array") {
                  Object(f) => f.properties.get("prototype")
                  _ => None
                }
                JSValue::Object(
                  match proto {
                    Some(p) => JSObject::new(properties={}, prototype=p)
                    None => JSObject::new(properties={})
                  },
                )
              }
            }
            _ => {
              let proto = match ctx.resolve("Array") {
                Object(f) => f.properties.get("prototype")
                _ => None
              }
              JSValue::Object(
                match proto {
                  Some(p) => JSObject::new(properties={}, prototype=p)
                  None => JSObject::new(properties={})
                },
              )
            }
          }
          let new_array_obj = match new_array_val {
            Object(o) => o
            _ =>
              raise EvalError::Throw(
                JSValue::String(
                  "TypeError: Array.from result must be an object",
                ),
              )
          }
          let mut k = 0
          while true {
            let next_method = iterator.get_property("next")
            let next_result = match next_method {
              Object(f) =>
                if f.is_callable {
                  ctx.invoke(f, iterator, []) catch {
                    e => raise e
                  }
                } else {
                  raise EvalError::Throw(
                    JSValue::String("TypeError: Iterator next must be callable"),
                  )
                }
              _ =>
                raise EvalError::Throw(
                  JSValue::String("TypeError: Iterator next must be callable"),
                )
            }
            match next_result {
              Object(_) => ()
              _ =>
                raise EvalError::Throw(
                  JSValue::String(
                    "TypeError: Iterator result must be an object",
                  ),
                )
            }
            let done = next_result.get_property("done").is_truthy()
            if done {
              new_array_obj["length"] = JSValue::Number(k.to_double())
              break
            }
            let value = next_result.get_property("value")
            let mapped_val = match map_fn {
              Some(f) =>
                ctx.invoke(f, this_arg, [value, JSValue::Number(k.to_double())]) catch {
                  e => raise e
                }
              None => value
            }

            // CreateDataPropertyOrThrow
            let key = k.to_string()
            let extensible = match
              new_array_obj.properties.get("__internal_extensible__") {
              Some(Boolean(false)) => false
              _ => true
            }
            if not(extensible) && not(new_array_obj.properties.contains(key)) {
              raise EvalError::Throw(
                JSValue::String(
                  "TypeError: Cannot define property on non-extensible object",
                ),
              )
            }
            new_array_obj[key] = mapped_val
            k = k + 1
          }
          return new_array_val
        }
        let len_val = items.get_property("length")
        let len = match len_val {
          Number(n) => n.to_int()
          _ => 0
        }
        let len = if len < 0 { 0 } else { len }

        // Construct new_array
        let new_array_val = match this_val {
          Object(ctor) => {
            let is_ctor = match ctor.call_info {
              Some({ is_constructor: true, .. }) => true
              _ => false
            }
            if is_ctor {
              // Construct(C, [len])
              let proto = match ctor.properties.get("prototype") {
                Some(p) => p
                None =>
                  match ctx.resolve("Object") {
                    Object(f) => f.properties.get("prototype").unwrap()
                    _ => JSValue::Undefined
                  }
              }
              let obj = JSObject::new(properties={}, prototype=proto)
              let this_obj = JSValue::Object(obj)
              let res = ctx.invoke(ctor, this_obj, [
                JSValue::Number(len.to_double()),
              ]) catch {
                EvalError::Return(v) => v // Handle return from constructor if needed? invoke handles it.
                e => raise e
              }
              match res {
                Object(_) => res
                _ => this_obj
              }
            } else {
              // ArrayCreate(len)
              let proto = match ctx.resolve("Array") {
                Object(f) => f.properties.get("prototype")
                _ => None
              }
              let obj = match proto {
                Some(p) => JSObject::new(properties={}, prototype=p)
                None => JSObject::new(properties={})
              }
              obj["length"] = JSValue::Number(len.to_double())
              JSValue::Object(obj)
            }
          }
          _ => {
            // ArrayCreate(len)
            let proto = match ctx.resolve("Array") {
              Object(f) => f.properties.get("prototype")
              _ => None
            }
            let obj = match proto {
              Some(p) => JSObject::new(properties={}, prototype=p)
              None => JSObject::new(properties={})
            }
            obj["length"] = JSValue::Number(len.to_double())
            JSValue::Object(obj)
          }
        }
        let new_array_obj = match new_array_val {
          Object(o) => o
          _ =>
            raise EvalError::Throw(
              JSValue::String("TypeError: Array.from result must be an object"),
            )
        }
        for k = 0; k < len; k = k + 1 {
          let key = k.to_string()
          let val = items.get_property(key)
          // println("DEBUG: Array.from k=" + key + " val=" + val.to_string())
          let mapped_val = match map_fn {
            Some(f) =>
              ctx.invoke(f, this_arg, [val, JSValue::Number(k.to_double())]) catch {
                _ => JSValue::Undefined
              }
            None => val
          }

          // CreateDataPropertyOrThrow logic
          let extensible = match
            new_array_obj.properties.get("__internal_extensible__") {
            Some(Boolean(false)) => false
            _ => true
          }
          // println("DEBUG: Array.from key=" + key + " extensible=" + extensible.to_string())
          if not(extensible) && not(new_array_obj.properties.contains(key)) {
            let type_error = match ctx.resolve("TypeError") {
              Object(f) =>
                if f.is_callable {
                  ctx.invoke(f, JSValue::Undefined, [
                    JSValue::String(
                      "Cannot define property on non-extensible object",
                    ),
                  ]) catch {
                    _ =>
                      JSValue::String(
                        "TypeError: Cannot define property on non-extensible object",
                      )
                  }
                } else {
                  JSValue::String(
                    "TypeError: Cannot define property on non-extensible object",
                  )
                }
              _ =>
                JSValue::String(
                  "TypeError: Cannot define property on non-extensible object",
                )
            }
            raise EvalError::Throw(type_error)
          }
          new_array_obj[key] = mapped_val
        }

        // CreateDataPropertyOrThrow logic for length
        let extensible = match
          new_array_obj.properties.get("__internal_extensible__") {
          Some(Boolean(false)) => false
          _ => true
        }
        if not(extensible) && not(new_array_obj.properties.contains("length")) {
          let type_error = match ctx.resolve("TypeError") {
            Object(f) =>
              if f.is_callable {
                ctx.invoke(f, JSValue::Undefined, [
                  JSValue::String(
                    "Cannot define property 'length' on non-extensible object",
                  ),
                ]) catch {
                  _ =>
                    JSValue::String(
                      "TypeError: Cannot define property 'length' on non-extensible object",
                    )
                }
              } else {
                JSValue::String(
                  "TypeError: Cannot define property 'length' on non-extensible object",
                )
              }
            _ =>
              JSValue::String(
                "TypeError: Cannot define property 'length' on non-extensible object",
              )
          }
          raise EvalError::Throw(type_error)
        }
        new_array_obj["length"] = JSValue::Number(len.to_double())
        new_array_val
      })
      let from_obj = JSObject::new_function(
        name="from",
        body=from_fn,
        prototype=func_proto_val,
      )
      obj["from"] = JSValue::Object(from_obj)
    }
    _ => ()
  }
}

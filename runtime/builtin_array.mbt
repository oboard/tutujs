///|
pub fn init_array_prototype(array_proto_val : JSValue) -> Unit {
  match array_proto_val {
    Object(obj) => {
      // push
      let push_fn = Native(fn(_ctx, this_val, args) {
        match this_val {
          Object(o) => {
            let mut len = match o.properties.get("length") {
              Some(Number(n)) => n
              _ => 0.0
            }
            for arg in args {
              o.properties.set(len.to_string(), arg)
              len = len + 1.0
            }
            o.properties.set("length", Number(len))
            Number(len)
          }
          _ => Number(0.0) // Should throw TypeError?
        }
      })
      let push_obj = JSFunction::new(name="push", body=push_fn)
      obj.properties.set("push", JSValue::Function(push_obj))

      // pop
      let pop_fn = Native(fn(_ctx, this_val, _args) {
        match this_val {
          Object(o) => {
            let len = match o.properties.get("length") {
              Some(Number(n)) => n
              _ => 0.0
            }
            if len > 0.0 {
              let new_len = len - 1.0
              let val = o.properties.get(new_len.to_string())
              o.properties.remove(new_len.to_string())
              o.properties.set("length", Number(new_len))
              val.unwrap_or(Undefined)
            } else {
              o.properties.set("length", Number(0.0))
              Undefined
            }
          }
          _ => Undefined
        }
      })
      let pop_obj = JSFunction::new(name="pop", body=pop_fn)
      obj.properties.set("pop", JSValue::Function(pop_obj))
    }
    _ => ()
  }
}

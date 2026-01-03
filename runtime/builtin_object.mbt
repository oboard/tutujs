///|
pub fn init_object_prototype(object_proto_val : JSValue) -> Unit {
  match object_proto_val {
    Object(obj) => {
      // toString
      let to_string_fn = Native(fn(_ctx, this_val, _args) {
        JSValue::String(
          match this_val {
            Object(_) => "[object Object]"
            Function(_) => "[object Function]" // Functions are objects too but usually have specific tag
            String(_) => "[object String]" // Boxed string? No, primitive string. 
            // Primitive values don't have methods unless boxed. 
            // But if I call "str".toString(), it boxes it.
            // In my eval, MemberExpression on primitive boxes it? 
            // Currently I don't support boxing primitives on property access in eval.
            // So this_val will be Object if it's a method call on object.
            _ => "[object Object]"
          },
        )
      })
      let to_string_obj = JSFunction::{
        name: Some("toString"),
        params: [],
        body: to_string_fn,
        context: Context::new(),
        properties: @hashmap.new(),
        prototype: None,
      }
      obj.properties.set("toString", JSValue::Function(to_string_obj))

      // valueOf
      let value_of_fn = Native(fn(_ctx, this_val, _args) { this_val })
      let value_of_obj = JSFunction::{
        name: Some("valueOf"),
        params: [],
        body: value_of_fn,
        context: Context::new(),
        properties: @hashmap.new(),
        prototype: None,
      }
      obj.properties.set("valueOf", JSValue::Function(value_of_obj))

      // hasOwnProperty
      let has_own_property_fn = Native(fn(_ctx, this_val, args) {
        if args.length() > 0 {
          let key = args[0].to_string()
          match this_val {
            Object(o) => Boolean(o.properties.contains(key))
            Function(f) => Boolean(f.properties.contains(key))
            _ => Boolean(false)
          }
        } else {
          Boolean(false)
        }
      })
      let has_own_property_obj = JSFunction::{
        name: Some("hasOwnProperty"),
        params: ["prop"],
        body: has_own_property_fn,
        context: Context::new(),
        properties: @hashmap.new(),
        prototype: None,
      }
      obj.properties.set(
        "hasOwnProperty",
        JSValue::Function(has_own_property_obj),
      )
    }
    _ => ()
  }
}

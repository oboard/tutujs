//|

///|
pub fn create_console_object(object_proto : JSValue) -> JSValue {
  let props = {
    "log": JSValue::Function(
      JSFunction::new(
        body=Native(fn(_, _, args) {
          println(args.map(i => i.to_string()).join(" "))
          JSValue::Undefined
        }),
      ),
    ),
  }
  JSValue::Object(JSObject::new(properties=props, prototype=object_proto))
}

///|
pub fn create_console_object(object_proto : JSValue) -> JSValue {
  let props = @hashmap.new()
  props.set(
    "log",
    Function(
      JSFunction::new(
        name="log",
        body=Native(fn(_ctx, _this_val, args) {
          let strs = []
          for arg in args {
            strs.push(arg.to_string())
          }
          let mut res = ""
          for i = 0; i < strs.length(); i = i + 1 {
            if i > 0 {
              res = res + " "
            }
            res = res + strs[i]
          }
          println(res)
          Undefined
        }),
      ),
    ),
  )
  Object(JSObject::new(properties=props, prototype=object_proto))
}

///|
pub fn create_proxy_constructor(func_proto : JSValue) -> JSValue {
  let proxy_fn_body = Native(fn(_ctx, _this_val, args) {
    if args is [target, handler, ..] {
      match target {
        Object(t_obj) => {
          let proxy_obj = JSObject::new(
            prototype=t_obj.prototype.unwrap_or(JSValue::Undefined),
          )
          proxy_obj.proxy_target = Some(target)
          proxy_obj.proxy_handler = Some(handler)
          JSValue::Object(proxy_obj)
        }
        Function(t_func) => {
          let proxy_func = JSFunction::new(
            params=t_func.params,
            body=t_func.body,
            context=t_func.context,
            is_constructor=t_func.is_constructor,
          )
          proxy_func.name = t_func.name
          proxy_func.base.prototype = t_func.base.prototype
          proxy_func.base.proxy_target = Some(target)
          proxy_func.base.proxy_handler = Some(handler)
          JSValue::Function(proxy_func)
        }
        _ => JSValue::Undefined // TypeError
      }
    } else {
      JSValue::Undefined // TypeError
    }
  })
  let proxy_fn = JSFunction::new(
    name="Proxy",
    params=["target", "handler"],
    body=proxy_fn_body,
    prototype=func_proto,
    is_constructor=true,
  )
  JSValue::Function(proxy_fn)
}

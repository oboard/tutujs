///|
priv struct ProxyBuiltin {
  inner : JSObject
}

///|
impl Builtin for ProxyBuiltin with to_js_value(self) {
  JSValue::Object(self.inner)
}

///|
pub fn create_proxy_constructor(func_proto : JSValue) -> JSValue {
  let proxy_builtin = ProxyBuiltin::{
    inner: JSObject::new_function(
      name="Proxy",
      params=["target", "handler"],
      body=Native(fn(ctx, this, args) {
        ProxyBuiltin::builtin_constructor(ctx, this, args)
      }),
      prototype=func_proto,
      is_constructor=true,
    ),
  }
  populate_builtin(proxy_builtin.inner, [
    prop_method(
      "revocable",
      fn(ctx, this, args) { proxy_builtin.revocable(ctx, this, args) },
      length=2,
    ),
  ])
  proxy_builtin.to_js_value()
}

///|
/// Proxy(target, handler)
fn ProxyBuiltin::builtin_constructor(
  ctx : Context,
  this_val : JSValue,
  args : Array[JSValue],
) -> JSValue raise EvalError {
  let is_constructor = match this_val {
    Object(_) => true
    _ => false
  }
  if not(is_constructor) {
    ctx.throw_type_error("Constructor Proxy requires 'new'")
  }
  if args is [target, handler, ..] {
    if not(target.is_object()) || not(handler.is_object()) {
      ctx.throw_type_error(
        "Cannot create proxy with a non-object target or handler",
      )
    }
    match target {
      Object(t_obj) =>
        if t_obj.is_callable {
          let call_info = t_obj.call_info.unwrap()
          let proxy_func_ref : Ref[JSObject?] = { val: None }
          let proxy_func_body = Native(fn(ctx, this_val, args) {
            let proxy_func = proxy_func_ref.val.unwrap()
            let base = proxy_func
            match (base.proxy_target, base.proxy_handler) {
              (Some(target), Some(handler)) => {
                let trap = handler.get_property("apply")
                match trap {
                  Object(f) =>
                    if f.is_callable {
                      let arg_array = create_array_from_values(ctx, args)
                      ctx.invoke(f, handler, [target, this_val, arg_array])
                    } else {
                      ctx.throw_type_error("Proxy apply trap is not a function")
                    }
                  Undefined | Null =>
                    match target {
                      Object(tf) =>
                        if tf.is_callable {
                          ctx.invoke(tf, this_val, args)
                        } else {
                          ctx.throw_type_error("Proxy target is not a function")
                        }
                      _ =>
                        ctx.throw_type_error("Proxy target is not a function")
                    }
                  _ =>
                    ctx.throw_type_error("Proxy apply trap is not a function")
                }
              }
              _ => ctx.throw_type_error("Cannot call a revoked proxy")
            }
          })
          let proxy_func = JSObject::new_function(
            params=call_info.params,
            body=proxy_func_body,
            context=call_info.context,
            is_constructor=call_info.is_constructor,
          )
          proxy_func.call_info.unwrap().name = call_info.name
          proxy_func.prototype = t_obj.prototype
          proxy_func.is_proxy = true
          proxy_func.proxy_target = Some(target)
          proxy_func.proxy_handler = Some(handler)
          proxy_func_ref.val = Some(proxy_func)
          JSValue::Object(proxy_func)
        } else {
          let proxy_obj = JSObject::new(
            prototype=t_obj.prototype.unwrap_or(JSValue::Undefined),
          )
          proxy_obj.is_proxy = true
          proxy_obj.proxy_target = Some(target)
          proxy_obj.proxy_handler = Some(handler)
          JSValue::Object(proxy_obj)
        }
      _ => {
        ctx.throw_type_error("Proxy target must be an object")
        JSValue::Undefined
      }
    }
  } else {
    ctx.throw_type_error("Proxy requires 2 arguments")
    JSValue::Undefined
  }
}

///|
/// Proxy.revocable(target, handler)
fn ProxyBuiltin::revocable(
  _self : ProxyBuiltin,
  ctx : Context,
  _this : JSValue,
  args : Array[JSValue],
) -> JSValue raise EvalError {
  if args is [target, handler, ..] {
    if not(target.is_object()) || not(handler.is_object()) {
      ctx.throw_type_error(
        "Cannot create proxy with a non-object target or handler",
      )
    }
    let proxy = ProxyBuiltin::builtin_constructor(
      ctx,
      JSValue::Object(JSObject::new()),
      [target, handler],
    )
    let revoke_fn = Native(fn(_ctx, _this_val, _args) {
      match proxy {
        Object(o) => {
          o.proxy_target = None
          o.proxy_handler = None
        }
        _ => ()
      }
      JSValue::Undefined
    })
    let res_obj = JSObject::new()
    res_obj["proxy"] = proxy
    // Built-in revoke function should have Function.prototype as [[Prototype]]
    let func_proto = match ctx.resolve("Function") {
      Object(f) => JSValue::Object(f).get_property("prototype")
      _ => JSValue::Undefined
    }
    res_obj["revoke"] = JSValue::Object(
      JSObject::new_function(name="", body=revoke_fn, prototype=func_proto),
    )
    JSValue::Object(res_obj)
  } else {
    ctx.throw_type_error("Proxy.revocable requires 2 arguments")
    JSValue::Undefined
  }
}

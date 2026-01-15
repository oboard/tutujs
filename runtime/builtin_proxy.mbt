///|
priv struct ProxyBuiltin {
  inner : JSFunction
}

///|
impl Builtin for ProxyBuiltin with to_js_value(self) {
  JSValue::Function(self.inner)
}

///|
pub fn create_proxy_constructor(func_proto : JSValue) -> JSValue {
  let proxy_builtin = ProxyBuiltin::{
    inner: JSFunction::new(
      name="Proxy",
      params=["target", "handler"],
      body=Native(fn(ctx, this, args) {
        ProxyBuiltin::builtin_constructor(ctx, this, args)
      }),
      prototype=func_proto,
      is_constructor=true,
    ),
  }
  populate_builtin(proxy_builtin.inner.base, [
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
      Object(t_obj) => {
        let proxy_obj = JSObject::new(
          prototype=t_obj.prototype.unwrap_or(JSValue::Undefined),
        )
        proxy_obj.is_proxy = true
        proxy_obj.proxy_target = Some(target)
        proxy_obj.proxy_handler = Some(handler)
        JSValue::Object(proxy_obj)
      }
      Function(t_func) => {
        let proxy_func_ref : Ref[JSFunction?] = { val: None }
        let proxy_func_body = Native(fn(ctx, this_val, args) {
          let proxy_func = proxy_func_ref.val.unwrap()
          let base = proxy_func.base
          match (base.proxy_target, base.proxy_handler) {
            (Some(target), Some(handler)) => {
              let trap = handler.get_property("apply")
              match trap {
                Function(f) => {
                  let arg_array = create_array_from_values(ctx, args)
                  ctx.invoke(f, handler, [target, this_val, arg_array])
                }
                Undefined | Null =>
                  match target {
                    Function(tf) => ctx.invoke(tf, this_val, args)
                    _ => ctx.throw_type_error("Proxy target is not a function")
                  }
                _ => ctx.throw_type_error("Proxy apply trap is not a function")
              }
            }
            _ => ctx.throw_type_error("Cannot call a revoked proxy")
          }
        })
        let proxy_func = JSFunction::new(
          params=t_func.params,
          body=proxy_func_body,
          context=t_func.context,
          is_constructor=t_func.is_constructor,
        )
        proxy_func.name = t_func.name
        proxy_func.base.prototype = t_func.base.prototype
        proxy_func.base.is_proxy = true
        proxy_func.base.proxy_target = Some(target)
        proxy_func.base.proxy_handler = Some(handler)
        proxy_func_ref.val = Some(proxy_func)
        JSValue::Function(proxy_func)
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
        Function(f) => {
          f.base.proxy_target = None
          f.base.proxy_handler = None
        }
        _ => ()
      }
      JSValue::Undefined
    })
    let res_obj = JSObject::new()
    res_obj["proxy"] = proxy
    res_obj["revoke"] = JSValue::Function(
      JSFunction::new(name="", body=revoke_fn),
    )
    JSValue::Object(res_obj)
  } else {
    ctx.throw_type_error("Proxy.revocable requires 2 arguments")
    JSValue::Undefined
  }
}

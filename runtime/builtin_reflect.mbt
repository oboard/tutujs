///|
priv struct ReflectBuiltin {
  inner : JSObject
}

///|
impl Builtin for ReflectBuiltin with to_js_value(self) {
  JSValue::Object(self.inner)
}

///|
pub fn create_reflect_object(
  object_proto : JSValue,
  _func_proto : JSValue,
) -> JSValue {
  let reflect = ReflectBuiltin::{ inner: JSObject::new(prototype=object_proto) }
  populate_builtin(reflect.inner, [
    prop_method(
      "apply",
      fn(ctx, this, args) { reflect.apply(ctx, this, args) },
      length=3,
    ),
    prop_method(
      "construct",
      fn(ctx, this, args) { reflect.construct(ctx, this, args) },
      length=2,
    ),
    prop_method(
      "defineProperty",
      fn(ctx, this, args) { reflect.define_property(ctx, this, args) },
      length=3,
    ),
    prop_method(
      "deleteProperty",
      fn(ctx, this, args) { reflect.delete_property(ctx, this, args) },
      length=2,
    ),
    prop_method(
      "isExtensible",
      fn(ctx, this, args) { reflect.is_extensible(ctx, this, args) },
      length=1,
    ),
    prop_method(
      "preventExtensions",
      fn(ctx, this, args) { reflect.prevent_extensions(ctx, this, args) },
      length=1,
    ),
  ])
  reflect.to_js_value()
}

///|
/// Reflect.apply(target, thisArgument, argumentsList)
fn ReflectBuiltin::apply(
  _self : ReflectBuiltin,
  ctx : Context,
  _this : JSValue,
  args : Array[JSValue],
) -> JSValue raise EvalError {
  if args.length() < 3 {
    ctx.throw_type_error("Reflect.apply requires at least 3 arguments")
  }
  let target = args[0]
  let this_arg = args[1]
  let args_list = args[2]
  let args_array = if args_list.is_object() {
    let len_val = args_list.get_property("length")
    let len = len_val.to_number().to_int()
    let arr = []
    for i = 0; i < len; i = i + 1 {
      arr.push(args_list.get_property(i.to_string()))
    }
    arr
  } else {
    ctx.throw_type_error("Reflect.apply: argumentsList must be an object")
    []
  }
  match target {
    Function(f) => ctx.invoke(f, this_arg, args_array)
    _ => ctx.throw_type_error("Reflect.apply: target must be a function")
  }
}

///|
/// Reflect.construct(target, argumentsList[, newTarget])
fn ReflectBuiltin::construct(
  _self : ReflectBuiltin,
  ctx : Context,
  _this : JSValue,
  args : Array[JSValue],
) -> JSValue raise EvalError {
  if args.length() < 2 {
    ctx.throw_type_error("Reflect.construct requires at least 2 arguments")
  }
  let target = args[0]
  let args_list = args[1]
  let new_target = if args.length() > 2 { args[2] } else { target }
  let func = match target {
    Function(f) if f.is_constructor => f
    _ => ctx.throw_type_error("Reflect.construct: target must be a constructor")
  }
  let nt = match new_target {
    Function(f) if f.is_constructor => f
    _ =>
      ctx.throw_type_error("Reflect.construct: newTarget must be a constructor")
  }
  let args_array = if args_list.is_object() {
    let len_val = args_list.get_property("length")
    let len = len_val.to_number().to_int()
    let arr = []
    for i = 0; i < len; i = i + 1 {
      arr.push(args_list.get_property(i.to_string()))
    }
    arr
  } else {
    ctx.throw_type_error("Reflect.construct: argumentsList must be an object")
    []
  }
  let proto_val = JSValue::Function(nt).get_property("prototype")
  let proto = match proto_val {
    Object(_) as p => p
    _ =>
      match JSValue::Function(func).get_property("prototype") {
        Object(_) as p => p
        _ =>
          match ctx.resolve("Object") {
            Function(obj_ctor) => obj_ctor.get("prototype")
            _ => Null
          }
      }
  }
  let new_obj = JSValue::Object(JSObject::new(prototype=proto))
  let res = ctx.invoke(func, new_obj, args_array) catch {
    EvalError::Return(v) => v
    e => raise e
  }
  match res {
    Object(_) | Function(_) => res
    _ => new_obj
  }
}

///|
/// Reflect.defineProperty(target, propertyKey, attributes)
fn ReflectBuiltin::define_property(
  _self : ReflectBuiltin,
  ctx : Context,
  _this : JSValue,
  args : Array[JSValue],
) -> JSValue {
  match (args, ctx.resolve("Object")) {
    ([_, _, _, ..], Function(obj_ctor)) =>
      match obj_ctor.get("defineProperty") {
        Function(f) => {
          let _ = ctx.invoke(f, Undefined, args) catch {
            _ => return JSValue::Boolean(false)
          }
          JSValue::Boolean(true)
        }
        _ => JSValue::Boolean(false)
      }
    _ => JSValue::Boolean(false)
  }
}

///|
/// Reflect.deleteProperty(target, propertyKey)
fn ReflectBuiltin::delete_property(
  _self : ReflectBuiltin,
  ctx : Context,
  _this : JSValue,
  args : Array[JSValue],
) -> JSValue raise EvalError {
  if args is [target, prop_arg, ..] {
    let prop_name = prop_arg.to_property_key()
    let res = target.delete_property(ctx, prop_name)
    JSValue::Boolean(res)
  } else {
    ctx.throw_type_error("Reflect.deleteProperty requires at least 2 arguments")
  }
}

///|
/// Reflect.isExtensible(target)
fn ReflectBuiltin::is_extensible(
  _self : ReflectBuiltin,
  ctx : Context,
  _this : JSValue,
  args : Array[JSValue],
) -> JSValue {
  if args is [target, ..] {
    match ctx.resolve("Object") {
      Function(obj_ctor) =>
        match obj_ctor.get("isExtensible") {
          Function(f) =>
            ctx.invoke(f, Undefined, [target]) catch {
              _ => JSValue::Boolean(false)
            }
          _ => JSValue::Boolean(false)
        }
      _ => JSValue::Boolean(false)
    }
  } else {
    JSValue::Boolean(false)
  }
}

///|
/// Reflect.preventExtensions(target)
fn ReflectBuiltin::prevent_extensions(
  _self : ReflectBuiltin,
  ctx : Context,
  _this : JSValue,
  args : Array[JSValue],
) -> JSValue {
  if args is [target, ..] {
    match ctx.resolve("Object") {
      Function(obj_ctor) =>
        match obj_ctor.get("preventExtensions") {
          Function(f) => {
            let _ = ctx.invoke(f, Undefined, [target]) catch {
              _ => return JSValue::Boolean(false)
            }
            JSValue::Boolean(true)
          }
          _ => JSValue::Boolean(false)
        }
      _ => JSValue::Boolean(false)
    }
  } else {
    JSValue::Boolean(false)
  }
}

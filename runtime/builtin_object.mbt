///|
priv struct ObjectPrototypeBuiltin {
  inner : JSObject
}

///|
impl Builtin for ObjectPrototypeBuiltin with to_js_value(self) {
  JSValue::Object(self.inner)
}

///|
pub fn init_object_prototype(
  object_proto_val : JSValue,
  _func_proto : JSValue,
) -> Unit {
  match object_proto_val {
    Object(obj) => {
      let proto = ObjectPrototypeBuiltin::{ inner: obj }
      populate_builtin(proto.inner, [
        prop_method("toString", proto.to_string(_, _, _)),
        prop_method("valueOf", proto.value_of(_, _, _)),
        prop_method("toLocaleString", proto.to_locale_string(_, _, _)),
        prop_method("hasOwnProperty", proto.has_own_property(_, _, _), length=1),
        prop_method("isPrototypeOf", proto.is_prototype_of(_, _, _), length=1),
        prop_method(
          "propertyIsEnumerable",
          proto.property_is_enumerable(_, _, _),
          length=1,
        ),
      ])
    }
    _ => ()
  }
}

///|
/// Object.prototype.toString()
fn ObjectPrototypeBuiltin::to_string(
  _self : ObjectPrototypeBuiltin,
  _ctx : Context,
  this_val : JSValue,
  _args : Array[JSValue],
) -> JSValue {
  let tag = match this_val {
    Undefined => "Undefined"
    Null => "Null"
    Object(_) | Function(_) => {
      let tag_val = this_val.get_property("Symbol(Symbol.toStringTag)")
      match tag_val {
        String(s) => s.to_string()
        _ => {
          let properties = match this_val {
            Object({ properties, .. }) => properties
            Function({ base: { properties, .. }, .. }) => properties
            _ => @hashmap.new()
          }
          match properties.get("PrimitiveValue") {
            Some(String(_)) => "String"
            Some(Number(_)) => "Number"
            Some(Boolean(_)) => "Boolean"
            _ => if this_val is Function(_) { "Function" } else { "Object" }
          }
        }
      }
    }
    String(_) => "String"
    Number(_) => "Number"
    Boolean(_) => "Boolean"
    Symbol(_, _) => "Symbol"
    BigInt(_) => "BigInt"
    _ => "Object"
  }
  JSValue::String("[object " + tag + "]")
}

///|
/// Object.prototype.valueOf()
fn ObjectPrototypeBuiltin::value_of(
  _self : ObjectPrototypeBuiltin,
  _ctx : Context,
  this_val : JSValue,
  _args : Array[JSValue],
) -> JSValue {
  this_val
}

///|
/// Object.prototype.toLocaleString()
fn ObjectPrototypeBuiltin::to_locale_string(
  _self : ObjectPrototypeBuiltin,
  ctx : Context,
  this_val : JSValue,
  _args : Array[JSValue],
) -> JSValue raise EvalError {
  let to_string = this_val.get_property("toString")
  match to_string {
    Function(f) => ctx.invoke(f, this_val, [])
    _ => JSValue::String(this_val.to_string())
  }
}

///|
/// Object.prototype.hasOwnProperty(prop)
fn ObjectPrototypeBuiltin::has_own_property(
  _self : ObjectPrototypeBuiltin,
  _ctx : Context,
  this_val : JSValue,
  args : Array[JSValue],
) -> JSValue {
  if args.length() == 0 {
    return JSValue::Boolean(false)
  }
  let key = args[0].to_property_key()
  match this_val {
    Object({ properties, .. }) | Function({ base: { properties, .. }, .. }) => {
      if properties.contains("PrimitiveValue") {
        match properties.get("PrimitiveValue") {
          Some(String(s)) => {
            let idx = @strconv.parse_int(key) catch { _ => -1 }
            if idx >= 0 && idx < s.length() {
              return JSValue::Boolean(true)
            }
          }
          _ => ()
        }
      }
      JSValue::Boolean(properties.contains(key))
    }
    _ => JSValue::Boolean(false)
  }
}

///|
/// Object.prototype.isPrototypeOf(object)
fn ObjectPrototypeBuiltin::is_prototype_of(
  _self : ObjectPrototypeBuiltin,
  _ctx : Context,
  this_val : JSValue,
  args : Array[JSValue],
) -> JSValue {
  if args.length() == 0 {
    return JSValue::Boolean(false)
  }
  match args[0] {
    Object(o) | Function({ base: o, .. }) => {
      let mut proto = o.prototype
      while true {
        match proto {
          Some(p) => {
            if p.strict_equal(this_val) {
              return JSValue::Boolean(true)
            }
            match p {
              Object({ prototype, .. })
              | Function({ base: { prototype, .. }, .. }) => proto = prototype
              _ => break
            }
          }
          None => break
        }
      }
      JSValue::Boolean(false)
    }
    _ => JSValue::Boolean(false)
  }
}

///|
/// Object.prototype.propertyIsEnumerable(prop)
fn ObjectPrototypeBuiltin::property_is_enumerable(
  _self : ObjectPrototypeBuiltin,
  ctx : Context,
  this_val : JSValue,
  args : Array[JSValue],
) -> JSValue {
  if args.length() == 0 {
    return JSValue::Boolean(false)
  }
  let key = args[0].to_property_key()
  match this_val {
    Object({ properties, .. }) | Function({ base: { properties, .. }, .. }) => {
      let mut root_ctx = ctx
      while true {
        match root_ctx.parent {
          Some(p) => root_ctx = p
          None => break
        }
      }
      let is_global = match root_ctx.scope.get("globalThis") {
        Some(g) => g.strict_equal(this_val)
        None => false
      }
      if is_global && is_builtin_global_property(key) {
        return JSValue::Boolean(false)
      }
      if properties.contains("PrimitiveValue") {
        match properties.get("PrimitiveValue") {
          Some(String(s)) => {
            let idx = @strconv.parse_int(key) catch { _ => -1 }
            if idx >= 0 && idx < s.length() {
              return JSValue::Boolean(true)
            }
          }
          _ => ()
        }
      }
      let is_enumerable = match properties.get("__descriptors") {
        Some(Object(d)) =>
          match d.properties.get(key) {
            Some(Object(desc)) =>
              match desc.properties.get("enumerable") {
                Some(Boolean(b)) => b
                _ => true
              }
            _ => true
          }
        _ => true
      }
      JSValue::Boolean(
        properties.contains(key) && not(key.has_prefix("__")) && is_enumerable,
      )
    }
    _ => JSValue::Boolean(false)
  }
}

///|
priv struct ObjectBuiltin {
  inner : JSFunction
}

///|
impl Builtin for ObjectBuiltin with to_js_value(self) {
  JSValue::Function(self.inner)
}

///|
pub fn create_object_constructor(
  proto : JSValue,
  func_proto : JSValue,
) -> JSValue {
  let object_builtin = ObjectBuiltin::{
    inner: JSFunction::new(
      name="Object",
      params=["value"],
      body=Native(ObjectBuiltin::builtin_constructor),
      prototype=func_proto,
      is_constructor=true,
    ),
  }
  object_builtin.inner.base.properties.set("prototype", proto)
  populate_builtin(object_builtin.inner.base, [
    prop_method("keys", object_builtin.keys(_, _, _), length=1),
    prop_method("create", object_builtin.create(_, _, _), length=2),
    prop_method("is", object_builtin.builtin_is(_, _, _), length=2),
    prop_method("assign", object_builtin.assign(_, _, _), length=2),
    prop_method(
      "defineProperty",
      object_builtin.define_property(_, _, _),
      length=3,
    ),
    prop_method("freeze", object_builtin.freeze(_, _, _), length=1),
    prop_method("isFrozen", object_builtin.is_frozen(_, _, _), length=1),
    prop_method("seal", object_builtin.seal(_, _, _), length=1),
    prop_method("isSealed", object_builtin.is_sealed(_, _, _), length=1),
    prop_method(
      "preventExtensions",
      object_builtin.prevent_extensions(_, _, _),
      length=1,
    ),
    prop_method("isExtensible", object_builtin.is_extensible(_, _, _), length=1),
    prop_method(
      "getOwnPropertySymbols",
      fn(ctx, this, args) {
        object_builtin.get_own_property_symbols(ctx, this, args)
      },
      length=1,
    ),
    prop_method(
      "getOwnPropertyDescriptor",
      object_builtin.get_own_property_descriptor(_, _, _),
      length=2,
    ),
    prop_method(
      "getPrototypeOf",
      object_builtin.get_prototype_of(_, _, _),
      length=1,
    ),
    prop_method(
      "setPrototypeOf",
      object_builtin.set_prototype_of(_, _, _),
      length=2,
    ),
    prop_method(
      "getOwnPropertyNames",
      object_builtin.get_own_property_names(_, _, _),
      length=1,
    ),
  ])
  object_builtin.to_js_value()
}

///|
/// Object(value)
fn ObjectBuiltin::builtin_constructor(
  ctx : Context,
  this_val : JSValue,
  args : Array[JSValue],
) -> JSValue raise EvalError {
  let proto = match ctx.resolve("Object") {
    Function(f) => f.get("prototype")
    _ => JSValue::Null
  }
  if args.length() > 0 {
    let val = args[0]
    let is_subclass_this = match this_val.get_prototype() {
      Some(p) => not(p.strict_equal(proto))
      None => false
    }
    if is_subclass_this {
      return this_val
    }
    match val {
      Object(_) | Function(_) => val
      Null | Undefined =>
        match this_val {
          Object(_) | Function(_) => this_val
          _ => JSValue::Object(JSObject::new(prototype=proto))
        }
      _ => {
        let ctor_name = match val {
          String(_) => "String"
          Number(_) => "Number"
          Boolean(_) => "Boolean"
          Symbol(_, _) => "Symbol"
          BigInt(_) => "BigInt"
          _ => ""
        }
        if ctor_name != "" {
          match ctx.resolve(ctor_name) {
            Function(f) => {
              let p = f.get("prototype")
              let obj = JSObject::new(prototype=p)
              obj["PrimitiveValue"] = val
              obj["constructor"] = JSValue::Function(f)
              if val is String(s) {
                obj["length"] = JSValue::Number(s.length().to_double())
              }
              JSValue::Object(obj)
            }
            _ => val
          }
        } else {
          val
        }
      }
    }
  } else {
    match this_val {
      Object(_) | Function(_) => this_val
      _ => JSValue::Object(JSObject::new(prototype=proto))
    }
  }
}

///|
/// Object.keys(obj)
fn ObjectBuiltin::keys(
  _self : ObjectBuiltin,
  ctx : Context,
  _this : JSValue,
  args : Array[JSValue],
) -> JSValue raise EvalError {
  if args.length() == 0 {
    ctx.throw_type_error("Cannot convert undefined or null to object")
  }
  let obj_arg = args[0]
  match obj_arg {
    Null | Undefined =>
      ctx.throw_type_error("Cannot convert undefined or null to object")
    _ => ()
  }
  let keys = obj_arg.own_keys(ctx)
  let enumerable_keys = []
  for k in keys {
    if not(k.has_prefix("Symbol(")) {
      let desc = match ctx.resolve("Object") {
        Function(f) =>
          match f.get("getOwnPropertyDescriptor") {
            Function(g) =>
              ctx.invoke(g, Undefined, [obj_arg, JSValue::String(k)]) catch {
                _ => Undefined
              }
            _ => Undefined
          }
        _ => Undefined
      }
      if desc.is_object() && desc.get_property("enumerable").is_truthy() {
        enumerable_keys.push(JSValue::String(k))
      }
    }
  }
  create_array_from_values(ctx, enumerable_keys)
}

///|
/// Object.create(proto)
fn ObjectBuiltin::create(
  _self : ObjectBuiltin,
  ctx : Context,
  _this : JSValue,
  args : Array[JSValue],
) -> JSValue raise EvalError {
  if args.length() == 0 {
    ctx.throw_type_error("Object.create requires at least 1 argument")
  }
  let proto = args[0]
  match proto {
    Object(_) | Null => JSValue::Object(JSObject::new(prototype=proto))
    _ =>
      ctx.throw_type_error("Object.create: prototype must be an object or null")
  }
}

///|
/// Object.is(v1, v2)
fn ObjectBuiltin::builtin_is(
  _self : ObjectBuiltin,
  _ctx : Context,
  _this : JSValue,
  args : Array[JSValue],
) -> JSValue {
  if args.length() >= 2 {
    JSValue::Boolean(args[0].strict_equal(args[1]))
  } else {
    JSValue::Boolean(false)
  }
}

///|
/// Object.assign(target, ...sources)
fn ObjectBuiltin::assign(
  _self : ObjectBuiltin,
  _ctx : Context,
  _this : JSValue,
  args : Array[JSValue],
) -> JSValue {
  if args.length() == 0 {
    return JSValue::Undefined
  }
  let target = args[0]
  match target {
    Object(t) | Function({ base: t, .. }) => {
      for i = 1; i < args.length(); i = i + 1 {
        match args[i] {
          Object(s) | Function({ base: s, .. }) =>
            for k, v in s.properties {
              if not(k.has_prefix("__")) && k != "PrimitiveValue" {
                t.properties.set(k, v)
              }
            }
          _ => ()
        }
      }
      target
    }
    _ => target
  }
}

///|
/// Object.defineProperty(obj, prop, desc)
fn ObjectBuiltin::define_property(
  _self : ObjectBuiltin,
  ctx : Context,
  _this : JSValue,
  args : Array[JSValue],
) -> JSValue raise EvalError {
  if args.length() < 3 {
    ctx.throw_type_error("Object.defineProperty requires 3 arguments")
  }
  let obj = args[0]
  let prop = args[1].to_property_key()
  let desc = args[2]

  // Proxy support
  match obj {
    Object(
      {
        is_proxy: true,
        proxy_target: Some(target),
        proxy_handler: Some(handler),
        ..,
      }
    )
    | Function(
      {
        base: {
          is_proxy: true,
          proxy_target: Some(target),
          proxy_handler: Some(handler),
          ..,
        },
        ..,
      }
    ) => {
      let trap = handler.get_property("defineProperty")
      match trap {
        Function(f) => {
          let res = ctx.invoke(f, handler, [target, args[1], desc])
          if not(res.is_truthy()) {
            ctx.throw_type_error("Proxy defineProperty trap returned false")
          }
          return obj
        }
        _ => ()
      }
    }
    _ => ()
  }
  match (obj, desc) {
    (Object(o), Object(d)) | (Function({ base: o, .. }), Object(d)) => {
      if d.properties.contains("value") {
        o.properties.set(prop, d.properties.get("value").unwrap())
      }
      let descriptors = match o.properties.get("__descriptors") {
        Some(Object(dm)) => dm
        _ => {
          let dm = JSObject::new()
          o.properties.set("__descriptors", JSValue::Object(dm))
          dm
        }
      }
      descriptors[prop] = desc
      obj
    }
    _ =>
      ctx.throw_type_error(
        "Object.defineProperty: target must be an object and descriptor must be an object",
      )
  }
}

// 其余静态方法实现

///|
fn ObjectBuiltin::freeze(
  _self : ObjectBuiltin,
  _ctx : Context,
  _this : JSValue,
  args : Array[JSValue],
) -> JSValue {
  if args.length() > 0 {
    args[0]
  } else {
    JSValue::Undefined
  }
}

///|
fn ObjectBuiltin::is_frozen(
  _self : ObjectBuiltin,
  _ctx : Context,
  _this : JSValue,
  _args : Array[JSValue],
) -> JSValue {
  JSValue::Boolean(false)
}

///|
fn ObjectBuiltin::seal(
  _self : ObjectBuiltin,
  _ctx : Context,
  _this : JSValue,
  args : Array[JSValue],
) -> JSValue {
  if args.length() > 0 {
    args[0]
  } else {
    JSValue::Undefined
  }
}

///|
fn ObjectBuiltin::is_sealed(
  _self : ObjectBuiltin,
  _ctx : Context,
  _this : JSValue,
  _args : Array[JSValue],
) -> JSValue {
  JSValue::Boolean(false)
}

///|
fn ObjectBuiltin::prevent_extensions(
  _self : ObjectBuiltin,
  _ctx : Context,
  _this : JSValue,
  args : Array[JSValue],
) -> JSValue {
  if args.length() > 0 {
    args[0]
  } else {
    JSValue::Undefined
  }
}

///|
fn ObjectBuiltin::is_extensible(
  _self : ObjectBuiltin,
  _ctx : Context,
  _this : JSValue,
  _args : Array[JSValue],
) -> JSValue {
  JSValue::Boolean(true)
}

///|
fn ObjectBuiltin::get_own_property_symbols(
  _self : ObjectBuiltin,
  ctx : Context,
  _this : JSValue,
  args : Array[JSValue],
) -> JSValue raise EvalError {
  if args.length() == 0 {
    return create_array_from_values(ctx, [])
  }
  let keys = args[0].own_keys(ctx)
  let symbols = []
  for k in keys {
    if k.has_prefix("Symbol(") {
      // 提取 Symbol ID 和描述并创建 Symbol 值
      symbols.push(JSValue::String(k))
    }
  }
  create_array_from_values(ctx, symbols)
}

///|
fn ObjectBuiltin::get_own_property_descriptor(
  _self : ObjectBuiltin,
  ctx : Context,
  _this : JSValue,
  args : Array[JSValue],
) -> JSValue raise EvalError {
  if args.length() < 2 {
    return JSValue::Undefined
  }
  let obj_arg = args[0]
  let prop_arg = args[1]
  let prop = prop_arg.to_property_key()

  // Proxy trap
  let proxy_info = match obj_arg {
    Object(o) if o.is_proxy => Some((o.proxy_target, o.proxy_handler))
    Function(f) if f.base.is_proxy =>
      Some((f.base.proxy_target, f.base.proxy_handler))
    _ => None
  }
  match proxy_info {
    Some((Some(target), Some(handler))) => {
      let trap = handler.get_property("getOwnPropertyDescriptor")
      match trap {
        Function(f) => {
          let trap_res = ctx.invoke(f, handler, [target, JSValue::String(prop)])
          if trap_res is Undefined {
            // Invariant check
            let target_desc = match ctx.resolve("Object") {
              Function(of) =>
                match of.get("getOwnPropertyDescriptor") {
                  Function(g) =>
                    ctx.invoke(g, Undefined, [target, JSValue::String(prop)]) catch {
                      _ => Undefined
                    }
                  _ => Undefined
                }
              _ => Undefined
            }
            match target_desc {
              Object(d) => {
                let configurable = match d.properties.get("configurable") {
                  Some(Boolean(b)) => b
                  _ => true
                }
                if not(configurable) {
                  ctx.throw_type_error(
                    "Proxy getOwnPropertyDescriptor trap invariant violated: cannot report undefined for non-configurable property",
                  )
                }
              }
              _ => ()
            }
            return Undefined
          }
          if not(trap_res.is_object()) {
            ctx.throw_type_error(
              "Proxy getOwnPropertyDescriptor trap must return an object or undefined",
            )
          }
          // Invariant check: if result is non-configurable, it must exist on target and be non-configurable
          let result_configurable = match trap_res {
            Object(o) =>
              match o.properties.get("configurable") {
                Some(Boolean(b)) => b
                _ => true
              }
            _ => true
          }
          if not(result_configurable) {
            let target_desc = match ctx.resolve("Object") {
              Function(of) =>
                match of.get("getOwnPropertyDescriptor") {
                  Function(g) =>
                    ctx.invoke(g, Undefined, [target, JSValue::String(prop)]) catch {
                      _ => Undefined
                    }
                  _ => Undefined
                }
              _ => Undefined
            }
            match target_desc {
              Undefined =>
                ctx.throw_type_error(
                  "Proxy getOwnPropertyDescriptor trap invariant violated: cannot report non-configurable for non-existent property",
                )
              Object(d) => {
                let target_configurable = match
                  d.properties.get("configurable") {
                  Some(Boolean(b)) => b
                  _ => true
                }
                if target_configurable {
                  ctx.throw_type_error(
                    "Proxy getOwnPropertyDescriptor trap invariant violated: cannot report non-configurable for configurable property",
                  )
                }
              }
              _ => ()
            }
          }
          return trap_res
        }
        Undefined | Null => {
          // Fallback to target
          let get_desc_fn = match ctx.resolve("Object") {
            Function(of) => of.get("getOwnPropertyDescriptor")
            _ => Undefined
          }
          match get_desc_fn {
            Function(f) =>
              return ctx.invoke(f, Undefined, [target, JSValue::String(prop)])
            _ => ()
          }
        }
        _ =>
          ctx.throw_type_error(
            "Proxy getOwnPropertyDescriptor trap is not a function",
          )
      }
    }
    Some((None, _)) =>
      ctx.throw_type_error(
        "Cannot perform 'getOwnPropertyDescriptor' on a revoked proxy",
      )
    _ => ()
  }
  let (properties, is_frozen, is_sealed) = match obj_arg {
    Object(o) => (o.properties, o.is_frozen, o.is_sealed)
    Function(f) => (f.base.properties, f.base.is_frozen, f.base.is_sealed)
    _ => return JSValue::Undefined
  }
  match properties.get("__descriptors") {
    Some(Object(d)) => d.properties.get(prop).unwrap_or(JSValue::Undefined)
    _ =>
      if properties.contains(prop) {
        let val = properties.get(prop).unwrap()
        let d = JSObject::new()
        d["value"] = val
        d["writable"] = JSValue::Boolean(not(is_frozen))
        d["enumerable"] = JSValue::Boolean(true)
        d["configurable"] = JSValue::Boolean(not(is_sealed))
        JSValue::Object(d)
      } else {
        JSValue::Undefined
      }
  }
}

///|
fn ObjectBuiltin::get_prototype_of(
  _self : ObjectBuiltin,
  _ctx : Context,
  _this : JSValue,
  args : Array[JSValue],
) -> JSValue {
  if args.length() > 0 {
    args[0].get_prototype().unwrap_or(JSValue::Null)
  } else {
    JSValue::Null
  }
}

///|
fn ObjectBuiltin::set_prototype_of(
  _self : ObjectBuiltin,
  _ctx : Context,
  _this : JSValue,
  args : Array[JSValue],
) -> JSValue {
  if args.length() >= 2 {
    let obj = args[0]
    let proto = args[1]
    match obj {
      Object(o) => o.prototype = Some(proto)
      Function(f) => f.base.prototype = Some(proto)
      _ => ()
    }
    obj
  } else if args.length() == 1 {
    args[0]
  } else {
    JSValue::Undefined
  }
}

///|
fn ObjectBuiltin::get_own_property_names(
  _self : ObjectBuiltin,
  ctx : Context,
  _this : JSValue,
  args : Array[JSValue],
) -> JSValue raise EvalError {
  if args.length() == 0 {
    return create_array_from_values(ctx, [])
  }
  let keys = args[0].own_keys(ctx)
  let names = []
  for k in keys {
    if not(k.has_prefix("Symbol(")) {
      names.push(JSValue::String(k))
    }
  }
  create_array_from_values(ctx, names)
}

// 辅助函数：判断是否为内置全局属性（不可枚举）

///|
fn is_builtin_global_property(key : String) -> Bool {
  key == "Map" ||
  key == "Set" ||
  key == "WeakMap" ||
  key == "WeakSet" ||
  key == "Promise" ||
  key == "Symbol" ||
  key == "Reflect" ||
  key == "JSON" ||
  key == "Math" ||
  key == "Date" ||
  key == "RegExp" ||
  key == "Error" ||
  key == "eval" ||
  key == "parseInt" ||
  key == "parseFloat" ||
  key == "isNaN" ||
  key == "isFinite" ||
  key == "Object" ||
  key == "Function" ||
  key == "Array" ||
  key == "String" ||
  key == "Number" ||
  key == "Boolean"
}

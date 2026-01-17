///|
/// 描述一个内置属性（数据或方法）
pub(all) struct BuiltinProperty {
  name : String
  value : JSValue
  enumerable : Bool
  configurable : Bool
  writable : Bool
}

///|
/// 辅助函数：快速创建内置方法描述
pub fn prop_method(
  name : String,
  f : (Context, JSValue, Array[JSValue]) -> JSValue raise EvalError,
  length? : Int = 0,
  enumerable? : Bool = false,
  configurable? : Bool = true,
  writable? : Bool = true,
  prototype? : JSValue,
) -> BuiltinProperty {
  let func = JSObject::new_function(
    name~,
    body=Native(f),
    params=[], // We use length override instead of params
    prototype?,
  )
  // Override length and name descriptors to be correct for built-ins
  let len = JSValue::Number(length.to_double())
  func["length"] = len
  func["name"] = JSValue::String(name)
  let descriptors = match func.properties.get("__descriptors") {
    Some(Object(d)) => d
    _ => {
      let d = JSObject::new()
      func.properties.set("__descriptors", JSValue::Object(d))
      d
    }
  }
  let len_desc = JSObject::new(properties={
    "enumerable": JSValue::Boolean(false),
    "configurable": JSValue::Boolean(true),
    "writable": JSValue::Boolean(false),
    "value": len,
  })
  descriptors["length"] = JSValue::Object(len_desc)
  let name_desc = JSObject::new(properties={
    "enumerable": JSValue::Boolean(false),
    "configurable": JSValue::Boolean(true),
    "writable": JSValue::Boolean(false),
    "value": JSValue::String(name),
  })
  descriptors["name"] = JSValue::Object(name_desc)
  { name, value: JSValue::Object(func), enumerable, configurable, writable }
}

///|
/// 辅助函数：快速创建内置数据属性描述
pub fn prop_data(
  name : String,
  value : JSValue,
  enumerable? : Bool = false,
  configurable? : Bool = true,
  writable? : Bool = true,
) -> BuiltinProperty {
  { name, value, enumerable, configurable, writable }
}

///|
/// 抽象内置对象的行为
pub trait Builtin {
  to_js_value(self : Self) -> JSValue
}

///|
/// 组装内置对象的通用逻辑
pub fn populate_builtin(obj : JSObject, props : Array[BuiltinProperty]) -> Unit {
  for prop in props {
    obj[prop.name] = prop.value
    let descriptors = match obj.properties.get("__descriptors") {
      Some(Object(d)) => d
      _ => {
        let d = JSObject::new()
        obj.properties.set("__descriptors", JSValue::Object(d))
        d
      }
    }
    let desc = JSObject::new(properties={
      "enumerable": JSValue::Boolean(prop.enumerable),
      "configurable": JSValue::Boolean(prop.configurable),
      "writable": JSValue::Boolean(prop.writable),
      "value": prop.value,
    })
    descriptors[prop.name] = JSValue::Object(desc)
  }
}

///|
/// 从 Array[JSValue] 创建 JS Array 对象
pub fn create_array_from_values(
  ctx : Context,
  values : Array[JSValue],
) -> JSValue {
  let array_proto = match ctx.resolve("Array") {
    Object(f) => f.get("prototype")
    _ => JSValue::Null
  }
  let arr = JSObject::new(prototype=array_proto, properties={
    "length": JSValue::Number(values.length().to_double()),
  })
  for i, v in values {
    arr[i.to_string()] = v
  }
  JSValue::Object(arr)
}

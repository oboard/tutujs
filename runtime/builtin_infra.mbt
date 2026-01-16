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
  length? : Int,
  enumerable? : Bool,
  configurable? : Bool,
  writable? : Bool,
) -> BuiltinProperty {
  let length = length.unwrap_or(0)
  let enumerable = enumerable.unwrap_or(false)
  let configurable = configurable.unwrap_or(true)
  let writable = writable.unwrap_or(true)
  let func_props = {
    "length": JSValue::Number(length.to_double()),
    "name": JSValue::String(name),
  }
  let func = JSFunction::new(name~, body=Native(f), properties=func_props)
  { name, value: JSValue::Function(func), enumerable, configurable, writable }
}

///|
/// 辅助函数：快速创建内置数据属性描述
pub fn prop_data(
  name : String,
  value : JSValue,
  enumerable? : Bool,
  configurable? : Bool,
  writable? : Bool,
) -> BuiltinProperty {
  let enumerable = enumerable.unwrap_or(false)
  let configurable = configurable.unwrap_or(true)
  let writable = writable.unwrap_or(true)
  { name, value, enumerable, configurable, writable }
}

///|
/// 抽象内置对象的行为
pub trait Builtin {
  to_js_value(self : Self) -> JSValue
}

///|
/// 组装内置对象的通用逻辑
pub fn populate_builtin(
  obj : JSObject,
  properties : Array[BuiltinProperty],
) -> Unit {
  for prop in properties {
    obj[prop.name] = prop.value

    // 如果有描述符存储，也记录下来
    let descriptors = match obj.properties.get("__descriptors") {
      Some(Object(d)) => d
      _ => {
        let d = JSObject::new()
        obj["__descriptors"] = JSValue::Object(d)
        d
      }
    }
    let desc = JSObject::new()
    desc["enumerable"] = JSValue::Boolean(prop.enumerable)
    desc["configurable"] = JSValue::Boolean(prop.configurable)
    desc["writable"] = JSValue::Boolean(prop.writable)
    desc["value"] = prop.value
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
    Function(f) => f.get("prototype")
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

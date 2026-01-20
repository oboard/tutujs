///|
pub enum JSValue {
  Undefined
  Null
  Bool(Bool)
  Number(Double)
  String(String)
  BigInt(@bigint.BigInt)
  Symbol(SymbolValue)
  Builtin(BuiltinValue)
  Function(FunctionValue)
  BoundFunction(BoundFunctionValue)
  Object(ObjectValue)
  Array(ArrayValue)
  Arguments(ArgumentsValue)
} derive(Show, ToJson)

///|
pub fn value_undefined() -> JSValue {
  JSValue::Undefined
}

///|
pub fn value_null() -> JSValue {
  JSValue::Null
}

///|
pub fn value_bool(value : Bool) -> JSValue {
  JSValue::Bool(value)
}

///|
pub fn value_number(value : Double) -> JSValue {
  JSValue::Number(value)
}

///|
pub fn value_string(value : String) -> JSValue {
  JSValue::String(value)
}

///|
pub fn value_bigint(value : @bigint.BigInt) -> JSValue {
  JSValue::BigInt(value)
}

///|
pub fn value_symbol(value : SymbolValue) -> JSValue {
  JSValue::Symbol(value)
}

///|
pub fn value_builtin(value : BuiltinValue) -> JSValue {
  JSValue::Builtin(value)
}

///|
pub fn value_function(value : FunctionValue) -> JSValue {
  JSValue::Function(value)
}

///|
pub fn value_bound_function(value : BoundFunctionValue) -> JSValue {
  JSValue::BoundFunction(value)
}

///|
pub fn value_object(value : ObjectValue) -> JSValue {
  JSValue::Object(value)
}

///|
pub fn value_array(value : ArrayValue) -> JSValue {
  JSValue::Array(value)
}

///|
pub fn value_arguments(value : ArgumentsValue) -> JSValue {
  JSValue::Arguments(value)
}

///|
pub fn JSValue::undefined() -> JSValue {
  Undefined
}

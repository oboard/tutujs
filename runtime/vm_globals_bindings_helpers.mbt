///|
fn declare_global_ctors(
  env : Env,
  object_ctor : JSValue,
  function_ctor : JSValue,
  array_ctor : JSValue,
  array_buffer_ctor : JSValue,
  shared_array_buffer_ctor : JSValue,
  dataview_ctor : JSValue,
  typed_array_ctor : JSValue,
  uint8_array_ctor : JSValue,
  int8_array_ctor : JSValue,
  uint8_clamped_array_ctor : JSValue,
  uint16_array_ctor : JSValue,
  int16_array_ctor : JSValue,
  uint32_array_ctor : JSValue,
  int32_array_ctor : JSValue,
  bigint64_array_ctor : JSValue,
  biguint64_array_ctor : JSValue,
  float16_array_ctor : JSValue,
  float32_array_ctor : JSValue,
  float64_array_ctor : JSValue,
  string_ctor : JSValue,
  number_ctor : JSValue,
  bool_ctor : JSValue,
  bigint_ctor : JSValue,
  symbol_ctor : JSValue,
  iterator_ctor : JSValue,
  regexp_ctor : JSValue,
  date_ctor : JSValue,
  map_ctor : JSValue,
  set_ctor : JSValue,
  weakmap_ctor : JSValue,
  weakset_ctor : JSValue,
  weakref_ctor : JSValue,
  finreg_ctor : JSValue,
  promise_ctor : JSValue,
  proxy_ctor : JSValue,
  error_ctor : JSValue,
  aggregate_error_ctor : JSValue,
  eval_error_ctor : JSValue,
  syntax_error_ctor : JSValue,
  range_error_ctor : JSValue,
  type_error_ctor : JSValue,
  reference_error_ctor : JSValue,
  uri_error_ctor : JSValue,
) -> Unit {
  env_declare(env, "Object", object_ctor)
  env_declare(env, "Function", function_ctor)
  env_declare(env, "Array", array_ctor)
  env_declare(env, "ArrayBuffer", array_buffer_ctor)
  env_declare(env, "SharedArrayBuffer", shared_array_buffer_ctor)
  env_declare(env, "DataView", dataview_ctor)
  env_declare(env, "TypedArray", typed_array_ctor)
  env_declare(env, "Uint8Array", uint8_array_ctor)
  env_declare(env, "Int8Array", int8_array_ctor)
  env_declare(env, "Uint8ClampedArray", uint8_clamped_array_ctor)
  env_declare(env, "Uint16Array", uint16_array_ctor)
  env_declare(env, "Int16Array", int16_array_ctor)
  env_declare(env, "Uint32Array", uint32_array_ctor)
  env_declare(env, "Int32Array", int32_array_ctor)
  env_declare(env, "BigInt64Array", bigint64_array_ctor)
  env_declare(env, "BigUint64Array", biguint64_array_ctor)
  env_declare(env, "Float16Array", float16_array_ctor)
  env_declare(env, "Float32Array", float32_array_ctor)
  env_declare(env, "Float64Array", float64_array_ctor)
  env_declare(env, "String", string_ctor)
  env_declare(env, "Number", number_ctor)
  env_declare(env, "Bool",bool_ctor)
  env_declare(env, "BigInt", bigint_ctor)
  env_declare(env, "Symbol", symbol_ctor)
  env_declare(env, "Iterator", iterator_ctor)
  env_declare(env, "RegExp", regexp_ctor)
  env_declare(env, "Date", date_ctor)
  env_declare(env, "Map", map_ctor)
  env_declare(env, "Set", set_ctor)
  env_declare(env, "WeakMap", weakmap_ctor)
  env_declare(env, "WeakSet", weakset_ctor)
  env_declare(env, "WeakRef", weakref_ctor)
  env_declare(env, "FinalizationRegistry", finreg_ctor)
  env_declare(env, "Promise", promise_ctor)
  env_declare(env, "Proxy", proxy_ctor)
  env_declare(env, "Error", error_ctor)
  env_declare(env, "AggregateError", aggregate_error_ctor)
  env_declare(env, "EvalError", eval_error_ctor)
  env_declare(env, "SyntaxError", syntax_error_ctor)
  env_declare(env, "RangeError", range_error_ctor)
  env_declare(env, "TypeError", type_error_ctor)
  env_declare(env, "ReferenceError", reference_error_ctor)
  env_declare(env, "URIError", uri_error_ctor)
}

///|
fn declare_standard_objects(
  env : Env,
  json_obj : JSValue,
  reflect_obj : JSValue,
  atomics_obj : JSValue,
  math_obj : JSValue,
  parse_int_func : JSValue,
  parse_float_func : JSValue,
) -> Unit {
  env_declare(env, "JSON", json_obj)
  env_declare(env, "Reflect", reflect_obj)
  env_declare(env, "Atomics", atomics_obj)
  env_declare(env, "Math", math_obj)
  env_declare(env, "parseInt", parse_int_func)
  env_declare(env, "parseFloat", parse_float_func)
}

///|
fn declare_module_helpers(env : Env) -> Unit {
  env_declare(env, "__import", new_builtin_value(BuiltinFunction::ModuleImport))
  env_declare(
    env,
    "__import_dynamic",
    new_builtin_value(BuiltinFunction::ModuleImportDynamic),
  )
  env_declare(
    env,
    "__import_binding",
    new_builtin_value(BuiltinFunction::ModuleImportBinding),
  )
  env_declare(
    env,
    "__binding",
    new_builtin_value(BuiltinFunction::ModuleBinding),
  )
  env_declare(env, "__export", new_builtin_value(BuiltinFunction::ModuleExport))
  env_declare(
    env,
    "__export_star",
    new_builtin_value(BuiltinFunction::ModuleExportStar),
  )
}

///|
fn declare_global_functions(env : Env) -> Unit {
  env_declare(env, "eval", new_builtin_value(BuiltinFunction::Eval))
  env_declare(env, "isNaN", new_builtin_value(BuiltinFunction::IsNaN))
  env_declare(env, "isFinite", new_builtin_value(BuiltinFunction::IsFinite))
  env_declare(env, "decodeURI", new_builtin_value(BuiltinFunction::DecodeURI))
  env_declare(
    env,
    "decodeURIComponent",
    new_builtin_value(BuiltinFunction::DecodeURIComponent),
  )
  env_declare(env, "encodeURI", new_builtin_value(BuiltinFunction::EncodeURI))
  env_declare(
    env,
    "encodeURIComponent",
    new_builtin_value(BuiltinFunction::EncodeURIComponent),
  )
  env_declare(env, "escape", new_builtin_value(BuiltinFunction::Escape))
  env_declare(env, "unescape", new_builtin_value(BuiltinFunction::Unescape))
}

///|
fn declare_host_objects(
  env : Env,
  std_obj : JSValue,
  os_obj : JSValue,
  bjson_obj : JSValue,
) -> Unit {
  env_declare(env, "std", std_obj)
  env_declare(env, "os", os_obj)
  env_declare(env, "bjson", bjson_obj)
}

///|
fn set_global_intrinsics(global : JSValue) -> Unit {
  match global {
    Object(obj) => {
      obj.props.set("NaN", property_data_const(Number(nan())))
      obj.props.set("Infinity", property_data_const(Number(inf())))
      obj.props.set("undefined", property_data_const(Undefined))
    }
    _ => ()
  }
}

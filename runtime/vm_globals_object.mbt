///|
fn init_global_object(env : Env, object_proto_obj : ObjectValue) -> JSValue {
  let global = new_object_value_with_proto(Some(Object(object_proto_obj)))
  env.bindings.set("this", global)
  global
}

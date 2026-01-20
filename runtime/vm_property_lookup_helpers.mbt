///|
fn get_property_in_chain(proto : JSValue?, name : String) -> JSValue? raise {
  match proto {
    None => None
    Some(obj) => {
      let desc = get_own_property_descriptor(obj, name)
      match desc {
        Undefined => get_property_in_chain(get_proto_of_value(obj), name)
        _ => Some(desc)
      }
    }
  }
}

///|
fn global_property_value(name : String) -> JSValue? raise {
  match root_env() {
    Some(env) =>
      match global_object(env) {
        Some(obj) =>
          if has_property_in_chain(obj.props, obj.proto, name) {
            Some(property_get(JSValue::Object(obj), name))
          } else {
            None
          }
        None => None
      }
    None => None
  }
}

///|
fn props_map_for_value(value : JSValue) -> Map[String, Property]? {
  match value {
    Object(obj) => Some(obj.props)
    Function(func) => Some(func.props)
    BoundFunction(bound) => Some(bound.props)
    Builtin(builtin) => Some(builtin.props)
    Array(arr) => Some(arr.props)
    Arguments(args) => Some(args.props)
    _ => None
  }
}

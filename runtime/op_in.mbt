///|
pub fn JSValue::op_in(self : JSValue, other : JSValue) -> Bool {
  match other {
    Object(obj) => {
      let key = match self {
        String(s) => s.to_string()
        _ => self.to_json().stringify() // Fallback to string representation
      }
      obj.properties.contains(key)
    }
    _ => false // TODO: throw TypeError: right-hand side of 'in' should be an object
  }
}

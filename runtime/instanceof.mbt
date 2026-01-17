///|
pub fn JSValue::instanceof(self : JSValue, other : JSValue) -> Bool {
  let prototype = match other {
    Object(f) => f.properties.get("prototype")
    _ => return false // Right-hand side of 'instanceof' is not callable or doesn't have prototype
  }
  match prototype {
    Some(proto) => {
      let mut current = self
      loop current {
        Object({ prototype: Some(p), .. }) => {
          if p.strict_equal(proto) {
            return true
          }
          current = p
          continue p
        }
        _ => return false
      }
    }
    None => false
  }
}

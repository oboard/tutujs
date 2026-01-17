///|
pub fn JSValue::instanceof(self : JSValue, other : JSValue) -> Bool {
  let prototype = match other {
    Object(f) =>
      match f.properties.get("prototype") {
        Some(p) => p
        None => Undefined
      }
    _ => return false
  }
  match prototype {
    Object(_) => {
      let mut current = self
      // Handle wrappers
      match self {
        String(_) | Number(_) | Boolean(_) | BigInt(_) | Symbol(_, _) =>
          // Primitive values are not instances of their constructors
          return false
        _ => ()
      }
      loop current {
        Object({ prototype: Some(p), .. }) => {
          if p.strict_equal(prototype) {
            return true
          }
          current = p
          continue p
        }
        _ => return false
      }
    }
    _ => false
  }
}

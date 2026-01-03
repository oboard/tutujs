///|
pub fn JSValue::instanceof(self : JSValue, other : JSValue) -> Bool {
  let prototype = match other {
    Function(f) => f.properties.get("prototype")
    _ => return false // Right-hand side of 'instanceof' is not callable or doesn't have prototype
  }
  match prototype {
    Some(proto) => {
      let mut current = self
      loop current {
        Object(obj) =>
          match obj.prototype {
            Some(p) => {
              // Using strict_equal or referential equality
              // For objects/functions strict_equal checks identity (via physical_equal)
              if p.strict_equal(proto) {
                return true
              }
              current = p
              continue p
            }
            None => return false
          }
        Function(func) =>
          match func.prototype {
            Some(p) => {
              if p.strict_equal(proto) {
                return true
              }
              current = p
              continue p
            }
            None => return false
          }
        _ => return false
      }
    }
    None => false
  }
}

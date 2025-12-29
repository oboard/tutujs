///|
pub fn JSValue::unstrict_equal(self : JSValue, other : JSValue) -> Bool {
  fn eq_coercion(value : JSValue) -> JSValue {
    if value is Boolean(bool) {
      Number(if bool { 1.0 } else { 0.0 })
    } else {
      value
    }
  }

  let self = eq_coercion(self)
  let other = eq_coercion(other)
  if self == Number(@double.not_a_number) ||
    other == Number(@double.not_a_number) {
    false
  } else {
    match (self, other) {
      (Number(a), Number(b)) => a == b
      (String(a), Number(b)) =>
        (@strconv.parse_double(a) == b) catch {
          _ => false
        }
      (_, _) => false
    }
  }
}

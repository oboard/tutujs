///|
pub impl Sub for JSValue with sub(self, other) -> JSValue {
  fn sub_coercion(value : JSValue) -> JSValue {
    if value is Boolean(bool) {
      Number(if bool { 1.0 } else { 0.0 })
    } else {
      value
    }
  }

  let self = sub_coercion(self)
  let other = sub_coercion(other)
  match (self, other) {
    (Number(a), Number(b)) => Number(a - b)
    (String(a), Number(b)) =>
      Number((@strconv.parse_double(a) - b) catch { _ => @double.not_a_number })
    (_, _) => Number(@double.not_a_number)
  }
}

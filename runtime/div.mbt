///|
pub impl Div for JSValue with div(self, other) -> JSValue {
  fn div_coercion(value : JSValue) -> JSValue {
    if value is Boolean(bool) {
      Number(if bool { 1.0 } else { 0.0 })
    } else {
      value
    }
  }

  let self = div_coercion(self)
  let other = div_coercion(other)
  match (self, other) {
    (Number(a), Number(b)) => Number(a / b)
    (String(a), Number(b)) =>
      Number((@strconv.parse_double(a) / b) catch { _ => @double.not_a_number })
    (_, _) => Number(@double.not_a_number)
  }
}

///|
pub impl Mod for JSValue with mod(self, other) -> JSValue {
  fn mod_coercion(value : JSValue) -> JSValue {
    if value is Boolean(bool) {
      Number(if bool { 1.0 } else { 0.0 })
    } else {
      value
    }
  }

  let self = mod_coercion(self)
  let other = mod_coercion(other)
  match (self, other) {
    (Number(a), Number(b)) => Number(a % b)
    (String(a), Number(b)) =>
      Number((@strconv.parse_double(a) % b) catch { _ => @double.not_a_number })
    (_, _) => Number(@double.not_a_number)
  }
}

///|
pub impl Neg for JSValue with neg(self) -> JSValue {
  fn neg_coercion(value : JSValue) -> JSValue {
    if value is Boolean(bool) {
      Number(if bool { 1.0 } else { 0.0 })
    } else {
      value
    }
  }

  let self = neg_coercion(self)
  match self {
    Number(a) => Number(-a)
    String(a) =>
      Number(-(@strconv.parse_double(a) catch { _ => @double.not_a_number }))
    _ => Number(@double.not_a_number)
  }
}

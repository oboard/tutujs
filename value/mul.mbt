///|
pub impl Mul for JSValue with mul(self, other) -> JSValue {
  fn mul_coercion(value : JSValue) -> JSValue {
    if value is Boolean(bool) {
      Number(if bool { 1.0 } else { 0.0 })
    } else {
      value
    }
  }

  let self = mul_coercion(self)
  let other = mul_coercion(other)
  if self == Number(@double.not_a_number) ||
    other == Number(@double.not_a_number) {
    Number(@double.not_a_number)
  } else {
    match (self, other) {
      (Number(a), Number(b)) => Number(a * b)
      (String(a), Number(b)) =>
        Number(
          (@strconv.parse_double(a) * b) catch {
            _ => @double.not_a_number
          },
        )
      (_, _) => Number(@double.not_a_number)
    }
  }
}

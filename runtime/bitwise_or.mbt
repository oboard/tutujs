///|
pub fn JSValue::bitwise_or(self : JSValue, other : JSValue) -> JSValue {
  let left = self.to_int32()
  let right = other.to_int32()
  Number((left | right).to_double())
}

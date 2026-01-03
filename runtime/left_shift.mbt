///|
pub fn JSValue::left_shift(self : JSValue, other : JSValue) -> JSValue {
  let left = self.to_int32()
  let right = other.to_int32()
  Number((left << (right & 0x1F)).to_double())
}

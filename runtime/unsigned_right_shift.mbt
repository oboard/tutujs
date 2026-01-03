///|
pub fn JSValue::unsigned_right_shift(
  self : JSValue,
  other : JSValue,
) -> JSValue {
  let left = self.to_int32()
  let right = other.to_int32()
  let uleft : UInt = left.reinterpret_as_uint()
  let shift = right & 0x1F
  let res = uleft >> shift
  // UInt to Double conversion
  // If no direct conversion, we can convert to Int64 then Double
  Number(res.to_int64().to_double())
}

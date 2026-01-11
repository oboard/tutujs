///|
pub fn JSValue::pow(self : JSValue, other : JSValue) -> JSValue {
  match (self, other) {
    (Number(a), Number(b)) => Number(@math.pow(a, b))
    (BigInt(a), BigInt(b)) => BigInt(a.pow(b))
    (BigInt(_), Number(_)) | (Number(_), BigInt(_)) =>
      // TypeError: Cannot mix BigInt and other types
      Number(@double.not_a_number) // TODO: Throw actual TypeError
    _ => Number(@double.not_a_number)
  }
}

///|
pub fn JSValue::strict_equal(self : JSValue, other : JSValue) -> Bool {
  match (self, other) {
    (Undefined, Undefined) => true
    (Null, Null) => true
    (Number(a), Number(b)) =>
      if a.is_nan() || b.is_nan() {
        false
      } else {
        a == b
      }
    (String(a), String(b)) => a == b
    (Boolean(a), Boolean(b)) => a == b
    (BigInt(a), BigInt(b)) => a == b
    (Symbol(id1, _), Symbol(id2, _)) => id1 == id2
    (Object(a), Object(b)) => a._id == b._id
    _ => false
  }
}

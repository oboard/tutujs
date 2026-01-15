///|
pub fn JSValue::unstrict_equal(
  self : JSValue,
  other : JSValue,
  ctx : Context,
) -> Bool raise EvalError {
  match (self, other) {
    (Undefined, Undefined) => true
    (Null, Null) => true
    (Undefined, Null) => true
    (Null, Undefined) => true
    (Number(a), Number(b)) => a == b
    (String(a), String(b)) => a == b
    (Boolean(a), Boolean(b)) => a == b
    (BigInt(a), BigInt(b)) => a == b
    (Symbol(id1, _), Symbol(id2, _)) => id1 == id2
    (Object(a), Object(b)) => physical_equal(a, b)
    (Function(a), Function(b)) => physical_equal(a.base, b.base)
    (Object(a), Function(b)) => physical_equal(a, b.base)
    (Function(a), Object(b)) => physical_equal(a.base, b)
    (Number(a), String(b)) =>
      a ==
      (@strconv.parse_double(b.to_string()) catch { _ => @double.not_a_number })
    (String(a), Number(b)) =>
      (@strconv.parse_double(a.to_string()) catch { _ => @double.not_a_number }) ==
      b
    (BigInt(a), String(b)) =>
      (a == BigInt::from_string(b.to_string())) catch {
        _ => false
      }
    (String(a), BigInt(b)) =>
      (BigInt::from_string(a.to_string()) == b) catch {
        _ => false
      }
    (Boolean(_), _) =>
      JSValue::Number(self.to_number()).unstrict_equal(other, ctx)
    (_, Boolean(_)) =>
      self.unstrict_equal(JSValue::Number(other.to_number()), ctx)
    (String(_) | Number(_) | Symbol(_, _) | BigInt(_), Object(_) | Function(_)) =>
      self.unstrict_equal(to_primitive(ctx, other), ctx)
    (Object(_) | Function(_), String(_) | Number(_) | Symbol(_, _) | BigInt(_)) =>
      to_primitive(ctx, self).unstrict_equal(other, ctx)
    _ => false
  }
}

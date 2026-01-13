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
    (Object(a), Object(b))
    | (Function({ base: a, .. }), Function({ base: b, .. })) =>
      physical_equal(a.properties, b.properties)
    (Number(a), String(b)) =>
      a == (@strconv.parse_double(b) catch { _ => @double.not_a_number })
    (String(a), Number(b)) =>
      (@strconv.parse_double(a) catch { _ => @double.not_a_number }) == b
    (Boolean(_), _) =>
      JSValue::Number(self.to_number()).unstrict_equal(other, ctx)
    (_, Boolean(_)) =>
      self.unstrict_equal(JSValue::Number(other.to_number()), ctx)
    (String(_) | Number(_), Object(_)) =>
      self.unstrict_equal(to_primitive(ctx, other), ctx)
    (Object(_), String(_) | Number(_)) =>
      to_primitive(ctx, self).unstrict_equal(other, ctx)
    _ => false
  }
}

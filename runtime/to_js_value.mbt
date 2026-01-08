///|
pub(open) trait ToJSValue {
  to_js_value(self : Self) -> JSValue
}

///|
pub impl ToJSValue for JSValue with to_js_value(self) {
  self
}

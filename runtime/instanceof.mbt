///|
pub fn JSValue::instanceof(_self : JSValue, _other : JSValue) -> Bool {
  // TODO: Implement prototype chain check.
  // Current JSFunction definition does not store properties (like 'prototype'),
  // so we cannot retrieve the prototype object from the constructor 'other'.
  // Returning false for now.
  false
}

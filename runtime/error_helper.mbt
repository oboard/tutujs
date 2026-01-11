///|
pub fn Context::throw_error(
  self : Context,
  error_type : String,
  message : String,
) -> Unit raise EvalError {
  let ctor = match self.resolve(error_type) {
    Function(f) => f
    _ =>
      // If constructor not found, fallback to generic object or string?
      // For bootstrapping, maybe just panic or return string?
      // But we want to test error objects.
      // If we are here, likely the environment is set up.
      abort("Error constructor " + error_type + " not found")
  }
  let err_obj = self.invoke(ctor, JSValue::Undefined, [JSValue::String(message)]) catch {
    _ => JSValue::String(error_type + ": " + message)
  }
  raise EvalError::Throw(err_obj)
}

///|
pub fn Context::throw_type_error(
  self : Context,
  message : String,
) -> Unit raise EvalError {
  self.throw_error("TypeError", message)
}

///|
pub fn Context::throw_reference_error(
  self : Context,
  message : String,
) -> Unit raise EvalError {
  self.throw_error("ReferenceError", message)
}

///|
pub fn Context::throw_range_error(
  self : Context,
  message : String,
) -> Unit raise EvalError {
  self.throw_error("RangeError", message)
}

///|
pub fn Context::throw_syntax_error(
  self : Context,
  message : String,
) -> Unit raise EvalError {
  self.throw_error("SyntaxError", message)
}

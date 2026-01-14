///|
pub fn[T] Context::throw_error(
  self : Context,
  error_type : String,
  message : String,
) -> T raise EvalError {
  let ctor = match self.resolve(error_type) {
    Function(f) => f
    _ => abort("Error constructor " + error_type + " not found")
  }
  let err_obj = self.invoke(ctor, JSValue::Undefined, [JSValue::String(message)]) catch {
    _ => JSValue::String(error_type + ": " + message)
  }
  raise EvalError::Throw(err_obj)
}

///|
pub fn[T] Context::throw_type_error(
  self : Context,
  message : String,
) -> T raise EvalError {
  self.throw_error("TypeError", message)
}

///|
pub fn[T] Context::throw_reference_error(
  self : Context,
  message : String,
) -> T raise EvalError {
  self.throw_error("ReferenceError", message)
}

///|
pub fn[T] Context::throw_range_error(
  self : Context,
  message : String,
) -> T raise EvalError {
  self.throw_error("RangeError", message)
}

///|
pub fn[T] Context::throw_syntax_error(
  self : Context,
  message : String,
) -> T raise EvalError {
  self.throw_error("SyntaxError", message)
}

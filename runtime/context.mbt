///|
pub(all) struct Context {
  scope : @hashmap.HashMap[String, JSValue]
  parent : Context?
} derive(Show)

///|
pub impl Eq for Context with equal(_, _) {
  // Simple reference equality check if possible, or always false for now
  false
}

///|
pub impl ToJson for Context with to_json(_) {
  JSValue::Null.to_json()
}

///|
pub impl FromJson for Context with from_json(_, _) {
  Context::new()
}

///|
#as_free_fn(new)
pub fn Context::new(parent? : Context) -> Context {
  let scope = @hashmap.new()
  match parent {
    None => {
      scope.set("NaN", Number(@double.not_a_number))
      scope.set("Infinity", Number(@double.infinity))
    }
    Some(_) => ()
  }
  { scope, parent }
}

///|
pub impl Compare for Context with compare(_, _) -> Int {
  0
}

///|
pub impl Hash for Context with hash_combine(_, _) -> Unit {
  // Not implemented
}

///|
pub(all) struct Context {
  scope : Map[String, JSValue]
  parent : Context?
} derive(Eq, ToJson, FromJson, Show)

///|
pub fn Context::new(parent? : Context) -> Context {
  let scope = Map::new()
  match parent {
    None => {
      scope.set("NaN", Number(@double.not_a_number))
      scope.set("Infinity", Number(@double.infinity))
      scope.set("undefined", Undefined)
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
pub impl Hash for Context with hash_combine(self, hasher) -> Unit {
  hasher.combine(self.scope.length())
}

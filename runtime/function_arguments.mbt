///|
pub struct JSArgs(Array[JSValue])

///|
pub fn JSArgs::new(arr : Array[JSValue]) -> JSArgs {
  arr
}

///|
pub fn JSArgs::empty() -> JSArgs {
  []
}

///|
pub fn JSArgs::length(self : JSArgs) -> Int {
  self.0.length()
}

///|
pub fn JSArgs::iter(self : JSArgs) -> Iter[JSValue] {
  self.0.iter()
}

///|
pub fn JSArgs::iter2(self : JSArgs) -> Iter2[Int, JSValue] {
  self.0.iter2()
}

///|
#alias("_[_]")
pub fn JSArgs::get(self : JSArgs, index : Int) -> JSValue {
  self.0.get(index).unwrap_or(JSValue::Undefined)
}

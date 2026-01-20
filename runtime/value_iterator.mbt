///|
pub struct IteratorWrapData {
  wrapped_iter : JSValue
  wrapped_next : JSValue
}

///|
pub struct IteratorConcatData {
  mut index : Int
  count : Int
  mut running : Bool
  mut iter : JSValue
  mut next : JSValue
  values : Array[(JSValue, JSValue)]
}

///|
pub struct IteratorHelperData {
  obj : JSValue
  next : JSValue
  func : JSValue
  mut inner : JSValue
  mut inner_next : JSValue
  mut count : Int64
  kind : Int
  mut executing : Bool
  mut done : Bool
}

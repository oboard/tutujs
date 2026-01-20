///|
pub struct MapData {
  entries : Array[(JSValue, JSValue)?]
}

///|
pub struct WeakMapData {
  entries : Array[(JSValue, JSValue)]
}

///|
pub struct MapIteratorData {
  entries : Array[(JSValue, JSValue)?]
  mut index : Int
  kind : Int
  mut done : Bool
}

///|
pub struct SetData {
  entries : Array[JSValue?]
}

///|
pub struct SetIteratorData {
  entries : Array[JSValue?]
  mut index : Int
  kind : Int
  mut done : Bool
}

///|
pub struct WeakSetData {
  entries : Array[JSValue]
}

///|
pub struct WeakRefData {
  target : JSValue
}

///|
pub struct FinalizationEntry {
  target : JSValue
  held_value : JSValue
  mut token : JSValue
}

///|
pub struct FinalizationRegistryData {
  callback : JSValue
  entries : Array[FinalizationEntry]
  realm_env : Env
}

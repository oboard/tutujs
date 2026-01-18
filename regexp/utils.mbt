///|
fn is_lead_surrogate(code : Int) -> Bool {
  code >= 0xD800 && code <= 0xDBFF
}

///|
fn is_trail_surrogate(code : Int) -> Bool {
  code >= 0xDC00 && code <= 0xDFFF
}

///|
fn advance_string_index(value : String, index : Int, unicode : Bool) -> Int {
  if !unicode {
    return index + 1
  }
  let len = value.length()
  if index + 1 >= len {
    return index + 1
  }
  let first = UInt16::to_int(value.code_unit_at(index))
  let second = UInt16::to_int(value.code_unit_at(index + 1))
  if is_lead_surrogate(first) && is_trail_surrogate(second) {
    index + 2
  } else {
    index + 1
  }
}

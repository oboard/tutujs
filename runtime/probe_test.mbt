///|
test "Slicing surrogate pair" {
  let s = "\u{1D306}"
  println("s len: " + s.length().to_string())
  let sub = s[1:2]
  println("s[1:2] len: " + sub.length().to_string())
  let low = Char::from_int(0xDF06).to_string()
  if sub == low {
    println("Slice matches low surrogate")
  } else {
    println("Slice DOES NOT match low surrogate")
  }
}

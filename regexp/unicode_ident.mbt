///|
fn ranges_sorted(ranges : Array[Range]) -> Array[Range] {
  let sorted = ranges.copy()
  sorted.sort_by(fn(a, b) { a.start - b.start })
  sorted
}

///|
fn ranges_normalize(ranges : Array[Range]) -> Array[Range] {
  if ranges.is_empty() {
    return []
  }
  let sorted = ranges_sorted(ranges)
  let result : Array[Range] = []
  let mut current = sorted[0]
  let mut i = 1
  while i < sorted.length() {
    let next = sorted[i]
    if next.start <= current.end + 1 {
      if next.end > current.end {
        current = Range::{ start: current.start, end: next.end }
      }
    } else {
      result.push(current)
      current = next
    }
    i = i + 1
  }
  result.push(current)
  result
}

///|
fn ranges_contains(ranges : Array[Range], code : Int) -> Bool {
  for r in ranges {
    if code >= r.start && code <= r.end {
      return true
    }
  }
  false
}

///|
fn unicode_prop_ranges_from_bytes(data : Bytes) -> Array[Range] {
  let ranges : Array[Range] = []
  let mut c = 0
  let mut bit = 0
  let mut i = 0
  while i < data.length() {
    let start = c
    let b = byte_at(data, i)
    i = i + 1
    if b < 64 {
      c = c + (b >> 3) + 1
      if bit != 0 {
        add_range_exclusive(ranges, start, c)
      }
      bit = bit ^ 1
      let start2 = c
      c = c + (b & 7) + 1
      if bit != 0 {
        add_range_exclusive(ranges, start2, c)
      }
      bit = bit ^ 1
      continue
    }
    if b >= 0x80 {
      c = c + (b - 0x80) + 1
    } else if b < 0x60 {
      c = c + (((b - 0x40) << 8) | byte_at(data, i)) + 1
      i = i + 1
    } else {
      c = c +
        (((b - 0x60) << 16) | (byte_at(data, i) << 8) | byte_at(data, i + 1)) +
        1
      i = i + 2
    }
    if bit != 0 {
      add_range_exclusive(ranges, start, c)
    }
    bit = bit ^ 1
  }
  ranges_normalize(ranges)
}

///|
let id_start_ranges : Array[Range] = unicode_prop_ranges_from_bytes(
  unicode_prop_ID_Start_table,
)

///|
let id_continue_ranges : Array[Range] = unicode_prop_ranges_from_bytes(
  unicode_prop_ID_Continue1_table,
)

///|
pub fn unicode_is_ident_start(code : Int) -> Bool {
  ranges_contains(id_start_ranges, code)
}

///|
pub fn unicode_is_ident_continue(code : Int) -> Bool {
  unicode_is_ident_start(code) || ranges_contains(id_continue_ranges, code)
}

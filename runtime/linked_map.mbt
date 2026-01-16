///|
pub(all) struct LinkedEntry {
  key : JSValue
  mut value : JSValue
  mut prev : LinkedEntry?
  mut next : LinkedEntry?
  mut removed : Bool
} derive(Show, ToJson)

///|
pub impl Eq for LinkedEntry with equal(self, other) {
  physical_equal(self, other)
}

///|
pub(all) struct LinkedMap {
  entries : Map[JSValue, LinkedEntry]
  mut head : LinkedEntry?
  mut tail : LinkedEntry?
}

///|
pub fn LinkedMap::new() -> LinkedMap {
  { entries: {}, head: None, tail: None }
}

///|
pub fn LinkedMap::set(self : LinkedMap, key : JSValue, value : JSValue) -> Unit {
  match self.entries.get(key) {
    Some(entry) => entry.value = value
    None => {
      let entry = { key, value, prev: self.tail, next: None, removed: false }
      match self.tail {
        Some(tail) => tail.next = Some(entry)
        None => self.head = Some(entry)
      }
      self.tail = Some(entry)
      self.entries.set(key, entry)
    }
  }
}

///|
pub fn LinkedMap::get(self : LinkedMap, key : JSValue) -> JSValue? {
  match self.entries.get(key) {
    Some(entry) => Some(entry.value)
    None => None
  }
}

///|
pub fn LinkedMap::contains(self : LinkedMap, key : JSValue) -> Bool {
  self.entries.contains(key)
}

///|
pub fn LinkedMap::remove(self : LinkedMap, key : JSValue) -> Unit {
  match self.entries.get(key) {
    Some(entry) => {
      entry.removed = true
      // Update prev
      match entry.prev {
        Some(prev) => prev.next = entry.next
        None => self.head = entry.next
      }
      // Update next
      match entry.next {
        Some(next) => next.prev = entry.prev
        None => self.tail = entry.prev
      }
      self.entries.remove(key)
    }
    None => ()
  }
}

///|
pub fn LinkedMap::clear(self : LinkedMap) -> Unit {
  self.entries.clear()
  self.head = None
  self.tail = None
}

///|
pub fn LinkedMap::length(self : LinkedMap) -> Int {
  self.entries.length()
}

///|
pub fn LinkedMap::each(
  self : LinkedMap,
  f : ((JSValue, JSValue)) -> Unit,
) -> Unit {
  let mut current = self.head
  while true {
    match current {
      Some(entry) => {
        f((entry.key, entry.value))
        current = entry.next
      }
      None => break
    }
  }
}

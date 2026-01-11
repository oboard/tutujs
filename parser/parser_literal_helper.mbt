///|
fn parse_regex_token(value : StringView) -> (String, Array[RegExpFlag]) {
  let s = value.to_string()
  let chars = s.to_array()
  let len = chars.length()
  let mut last_slash = -1
  for i = len - 1; i >= 0; i = i - 1 {
    if chars[i] == '/' {
      last_slash = i
      break
    }
  }
  if last_slash <= 0 {
    ("", [])
  } else {
    try {
      let pattern_view = s[1:last_slash]
      let flags_view = s[last_slash + 1:]
      let pattern = pattern_view.to_string()
      let flags = []
      for char in flags_view {
        match char {
          'g' => flags.push(RegExpFlag::G)
          'i' => flags.push(RegExpFlag::I)
          'm' => flags.push(RegExpFlag::M)
          's' => flags.push(RegExpFlag::S)
          'u' => flags.push(RegExpFlag::U)
          'y' => flags.push(RegExpFlag::Y)
          'v' => flags.push(RegExpFlag::V)
          _ => ()
        }
      }
      (pattern, flags)
    } catch {
      _ => ("", [])
    }
  }
}

///|
pub fn unescape_string_literal(s : String) -> String {
  let chars = s.to_array()
  let len = chars.length()
  let mut res = ""
  let mut i = 0
  while i < len {
    if chars[i] == '\\' {
      i = i + 1
      if i >= len {
        break
      }
      match chars[i] {
        'n' => res = res + "\n"
        'r' => res = res + "\r"
        't' => res = res + "\t"
        'b' => res = res + "\u0008"
        'f' => res = res + "\u000C"
        'v' => res = res + "\u000B"
        '\'' => res = res + "'"
        '"' => res = res + "\""
        '\\' => res = res + "\\"
        '0' => res = res + "\u0000"
        'x' =>
          if i + 2 < len {
            let hex = s[i + 1:i + 3] catch { _ => "" }
            let code = @strconv.parse_int(hex, base=16) catch { _ => -1 }
            if code >= 0 {
              res = res + Int::unsafe_to_char(code).to_string()
              i = i + 2
            } else {
              res = res + "x"
            }
          } else {
            res = res + "x"
          }
        'u' =>
          if i + 4 < len {
            let hex = s[i + 1:i + 5] catch { _ => "" }
            let code = @strconv.parse_int(hex, base=16) catch { _ => -1 }
            if code >= 0 {
              res = res + Int::unsafe_to_char(code).to_string()
              i = i + 4
            } else {
              res = res + "u"
            }
          } else {
            res = res + "u"
          }
        c => res = res + c.to_string()
      }
    } else {
      res = res + chars[i].to_string()
    }
    i = i + 1
  }
  res
}

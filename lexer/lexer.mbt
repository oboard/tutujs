///|
pub(all) struct LexToken {
  kind : @tokens.TokenKind
  value : StringView
  line : Int
  column : Int
} derive(Show, ToJson, Eq)

///|
pub(all) struct Lexer {
  input : String
  mut position : Int
  mut line : Int
  mut line_start : Int
  mut tokens : Array[LexToken]
  mut errors : Array[String]
  mut json_mode : Bool
}

///|
pub fn Lexer::new(input : String) -> Lexer {
  {
    input,
    position: 0,
    line: 1,
    line_start: 0,
    tokens: [],
    errors: [],
    json_mode: false,
  }
}

///|
pub fn Lexer::set_json_mode(self : Lexer, mode : Bool) -> Unit {
  self.json_mode = mode
}

///|
fn Lexer::add_token(
  self : Lexer,
  kind : @tokens.TokenKind,
  value : StringView,
) -> Unit {
  let column = self.position - self.line_start + 1
  self.position += value.length()
  self.tokens.push({ kind, value, line: self.line, column })
}

///|
pub fn Lexer::tokenize(self : Lexer) -> Array[LexToken] {
  let input = self.input
  lex_tokens(input, self)
  let needs_eof = match self.tokens.last() {
    Some(t) => t.kind != @tokens.TokenKind::EOF
    None => true
  }
  if needs_eof {
    self.tokens.push({
      kind: @tokens.TokenKind::EOF,
      value: "EOF",
      line: self.line,
      column: self.position - self.line_start + 1,
    })
  }
  self.tokens
}

///|
fn lex_tokens(input : StringView, lexer : Lexer) -> Unit {
  lexmatch input with longest {
    ("`" ("([^`\\\\]|\\\\.)*" as raw) "`", rest) => {
      lexer.add_token(@tokens.TokenKind::StringLiteral, raw)
      lexer.position += 2
      lex_tokens(rest, lexer)
    }

    // Whitespace
    ("[ \t\r]+" as raw, rest) => {
      lexer.position += raw.length()
      lex_tokens(rest, lexer)
    }

    // Newlines
    ("\n|\r|\r\n|\u2028|\u2029" as raw, rest) => {
      if lexer.json_mode && (raw == "\u2028" || raw == "\u2029") {
        lexer.errors.push("Invalid JSON whitespace")
        lexer.add_token(@tokens.TokenKind::Illegal, raw)
      }
      lexer.line += 1
      lexer.position += raw.length()
      lexer.line_start = lexer.position
      lex_tokens(rest, lexer)
    }

    // Comments
    ("//[^\r\n]*" as raw, rest) => {
      if lexer.json_mode {
        lexer.errors.push("Comments not allowed in JSON")
        lexer.add_token(@tokens.TokenKind::Illegal, raw)
      }
      lexer.position += raw.length()
      lex_tokens(rest, lexer)
    }
    ("/\*[^*]*\*+([^/*][^*]*\*+)*/" as raw, rest) => {
      if lexer.json_mode {
        lexer.errors.push("Comments not allowed in JSON")
        lexer.add_token(@tokens.TokenKind::Illegal, raw)
      }
      lexer.position += raw.length()
      // Count newlines in block comment
      for i = 0; i < raw.length(); i = i + 1 {
        if raw[i] == '\n' {
          lexer.line += 1
          // line_start needs to be updated to position after this newline
          // But calculating absolute position of this newline is tricky relative to start of raw?
          // Actually, if we just update line count, column will be wrong for the rest of the comment?
          // But for subsequent tokens, line_start needs to be correct (start of last line).
          // We can find the LAST newline index.
        }
      }
      // Find last newline to update line_start
      let mut last_nl = -1
      for i = 0; i < raw.length(); i = i + 1 {
        if raw[i] == '\n' || raw[i] == '\r' { // Simplification
          last_nl = i
        }
      }
      if last_nl != -1 {
        // line_start is start of block comment + last_nl + 1
        // lexer.position is already at end of block comment.
        // Wait. lexer.position BEFORE adding raw.length() was start of comment.
        // So line_start = (lexer.position - raw.length()) + last_nl + 1
        lexer.line_start = lexer.position - raw.length() + last_nl + 1
      }
      lex_tokens(rest, lexer)
    }

    // Boolean literals
    ("true|false" as raw, rest) => {
      lexer.add_token(@tokens.TokenKind::BooleanLiteral, raw)
      lex_tokens(rest, lexer)
    }

    // String literals
    ("\"" ("([^\\\"\\\\]|[\\\\].)*" as raw) "\"", rest) => {
      // Check for control characters
      let len = raw.length()
      let mut i = 0
      while i < len {
        let c = raw[i]
        if c == '\\' {
          i = i + 2
          continue
        }
        if c < '\u0020' {
          lexer.errors.push("Control character in string literal")
        }
        i = i + 1
      }
      lexer.add_token(@tokens.TokenKind::StringLiteral, raw)
      lexer.position += 2
      lex_tokens(rest, lexer)
    }
    ("'" ("([^'\\\\]|[\\\\].)*" as raw) "'", rest) => {
      lexer.add_token(@tokens.TokenKind::StringLiteral, raw)
      lexer.position += 2
      lex_tokens(rest, lexer)
    }

    // Numeric literals
    ("0x[0-9a-fA-F](_|[0-9a-fA-F])*(n)?" as raw, rest) => {
      lexer.add_token(@tokens.TokenKind::NumericLiteral, raw)
      lex_tokens(rest, lexer)
    }
    ("0X[0-9a-fA-F](_|[0-9a-fA-F])*(n)?" as raw, rest) => {
      lexer.add_token(@tokens.TokenKind::NumericLiteral, raw)
      lex_tokens(rest, lexer)
    }
    ("0o[0-7](_|[0-7])*(n)?" as raw, rest) => {
      lexer.add_token(@tokens.TokenKind::NumericLiteral, raw)
      lex_tokens(rest, lexer)
    }
    ("0O[0-7](_|[0-7])*(n)?" as raw, rest) => {
      lexer.add_token(@tokens.TokenKind::NumericLiteral, raw)
      lex_tokens(rest, lexer)
    }
    ("0b[01](_|[01])*(n)?" as raw, rest) => {
      lexer.add_token(@tokens.TokenKind::NumericLiteral, raw)
      lex_tokens(rest, lexer)
    }
    ("0B[01](_|[01])*(n)?" as raw, rest) => {
      lexer.add_token(@tokens.TokenKind::NumericLiteral, raw)
      lex_tokens(rest, lexer)
    }
    // Decimal with dot, no exponent
    ("[0-9](_|[0-9])*\.[0-9](_|[0-9])*" as raw, rest) => {
      lexer.add_token(@tokens.TokenKind::NumericLiteral, raw)
      lex_tokens(rest, lexer)
    }
    // Decimal with dot and exponent signed +
    ("[0-9](_|[0-9])*\.[0-9](_|[0-9])*[eE]\+[0-9](_|[0-9])*" as raw, rest) => {
      lexer.add_token(@tokens.TokenKind::NumericLiteral, raw)
      lex_tokens(rest, lexer)
    }
    // Decimal with dot and exponent signed -
    ("[0-9](_|[0-9])*\.[0-9](_|[0-9])*[eE]-[0-9](_|[0-9])*" as raw, rest) => {
      lexer.add_token(@tokens.TokenKind::NumericLiteral, raw)
      lex_tokens(rest, lexer)
    }
    // Decimal with dot and exponent unsigned
    ("[0-9](_|[0-9])*\.[0-9](_|[0-9])*[eE][0-9](_|[0-9])*" as raw, rest) => {
      lexer.add_token(@tokens.TokenKind::NumericLiteral, raw)
      lex_tokens(rest, lexer)
    }
    // Decimal without dot, with exponent signed +
    ("[0-9](_|[0-9])*[eE]\+[0-9](_|[0-9])*" as raw, rest) => {
      lexer.add_token(@tokens.TokenKind::NumericLiteral, raw)
      lex_tokens(rest, lexer)
    }
    // Decimal without dot, with exponent signed -
    ("[0-9](_|[0-9])*[eE]-[0-9](_|[0-9])*" as raw, rest) => {
      lexer.add_token(@tokens.TokenKind::NumericLiteral, raw)
      lex_tokens(rest, lexer)
    }
    // Decimal without dot, with exponent unsigned
    ("[0-9](_|[0-9])*[eE][0-9](_|[0-9])*" as raw, rest) => {
      lexer.add_token(@tokens.TokenKind::NumericLiteral, raw)
      lex_tokens(rest, lexer)
    }
    // Dot starting, no exponent
    ("\.[0-9](_|[0-9])*" as raw, rest) => {
      lexer.add_token(@tokens.TokenKind::NumericLiteral, raw)
      lex_tokens(rest, lexer)
    }
    // Dot starting, with exponent signed +
    ("\.[0-9](_|[0-9])*[eE]\+[0-9](_|[0-9])*" as raw, rest) => {
      lexer.add_token(@tokens.TokenKind::NumericLiteral, raw)
      lex_tokens(rest, lexer)
    }
    // Dot starting, with exponent signed -
    ("\.[0-9](_|[0-9])*[eE]-[0-9](_|[0-9])*" as raw, rest) => {
      lexer.add_token(@tokens.TokenKind::NumericLiteral, raw)
      lex_tokens(rest, lexer)
    }
    // Dot starting, with exponent unsigned
    ("\.[0-9](_|[0-9])*[eE][0-9](_|[0-9])*" as raw, rest) => {
      lexer.add_token(@tokens.TokenKind::NumericLiteral, raw)
      lex_tokens(rest, lexer)
    }
    // Plain integer
    ("[0-9](_|[0-9])*(n)?" as raw, rest) => {
      lexer.add_token(@tokens.TokenKind::NumericLiteral, raw)
      lex_tokens(rest, lexer)
    }

    // Identifiers
    ("[a-zA-Z_$][a-zA-Z0-9_$]*" as raw, rest) => {
      let kind = match keyword_table.get(raw.to_string()) {
        Some(k) => k
        None => @tokens.TokenKind::Identifier
      }
      lexer.add_token(kind, raw)
      lex_tokens(rest, lexer)
    }

    // Operators
    ("\.\.\." as raw, rest) => {
      lexer.add_token(@tokens.TokenKind::Ellipsis, raw)
      lex_tokens(rest, lexer)
    }
    ("===" as raw, rest) => {
      lexer.add_token(@tokens.TokenKind::EqualEqualEqual, raw)
      lex_tokens(rest, lexer)
    }
    ("!==" as raw, rest) => {
      lexer.add_token(@tokens.TokenKind::ExclamationEqualEqual, raw)
      lex_tokens(rest, lexer)
    }
    (">>>" as raw, rest) => {
      lexer.add_token(@tokens.TokenKind::UnsignedRightShift, raw)
      lex_tokens(rest, lexer)
    }
    (">>>=" as raw, rest) => {
      lexer.add_token(@tokens.TokenKind::UnsignedRightShiftEqual, raw)
      lex_tokens(rest, lexer)
    }
    ("<<=" as raw, rest) => {
      lexer.add_token(@tokens.TokenKind::LeftShiftEqual, raw)
      lex_tokens(rest, lexer)
    }
    (">>=" as raw, rest) => {
      lexer.add_token(@tokens.TokenKind::RightShiftEqual, raw)
      lex_tokens(rest, lexer)
    }
    ("\*\*=" as raw, rest) => {
      lexer.add_token(@tokens.TokenKind::StarStarEqual, raw)
      lex_tokens(rest, lexer)
    }
    ("\*\*" as raw, rest) => {
      lexer.add_token(@tokens.TokenKind::StarStar, raw)
      lex_tokens(rest, lexer)
    }
    (">>" as raw, rest) => {
      lexer.add_token(@tokens.TokenKind::RightShift, raw)
      lex_tokens(rest, lexer)
    }
    ("<<" as raw, rest) => {
      lexer.add_token(@tokens.TokenKind::LeftShift, raw)
      lex_tokens(rest, lexer)
    }
    ("==" as raw, rest) => {
      lexer.add_token(@tokens.TokenKind::EqualEqual, raw)
      lex_tokens(rest, lexer)
    }
    ("!=" as raw, rest) => {
      lexer.add_token(@tokens.TokenKind::ExclamationEqual, raw)
      lex_tokens(rest, lexer)
    }
    ("<=" as raw, rest) => {
      lexer.add_token(@tokens.TokenKind::LessThanOrEqual, raw)
      lex_tokens(rest, lexer)
    }
    (">=" as raw, rest) => {
      lexer.add_token(@tokens.TokenKind::GreaterThanOrEqual, raw)
      lex_tokens(rest, lexer)
    }
    ("&&" as raw, rest) => {
      lexer.add_token(@tokens.TokenKind::AmpersandAmpersand, raw)
      lex_tokens(rest, lexer)
    }
    ("\|\|" as raw, rest) => {
      lexer.add_token(@tokens.TokenKind::BarBar, raw)
      lex_tokens(rest, lexer)
    }
    ("\?\?" as raw, rest) => {
      lexer.add_token(@tokens.TokenKind::QuestionQuestion, raw)
      lex_tokens(rest, lexer)
    }
    ("\+\+" as raw, rest) => {
      lexer.add_token(@tokens.TokenKind::PlusPlus, raw)
      lex_tokens(rest, lexer)
    }
    ("--" as raw, rest) => {
      lexer.add_token(@tokens.TokenKind::MinusMinus, raw)
      lex_tokens(rest, lexer)
    }
    ("=>" as raw, rest) => {
      lexer.add_token(@tokens.TokenKind::Arrow, raw)
      lex_tokens(rest, lexer)
    }
    ("\+=" as raw, rest) => {
      lexer.add_token(@tokens.TokenKind::PlusEqual, raw)
      lex_tokens(rest, lexer)
    }
    ("-=" as raw, rest) => {
      lexer.add_token(@tokens.TokenKind::MinusEqual, raw)
      lex_tokens(rest, lexer)
    }
    ("\*=" as raw, rest) => {
      lexer.add_token(@tokens.TokenKind::StarEqual, raw)
      lex_tokens(rest, lexer)
    }
    ("/=" as raw, rest) => {
      lexer.add_token(@tokens.TokenKind::SlashEqual, raw)
      lex_tokens(rest, lexer)
    }
    ("%=" as raw, rest) => {
      lexer.add_token(@tokens.TokenKind::PercentEqual, raw)
      lex_tokens(rest, lexer)
    }
    ("&=" as raw, rest) => {
      lexer.add_token(@tokens.TokenKind::AmpersandEqual, raw)
      lex_tokens(rest, lexer)
    }
    ("\|=" as raw, rest) => {
      lexer.add_token(@tokens.TokenKind::PipeEqual, raw)
      lex_tokens(rest, lexer)
    }
    ("\^=" as raw, rest) => {
      lexer.add_token(@tokens.TokenKind::CaretEqual, raw)
      lex_tokens(rest, lexer)
    }

    // Single character operators
    ("[{]", rest) => {
      lexer.add_token(@tokens.TokenKind::LBrace, "{")
      lex_tokens(rest, lexer)
    }
    ("[}]", rest) => {
      lexer.add_token(@tokens.TokenKind::RBrace, "}")
      lex_tokens(rest, lexer)
    }
    ("\(", rest) => {
      lexer.add_token(@tokens.TokenKind::LParen, "(")
      lex_tokens(rest, lexer)
    }
    ("\)", rest) => {
      lexer.add_token(@tokens.TokenKind::RParen, ")")
      lex_tokens(rest, lexer)
    }
    ("\[", rest) => {
      lexer.add_token(@tokens.TokenKind::LBracket, "[")
      lex_tokens(rest, lexer)
    }
    ("\]", rest) => {
      lexer.add_token(@tokens.TokenKind::RBracket, "]")
      lex_tokens(rest, lexer)
    }
    ("\.\.\.", rest) => {
      lexer.add_token(@tokens.TokenKind::Ellipsis, "...")
      lex_tokens(rest, lexer)
    }
    ("\.", rest) => {
      lexer.add_token(@tokens.TokenKind::Dot, ".")
      lex_tokens(rest, lexer)
    }
    (";", rest) => {
      lexer.add_token(@tokens.TokenKind::Semicolon, ";")
      lex_tokens(rest, lexer)
    }
    (",", rest) => {
      lexer.add_token(@tokens.TokenKind::Comma, ",")
      lex_tokens(rest, lexer)
    }
    ("\?", rest) => {
      lexer.add_token(@tokens.TokenKind::Question, "?")
      lex_tokens(rest, lexer)
    }
    (":", rest) => {
      lexer.add_token(@tokens.TokenKind::Colon, ":")
      lex_tokens(rest, lexer)
    }
    ("=", rest) => {
      lexer.add_token(@tokens.TokenKind::Equal, "=")
      lex_tokens(rest, lexer)
    }
    ("\+", rest) => {
      lexer.add_token(@tokens.TokenKind::Plus, "+")
      lex_tokens(rest, lexer)
    }
    ("-", rest) => {
      lexer.add_token(@tokens.TokenKind::Minus, "-")
      lex_tokens(rest, lexer)
    }
    ("\*", rest) => {
      lexer.add_token(@tokens.TokenKind::Star, "*")
      lex_tokens(rest, lexer)
    }
    ("/", rest) =>
      if is_regex_start(lexer) {
        lexmatch rest {
          (("([^/\\\\\n\r]|\\\\.)*" as body) "/" ("[a-zA-Z]*" as flags), rest2) => {
            let full = "/" + body.to_string() + "/" + flags.to_string()
            lexer.add_token(@tokens.TokenKind::RegularExpressionLiteral, full)
            lex_tokens(rest2, lexer)
          }
          _ => {
            lexer.add_token(@tokens.TokenKind::Slash, "/")
            lex_tokens(rest, lexer)
          }
        }
      } else {
        lexer.add_token(@tokens.TokenKind::Slash, "/")
        lex_tokens(rest, lexer)
      }
    ("%", rest) => {
      lexer.add_token(@tokens.TokenKind::Percent, "%")
      lex_tokens(rest, lexer)
    }
    ("&", rest) => {
      lexer.add_token(@tokens.TokenKind::Ampersand, "&")
      lex_tokens(rest, lexer)
    }
    ("\|", rest) => {
      lexer.add_token(@tokens.TokenKind::Pipe, "|")
      lex_tokens(rest, lexer)
    }
    ("\^", rest) => {
      lexer.add_token(@tokens.TokenKind::Caret, "^")
      lex_tokens(rest, lexer)
    }
    ("!", rest) => {
      lexer.add_token(@tokens.TokenKind::Exclamation, "!")
      lex_tokens(rest, lexer)
    }
    ("~", rest) => {
      lexer.add_token(@tokens.TokenKind::Tilde, "~")
      lex_tokens(rest, lexer)
    }
    ("<", rest) => {
      lexer.add_token(@tokens.TokenKind::LessThan, "<")
      lex_tokens(rest, lexer)
    }
    (">", rest) => {
      lexer.add_token(@tokens.TokenKind::GreaterThan, ">")
      lex_tokens(rest, lexer)
    }

    // Error case
    ("." as c, rest) => {
      let start = lexer.line_start
      let mut end = lexer.input.length()
      let mut i = start
      while i < end {
        if lexer.input[i] == '\n' {
          end = i
          break
        }
        i = i + 1
      }
      // let line_content = lexer.input.substring(start=start, end=end)
      // println("Lexer Illegal: '" + c.to_string() + "' at line " + lexer.line.to_string() + " column " + (lexer.position - lexer.line_start + 1).to_string())
      // println("Line content: " + line_content)
      // println("Char code at position: " + lexer.input[lexer.position].to_int().to_string())
      // if lexer.position > 0 {
      //   println("Prev char code: " + lexer.input[lexer.position - 1].to_int().to_string())
      // }
      // if lexer.position + 1 < lexer.input.length() {
      //   println("Next char code: " + lexer.input[lexer.position + 1].to_int().to_string())
      // }
      lexer.add_token(@tokens.TokenKind::Illegal, c.to_string())
      lex_tokens(rest, lexer)
    }
    _ => ()
  }
}

///|
pub fn parse(code : String) -> Array[LexToken] {
  let lexer = Lexer::new(code)
  lexer.tokenize()
}

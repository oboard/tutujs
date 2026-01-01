///|
pub(all) struct LexToken {
  kind : @tokens.TokenKind
  value : StringView
  line : Int
  column : Int
} derive(Show, ToJson, Eq)

///|
let keyword_table : @immut/hashmap.HashMap[String, @tokens.TokenKind] = @immut/hashmap.HashMap::from_array([
    ("break", @tokens.TokenKind::Break),
    ("case", @tokens.TokenKind::Case),
    ("catch", @tokens.TokenKind::Catch),
    ("class", @tokens.TokenKind::Class),
    ("const", @tokens.TokenKind::Const),
    ("continue", @tokens.TokenKind::Continue),
    ("debugger", @tokens.TokenKind::Debugger),
    ("default", @tokens.TokenKind::Default),
    ("delete", @tokens.TokenKind::Delete),
    ("do", @tokens.TokenKind::Do),
    ("else", @tokens.TokenKind::Else),
    ("export", @tokens.TokenKind::Export),
    ("extends", @tokens.TokenKind::Extends),
    ("finally", @tokens.TokenKind::Finally),
    ("for", @tokens.TokenKind::For),
    ("function", @tokens.TokenKind::Function),
    ("if", @tokens.TokenKind::If),
    ("import", @tokens.TokenKind::Import),
    ("in", @tokens.TokenKind::In),
    ("instanceof", @tokens.TokenKind::Instanceof),
    ("new", @tokens.TokenKind::New),
    ("return", @tokens.TokenKind::Return),
    ("super", @tokens.TokenKind::Super),
    ("switch", @tokens.TokenKind::Switch),
    ("this", @tokens.TokenKind::This),
    ("throw", @tokens.TokenKind::Throw),
    ("try", @tokens.TokenKind::Try),
    ("typeof", @tokens.TokenKind::Typeof),
    ("var", @tokens.TokenKind::Var),
    ("void", @tokens.TokenKind::Void),
    ("while", @tokens.TokenKind::While),
    ("with", @tokens.TokenKind::With),
    ("yield", @tokens.TokenKind::Yield),
    ("enum", @tokens.TokenKind::Enum),
    ("implements", @tokens.TokenKind::Implements),
    ("interface", @tokens.TokenKind::Interface),
    ("let", @tokens.TokenKind::Let),
    ("package", @tokens.TokenKind::Package),
    ("private", @tokens.TokenKind::Private),
    ("protected", @tokens.TokenKind::Protected),
    ("public", @tokens.TokenKind::Public),
    ("static", @tokens.TokenKind::Static),
    ("await", @tokens.TokenKind::Await),
    ("async", @tokens.TokenKind::Async),
    ("null", @tokens.TokenKind::NullLiteral),
  ],
)

///|
pub(all) struct Lexer {
  input : String
  mut position : Int
  mut line : Int
  mut line_start : Int
  mut tokens : Array[LexToken]
}

///|
pub fn Lexer::new(input : String) -> Lexer {
  { input, position: 0, line: 1, line_start: 0, tokens: [] }
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
fn Lexer::tokenize(self : Lexer) -> Array[LexToken] {
  let input = self.input
  lex_tokens(input, self)
  println(self.tokens)
  self.tokens
}

///|
fn lex_tokens(input : StringView, lexer : Lexer) -> Unit {
  lexmatch input with longest {
    ("`" ("([^`\\\\]|\\\\.)*" as raw) "`", rest) => {
      lexer.add_token(@tokens.TokenKind::StringLiteral, raw)
      lex_tokens(rest, lexer)
    }

    // Whitespace
    ("[ \t\r]+", rest) => lex_tokens(rest, lexer)

    // Newlines
    ("\n", rest) => {
      lexer.line += 1
      lexer.line_start = lexer.position + 1
      lex_tokens(rest, lexer)
    }

    // Comments
    ("//[^\r\n]*", rest) => lex_tokens(rest, lexer)
    ("/\*[^*]*\*+([^/*][^*]*\*+)*/", rest) => lex_tokens(rest, lexer)

    // Boolean literals
    ("true|false" as raw, rest) => {
      lexer.add_token(@tokens.TokenKind::BooleanLiteral, raw)
      lex_tokens(rest, lexer)
    }

    // String literals
    ("\"" ("([^\\x22\\\\]|\\\\.)*" as raw) "\"", rest) => {
      lexer.add_token(@tokens.TokenKind::StringLiteral, raw)
      lex_tokens(rest, lexer)
    }
    ("'" ("([^'\\\\]|\\\\.)*" as raw) "'", rest) => {
      lexer.add_token(@tokens.TokenKind::StringLiteral, raw)
      lex_tokens(rest, lexer)
    }

    // Numeric literals
    ("0x[0-9a-fA-F](_|[0-9a-fA-F])*" as raw, rest) => {
      lexer.add_token(@tokens.TokenKind::NumericLiteral, raw)
      lex_tokens(rest, lexer)
    }
    ("0X[0-9a-fA-F](_|[0-9a-fA-F])*" as raw, rest) => {
      lexer.add_token(@tokens.TokenKind::NumericLiteral, raw)
      lex_tokens(rest, lexer)
    }
    ("0o[0-7](_|[0-7])*" as raw, rest) => {
      lexer.add_token(@tokens.TokenKind::NumericLiteral, raw)
      lex_tokens(rest, lexer)
    }
    ("0O[0-7](_|[0-7])*" as raw, rest) => {
      lexer.add_token(@tokens.TokenKind::NumericLiteral, raw)
      lex_tokens(rest, lexer)
    }
    ("0b[01](_|[01])*" as raw, rest) => {
      lexer.add_token(@tokens.TokenKind::NumericLiteral, raw)
      lex_tokens(rest, lexer)
    }
    ("0B[01](_|[01])*" as raw, rest) => {
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
    ("[0-9](_|[0-9])*" as raw, rest) => {
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
    ("[0-9]+" as raw, rest) => {
      lexer.add_token(@tokens.TokenKind::NumericLiteral, raw)
      lex_tokens(rest, lexer)
    }
    ("0[xX][0-9a-fA-F]+" as raw, rest) => {
      lexer.add_token(@tokens.TokenKind::NumericLiteral, raw)
      lex_tokens(rest, lexer)
    }
    ("0[oO][0-7]+" as raw, rest) => {
      lexer.add_token(@tokens.TokenKind::NumericLiteral, raw)
      lex_tokens(rest, lexer)
    }
    ("0[bB][01]+" as raw, rest) => {
      lexer.add_token(@tokens.TokenKind::NumericLiteral, raw)
      lex_tokens(rest, lexer)
    }

    // Operators
    ("\\.\\.\\." as raw, rest) => {
      lexer.add_token(@tokens.TokenKind::Ellipsis, raw)
      lex_tokens(rest, lexer)
    }
    ("===" as raw, rest) => {
      lexer.add_token(@tokens.TokenKind::EqEqEq, raw)
      lex_tokens(rest, lexer)
    }
    ("!==" as raw, rest) => {
      lexer.add_token(@tokens.TokenKind::NotEqEq, raw)
      lex_tokens(rest, lexer)
    }
    (">>>" as raw, rest) => {
      lexer.add_token(@tokens.TokenKind::URShift, raw)
      lex_tokens(rest, lexer)
    }
    (">>>=" as raw, rest) => {
      lexer.add_token(@tokens.TokenKind::URShiftEq, raw)
      lex_tokens(rest, lexer)
    }
    ("<<=" as raw, rest) => {
      lexer.add_token(@tokens.TokenKind::LShiftEq, raw)
      lex_tokens(rest, lexer)
    }
    (">>=" as raw, rest) => {
      lexer.add_token(@tokens.TokenKind::RShiftEq, raw)
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
      lexer.add_token(@tokens.TokenKind::RShift, raw)
      lex_tokens(rest, lexer)
    }
    ("<<" as raw, rest) => {
      lexer.add_token(@tokens.TokenKind::LShift, raw)
      lex_tokens(rest, lexer)
    }
    ("==" as raw, rest) => {
      lexer.add_token(@tokens.TokenKind::EqEq, raw)
      lex_tokens(rest, lexer)
    }
    ("!=" as raw, rest) => {
      lexer.add_token(@tokens.TokenKind::NotEq, raw)
      lex_tokens(rest, lexer)
    }
    ("<=" as raw, rest) => {
      lexer.add_token(@tokens.TokenKind::Le, raw)
      lex_tokens(rest, lexer)
    }
    (">=" as raw, rest) => {
      lexer.add_token(@tokens.TokenKind::Ge, raw)
      lex_tokens(rest, lexer)
    }
    ("&&" as raw, rest) => {
      lexer.add_token(@tokens.TokenKind::And, raw)
      lex_tokens(rest, lexer)
    }
    ("\|\|" as raw, rest) => {
      lexer.add_token(@tokens.TokenKind::Or, raw)
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
      lexer.add_token(@tokens.TokenKind::PlusEq, raw)
      lex_tokens(rest, lexer)
    }
    ("-=" as raw, rest) => {
      lexer.add_token(@tokens.TokenKind::MinusEq, raw)
      lex_tokens(rest, lexer)
    }
    ("\*=" as raw, rest) => {
      lexer.add_token(@tokens.TokenKind::StarEq, raw)
      lex_tokens(rest, lexer)
    }
    ("/=" as raw, rest) => {
      lexer.add_token(@tokens.TokenKind::SlashEq, raw)
      lex_tokens(rest, lexer)
    }
    ("%=" as raw, rest) => {
      lexer.add_token(@tokens.TokenKind::PercentEq, raw)
      lex_tokens(rest, lexer)
    }
    ("&=" as raw, rest) => {
      lexer.add_token(@tokens.TokenKind::BitAndEq, raw)
      lex_tokens(rest, lexer)
    }
    ("\|=" as raw, rest) => {
      lexer.add_token(@tokens.TokenKind::BitOrEq, raw)
      lex_tokens(rest, lexer)
    }
    ("\^=" as raw, rest) => {
      lexer.add_token(@tokens.TokenKind::BitXorEq, raw)
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
      lexer.add_token(@tokens.TokenKind::Semi, ";")
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
      lexer.add_token(@tokens.TokenKind::Eq, "=")
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
    ("/", rest) => {
      lexer.add_token(@tokens.TokenKind::Slash, "/")
      lex_tokens(rest, lexer)
    }
    ("%", rest) => {
      lexer.add_token(@tokens.TokenKind::Percent, "%")
      lex_tokens(rest, lexer)
    }
    ("&", rest) => {
      lexer.add_token(@tokens.TokenKind::BitAnd, "&")
      lex_tokens(rest, lexer)
    }
    ("\|", rest) => {
      lexer.add_token(@tokens.TokenKind::BitOr, "|")
      lex_tokens(rest, lexer)
    }
    ("\^", rest) => {
      lexer.add_token(@tokens.TokenKind::BitXor, "^")
      lex_tokens(rest, lexer)
    }
    ("!", rest) => {
      lexer.add_token(@tokens.TokenKind::Not, "!")
      lex_tokens(rest, lexer)
    }
    ("~", rest) => {
      lexer.add_token(@tokens.TokenKind::BitNot, "~")
      lex_tokens(rest, lexer)
    }
    ("<", rest) => {
      lexer.add_token(@tokens.TokenKind::Lt, "<")
      lex_tokens(rest, lexer)
    }
    (">", rest) => {
      lexer.add_token(@tokens.TokenKind::Gt, ">")
      lex_tokens(rest, lexer)
    }

    // EOF
    ("$", _) => lexer.add_token(@tokens.TokenKind::EOF, "EOF")

    // Error case
    ("." as c, rest) => {
      lexer.add_token(@tokens.TokenKind::Illegal, c.to_string())
      lex_tokens(rest, lexer)
    }
    _ => panic()
  }
}

///|
pub fn parse(code : String) -> Array[LexToken] {
  let lexer = Lexer::new(code)
  lexer.tokenize()
}

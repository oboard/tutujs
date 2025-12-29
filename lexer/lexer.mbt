///|
pub(all) struct LexToken {
  kind : @tokens.TokenKind
  value : String
  line : Int
  column : Int
} derive(Show, Eq)

///|
pub(all) struct Lexer {
  input : String
  mut position : Int
  mut line : Int
  mut column : Int
}

///|
pub fn Lexer::new(input : String) -> Lexer {
  { input, position: 0, line: 1, column: 1 }
}

///|
fn is_hex_digit(char : Char) -> Bool {
  char is ('0'..='9' | 'a'..='z' | 'A'..='Z')
}

///|
fn is_octal_digit(char : Char) -> Bool {
  char is ('0'..='7')
}

///|
fn is_binary_digit(char : Char) -> Bool {
  char is ('0' | '1')
}

///|
fn is_identifier_start(char : Char) -> Bool {
  char is ('a'..='z' | 'A'..='Z' | '_' | '$')
}

///|
fn is_identifier_part(char : Char) -> Bool {
  is_identifier_start(char) || char.is_digit(10)
}

///|
fn char_from_int(i : Int) -> Char {
  i.unsafe_to_char()
}

///|
fn Lexer::current_char(self : Lexer) -> Char {
  if self.position >= self.input.length() {
    ' '
  } else {
    // self.input[i] returns UInt16 in newer MoonBit versions
    let code = self.input[self.position]
    char_from_int(code.to_int())
  }
}

///|
fn Lexer::peek_char(self : Lexer, offset? : Int = 1) -> Char {
  let pos = self.position + offset
  if pos >= self.input.length() {
    ' '
  } else {
    let code = self.input[pos]
    char_from_int(code.to_int())
  }
}

///|
fn Lexer::advance(self : Lexer) -> Unit {
  if self.position < self.input.length() {
    // Check newline. Need to get char carefully as input[] is UInt16
    let code = self.input[self.position]
    let char = char_from_int(code.to_int())
    if char == '\n' {
      self.line += 1
      self.column = 1
    } else {
      self.column += 1
    }
    self.position += 1
  }
}

///|
fn Lexer::skip_whitespace(self : Lexer) -> Unit {
  while self.position < self.input.length() {
    let char = self.current_char()
    match char {
      ' ' | '\t' | '\r' => self.advance()
      '\n' => {
        self.line += 1
        self.column = 1
        self.advance()
      }
      _ => break
    }
  }
}

///|
fn Lexer::skip_comments(self : Lexer) -> Unit {
  if self.current_char() == '/' {
    let next_char = self.peek_char()
    if next_char == '/' {
      self.advance()
      self.advance()
      while self.position < self.input.length() && self.current_char() != '\n' {
        self.advance()
      }
    } else if next_char == '*' {
      self.advance()
      self.advance()
      while self.position < self.input.length() {
        if self.current_char() == '*' && self.peek_char() == '/' {
          self.advance()
          self.advance()
          break
        }
        if self.current_char() == '\n' {
          self.line += 1
          self.column = 1
        }
        self.advance()
      }
    }
  }
}

///|
fn Lexer::read_number(self : Lexer) -> LexToken {
  let start = self.position
  let start_column = self.column
  if self.current_char() == '0' {
    let next = self.peek_char()
    match next {
      'x' | 'X' => {
        self.advance()
        self.advance()
        while is_hex_digit(self.current_char()) {
          self.advance()
        }
      }
      'o' | 'O' => {
        self.advance()
        self.advance()
        while is_octal_digit(self.current_char()) {
          self.advance()
        }
      }
      'b' | 'B' => {
        self.advance()
        self.advance()
        while is_binary_digit(self.current_char()) {
          self.advance()
        }
      }
      _ => {
        // Decimal number starting with 0
        while self.current_char().is_digit(10) {
          self.advance()
        }
        // Decimal point
        if self.current_char() == '.' && self.peek_char().is_digit(10) {
          self.advance()
          while self.current_char().is_digit(10) {
            self.advance()
          }
        }
        // Exponent
        if self.current_char() == 'e' || self.current_char() == 'E' {
          self.advance()
          if self.current_char() == '+' || self.current_char() == '-' {
            self.advance()
          }
          while self.current_char().is_digit(10) {
            self.advance()
          }
        }
      }
    }
  } else {
    while self.current_char().is_digit(10) {
      self.advance()
    }
    if self.current_char() == '.' && self.peek_char().is_digit(10) {
      self.advance()
      while self.current_char().is_digit(10) {
        self.advance()
      }
    }
    if self.current_char() == 'e' || self.current_char() == 'E' {
      self.advance()
      if self.current_char() == '+' || self.current_char() == '-' {
        self.advance()
      }
      while self.current_char().is_digit(10) {
        self.advance()
      }
    }
  }
  let value = self.input.unsafe_substring(start~, end=self.position)
  {
    kind: @tokens.TokenKind::NumericLiteral,
    value,
    line: self.line,
    column: start_column,
  }
}

///|
fn Lexer::read_string(self : Lexer, quote : Char) -> LexToken {
  let start_column = self.column
  self.advance() // Skip opening quote
  let mut value = ""
  while self.position < self.input.length() && self.current_char() != quote {
    if self.current_char() == '\\' {
      self.advance()
      let escaped = self.current_char()
      match escaped {
        'n' => value += "\n"
        't' => value += "\t"
        'r' => value += "\r"
        'b' => value += "\b"
        'f' => value += "\f"
        'v' => value += "\u000B"
        '0' => value += "\u0000"
        '\\' => value += "\\"
        '"' => value += "\""
        '\'' => value += "'"
        '`' => value += "`"
        _ => value += escaped.to_string()
      }
    } else {
      value += self.current_char().to_string()
    }
    self.advance()
  }
  if self.current_char() == quote {
    self.advance() // Skip closing quote
  }
  {
    kind: @tokens.TokenKind::StringLiteral,
    value,
    line: self.line,
    column: start_column,
  }
}

///|
fn get_keyword_kind(value : String) -> @tokens.TokenKind {
  match value {
    "break" => Break
    "case" => Case
    "catch" => Catch
    "class" => Class
    "const" => Const
    "continue" => Continue
    "debugger" => Debugger
    "default" => Default
    "delete" => Delete
    "do" => Do
    "else" => Else
    "export" => Export
    "extends" => Extends
    "finally" => Finally
    "for" => For
    "function" => Function
    "if" => If
    "import" => Import
    "in" => In
    "instanceof" => Instanceof
    "new" => New
    "return" => Return
    "super" => Super
    "switch" => Switch
    "this" => This
    "throw" => Throw
    "try" => Try
    "typeof" => Typeof
    "var" => Var
    "void" => Void
    "while" => While
    "with" => With
    "yield" => Yield
    "enum" => Enum
    "implements" => Implements
    "interface" => Interface
    "let" => Let
    "package" => Package
    "private" => Private
    "protected" => Protected
    "public" => Public
    "static" => Static
    "await" => Await
    "async" => Async
    _ => Identifier
  }
}

///|
fn Lexer::read_identifier(self : Lexer) -> LexToken {
  let start = self.position
  let start_column = self.column
  while is_identifier_part(self.current_char()) {
    self.advance()
  }
  let value = self.input.unsafe_substring(start~, end=self.position)
  let kind = get_keyword_kind(value)
  { kind, value, line: self.line, column: start_column }
}

///|
fn Lexer::read_operator(self : Lexer) -> LexToken {
  let char = self.current_char()
  let start_column = self.column

  // Check for 4-char operators
  if self.position + 4 <= self.input.length() {
    let four_char = self.input.unsafe_substring(
      start=self.position,
      end=self.position + 4,
    )
    match four_char {
      ">>>=" => {
        self.advance()
        self.advance()
        self.advance()
        self.advance()
        return {
          kind: URShiftEq,
          value: ">>>=",
          line: self.line,
          column: start_column,
        }
      }
      _ => ()
    }
  }

  // Check for 3-char operators
  if self.position + 3 <= self.input.length() {
    let three_char = self.input.unsafe_substring(
      start=self.position,
      end=self.position + 3,
    )
    match three_char {
      "..." => {
        self.advance()
        self.advance()
        self.advance()
        return {
          kind: Ellipsis,
          value: "...",
          line: self.line,
          column: start_column,
        }
      }
      "===" => {
        self.advance()
        self.advance()
        self.advance()
        return {
          kind: EqEqEq,
          value: "===",
          line: self.line,
          column: start_column,
        }
      }
      "!==" => {
        self.advance()
        self.advance()
        self.advance()
        return {
          kind: NotEqEq,
          value: "!==",
          line: self.line,
          column: start_column,
        }
      }
      ">>>" => {
        self.advance()
        self.advance()
        self.advance()
        return {
          kind: URShift,
          value: ">>>",
          line: self.line,
          column: start_column,
        }
      }
      "<<=" => {
        self.advance()
        self.advance()
        self.advance()
        return {
          kind: LShiftEq,
          value: "<<=",
          line: self.line,
          column: start_column,
        }
      }
      ">>=" => {
        self.advance()
        self.advance()
        self.advance()
        return {
          kind: RShiftEq,
          value: ">>=",
          line: self.line,
          column: start_column,
        }
      }
      "**=" => {
        self.advance()
        self.advance()
        self.advance()
        return {
          kind: StarStarEqual,
          value: "**=",
          line: self.line,
          column: start_column,
        }
      }
      _ => ()
    }
  }

  // Check for 2-char operators
  if self.position + 2 <= self.input.length() {
    let two_char = self.input.unsafe_substring(
      start=self.position,
      end=self.position + 2,
    )
    match two_char {
      "**" => {
        self.advance()
        self.advance()
        return {
          kind: StarStar,
          value: "**",
          line: self.line,
          column: start_column,
        }
      }
      ">>" => {
        self.advance()
        self.advance()
        return {
          kind: RShift,
          value: ">>",
          line: self.line,
          column: start_column,
        }
      }
      "<<" => {
        self.advance()
        self.advance()
        return {
          kind: LShift,
          value: "<<",
          line: self.line,
          column: start_column,
        }
      }
      "==" => {
        self.advance()
        self.advance()
        return {
          kind: EqEq,
          value: "==",
          line: self.line,
          column: start_column,
        }
      }
      "!=" => {
        self.advance()
        self.advance()
        return {
          kind: NotEq,
          value: "!=",
          line: self.line,
          column: start_column,
        }
      }
      "<=" => {
        self.advance()
        self.advance()
        return { kind: Le, value: "<=", line: self.line, column: start_column }
      }
      ">=" => {
        self.advance()
        self.advance()
        return { kind: Ge, value: ">=", line: self.line, column: start_column }
      }
      "&&" => {
        self.advance()
        self.advance()
        return { kind: And, value: "&&", line: self.line, column: start_column }
      }
      "||" => {
        self.advance()
        self.advance()
        return { kind: Or, value: "||", line: self.line, column: start_column }
      }
      "??" => {
        self.advance()
        self.advance()
        return {
          kind: QuestionQuestion,
          value: "??",
          line: self.line,
          column: start_column,
        }
      }
      "++" => {
        self.advance()
        self.advance()
        return {
          kind: PlusPlus,
          value: "++",
          line: self.line,
          column: start_column,
        }
      }
      "--" => {
        self.advance()
        self.advance()
        return {
          kind: MinusMinus,
          value: "--",
          line: self.line,
          column: start_column,
        }
      }
      "=>" => {
        self.advance()
        self.advance()
        return {
          kind: Arrow,
          value: "=>",
          line: self.line,
          column: start_column,
        }
      }
      "+=" => {
        self.advance()
        self.advance()
        return {
          kind: PlusEq,
          value: "+=",
          line: self.line,
          column: start_column,
        }
      }
      "-=" => {
        self.advance()
        self.advance()
        return {
          kind: MinusEq,
          value: "-=",
          line: self.line,
          column: start_column,
        }
      }
      "*=" => {
        self.advance()
        self.advance()
        return {
          kind: StarEq,
          value: "*=",
          line: self.line,
          column: start_column,
        }
      }
      "/=" => {
        self.advance()
        self.advance()
        return {
          kind: SlashEq,
          value: "/=",
          line: self.line,
          column: start_column,
        }
      }
      "%=" => {
        self.advance()
        self.advance()
        return {
          kind: PercentEq,
          value: "%=",
          line: self.line,
          column: start_column,
        }
      }
      "&=" => {
        self.advance()
        self.advance()
        return {
          kind: BitAndEq,
          value: "&=",
          line: self.line,
          column: start_column,
        }
      }
      "|=" => {
        self.advance()
        self.advance()
        return {
          kind: BitOrEq,
          value: "|=",
          line: self.line,
          column: start_column,
        }
      }
      "^=" => {
        self.advance()
        self.advance()
        return {
          kind: BitXorEq,
          value: "^=",
          line: self.line,
          column: start_column,
        }
      }
      _ => ()
    }
  }
  self.advance()
  match char {
    '{' => { kind: LBrace, value: "{", line: self.line, column: start_column }
    '}' => { kind: RBrace, value: "}", line: self.line, column: start_column }
    '(' => { kind: LParen, value: "(", line: self.line, column: start_column }
    ')' => { kind: RParen, value: ")", line: self.line, column: start_column }
    '[' => { kind: LBracket, value: "[", line: self.line, column: start_column }
    ']' => { kind: RBracket, value: "]", line: self.line, column: start_column }
    '.' => { kind: Dot, value: ".", line: self.line, column: start_column }
    ';' => { kind: Semi, value: ";", line: self.line, column: start_column }
    ',' => { kind: Comma, value: ",", line: self.line, column: start_column }
    '?' => { kind: Question, value: "?", line: self.line, column: start_column }
    ':' => { kind: Colon, value: ":", line: self.line, column: start_column }
    '=' => { kind: Eq, value: "=", line: self.line, column: start_column }
    '+' => { kind: Plus, value: "+", line: self.line, column: start_column }
    '-' => { kind: Minus, value: "-", line: self.line, column: start_column }
    '*' => { kind: Star, value: "*", line: self.line, column: start_column }
    '/' => { kind: Slash, value: "/", line: self.line, column: start_column }
    '%' => { kind: Percent, value: "%", line: self.line, column: start_column }
    '&' => { kind: BitAnd, value: "&", line: self.line, column: start_column }
    '|' => { kind: BitOr, value: "|", line: self.line, column: start_column }
    '^' => { kind: BitXor, value: "^", line: self.line, column: start_column }
    '!' => { kind: Not, value: "!", line: self.line, column: start_column }
    '~' => { kind: BitNot, value: "~", line: self.line, column: start_column }
    '<' => { kind: Lt, value: "<", line: self.line, column: start_column }
    '>' => { kind: Gt, value: ">", line: self.line, column: start_column }
    _ =>
      {
        kind: Illegal,
        value: char.to_string(),
        line: self.line,
        column: start_column,
      }
  }
}

///|
fn Lexer::next_token(self : Lexer) -> LexToken? {
  // Loop to skip whitespace and comments until we find something else or EOF
  while true {
    let before_pos = self.position
    self.skip_whitespace()
    self.skip_comments()
    if self.position == before_pos {
      break
    }
  }
  if self.position >= self.input.length() {
    return None
  }
  let char = self.current_char()
  if char.is_digit(10) || (char == '.' && self.peek_char().is_digit(10)) {
    return Some(self.read_number())
  }
  if char == '"' || char == '\'' || char == '`' {
    return Some(self.read_string(char))
  }
  if is_identifier_start(char) {
    return Some(self.read_identifier())
  }
  Some(self.read_operator())
}

///|
pub fn Lexer::tokenize(self : Lexer) -> Array[LexToken] {
  let tokens = []
  while true {
    let token_opt = self.next_token()
    match token_opt {
      Some(token) => tokens.push(token)
      None => break
    }
  }
  tokens.push({ kind: EOF, value: "EOF", line: self.line, column: self.column })
  tokens
}

///|
pub fn parse(code : String) -> Array[LexToken] {
  let lexer = Lexer::new(code)
  lexer.tokenize()
}

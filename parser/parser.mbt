///|
type TokenKind = @tokens.TokenKind

///|
type LexToken = @lexer.LexToken

///|
pub(all) struct Parser {
  tokens : Array[LexToken]
  mut pos : Int
  errors : Array[String]
}

///|
pub fn Parser::new(tokens : Array[LexToken]) -> Parser {
  { tokens, pos: 0, errors: [] }
}

///|
pub fn parse(tokens : Array[LexToken]) -> Program {
  let p = Parser::new(tokens).parse_program()
  p
}

///|
pub fn Parser::parse_program(self : Parser) -> Program {
  let body = []
  let directives = []
  while self.peek().kind != TokenKind::EOF {
    let stmt = self.parse_statement()
    body.push(stmt)
    match stmt {
      Statement::ExpressionStatement(expr_stmt) =>
        match expr_stmt.directive {
          Some(d) => directives.push(d)
          None => ()
        }
      _ => ()
    }
  }
  { sourceType: Module, body, directives, interpreter: None }
}

///|
fn Parser::peek_at(self : Parser, offset : Int) -> LexToken {
  let idx = self.pos + offset
  if idx < self.tokens.length() {
    self.tokens[idx]
  } else {
    self.tokens[self.tokens.length() - 1] // EOF
  }
}

///|
fn Parser::peek(self : Parser) -> LexToken {
  if self.pos < self.tokens.length() {
    self.tokens[self.pos]
  } else {
    self.tokens[self.tokens.length() - 1] // EOF
  }
}

///|
fn Parser::advance(self : Parser) -> Unit {
  if self.pos < self.tokens.length() {
    self.pos = self.pos + 1
  }
}

///|
fn Parser::consume(self : Parser, kind : TokenKind) -> Unit {
  if self.peek().kind == kind {
    self.advance()
  }
}

///|
fn Parser::lookahead(self : Parser) -> LexToken {
  if self.pos + 1 < self.tokens.length() {
    self.tokens[self.pos + 1]
  } else {
    self.tokens[self.tokens.length() - 1] // EOF
  }
}

///|
fn Parser::has_newline_before(self : Parser, token : LexToken) -> Bool {
  if self.pos > 0 {
    let prev = self.tokens[self.pos - 1]
    return prev.line < token.line
  }
  false
}

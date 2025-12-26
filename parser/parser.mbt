///|
pub enum SourceType {
  Script
  Module
} derive(Show, Eq, ToJson, FromJson, Compare, Hash)

///|
pub enum VariableKind {
  Var
  Let
  Const
} derive(Show, Eq, ToJson, FromJson, Compare, Hash)

///|
struct Position {
  line : Int
  column : Int
} derive(Show, Eq, ToJson, FromJson, Compare, Hash)

///|
struct SourceLocation {
  start : Position
  end : Position
} derive(Show, Eq, ToJson, FromJson, Compare, Hash)

// --- Helper Functions for AST Creation ---

///|
fn create_program(body : Array[ASTNode]) -> ASTNode {
  {
    node_type: Program,
    loc: None,
    body,
    operator: None,
    left: None,
    right: None,
    argument: None,
    declarations: [],
    kind: None,
    id: None,
    init: None,
    params: [],
    callee: None,
    name: None,
    value: None,
    raw: None,
    condition: None,
    consequent: None,
    alternate: None,
    properties: [],
    elements: [],
    key: None,
    node_method: None,
    shorthand: None,
  }
}

///|
fn create_identifier(name : String, loc : SourceLocation?) -> ASTNode {
  {
    node_type: Identifier({ name, optional: false }),
    loc,
    name: Some(name),
    body: [],
    operator: None,
    left: None,
    right: None,
    argument: None,
    declarations: [],
    kind: None,
    id: None,
    init: None,
    params: [],
    callee: None,
    value: None,
    raw: None,
    condition: None,
    consequent: None,
    alternate: None,
    properties: [],
    elements: [],
    key: None,
    node_method: None,
    shorthand: None,
  }
}

///|
fn create_literal(
  value : String,
  raw : String,
  loc : SourceLocation?,
) -> ASTNode {
  {
    node_type: StringLiteral(value),
    loc,
    // TODO: tokenize value
    value: Some(value),
    raw: Some(raw),
    body: [],
    operator: None,
    left: None,
    right: None,
    argument: None,
    declarations: [],
    kind: None,
    id: None,
    init: None,
    params: [],
    callee: None,
    name: None,
    condition: None,
    consequent: None,
    alternate: None,
    properties: [],
    elements: [],
    key: None,
    node_method: None,
    shorthand: None,
  }
}

///|
struct Token {
  kind : TokenKind
  loc : SourceLocation
} derive(Show, Eq)

// --- Parser Implementation ---F

///|
pub struct Parser {
  lexer : @lexer.Lexer
  mut current : Token
  mut peek : Token
}

///|
fn convert_pos(pos : @lexer.Position) -> Position {
  { line: pos.line, column: pos.column }
}

///|
pub fn Parser::new(input : String) -> Parser {
  let lexer = @lexer.Lexer::new(input)
  let dummy_loc = { start: { line: 0, column: 0 }, end: { line: 0, column: 0 } }
  let dummy_token = { kind: EOF, loc: dummy_loc }
  let parser = { lexer, current: dummy_token, peek: dummy_token }
  parser.advance_token()
  parser.advance_token()
  parser
}

///|
fn Parser::advance_token(self : Parser) -> Unit {
  self.current = self.peek
  self.peek = self.read_next_token()
}

///|
fn Parser::read_next_token(self : Parser) -> Token {
  self.lexer.skip_whitespace()
  let start_pos = convert_pos(self.lexer.get_loc())
  match self.lexer.peek() {
    None => { kind: EOF, loc: { start: start_pos, end: start_pos } }
    Some(ch) =>
      if ch.is_ascii_alphabetic() || ch == '_' || ch == '$' {
        let mut ident = ""
        while true {
          match self.lexer.peek() {
            Some(c) =>
              if c.is_ascii_alphabetic() ||
                c.is_ascii_digit() ||
                c == '_' ||
                c == '$' {
                ident = ident + c.to_string()
                self.lexer.advance()
              } else {
                break
              }
            None => break
          }
        }
        let kind = match ident {
          "function" => TokenKind::Function
          "return" => TokenKind::Return
          "let" => TokenKind::Let
          "var" => TokenKind::Var
          "const" => TokenKind::Const
          "if" => TokenKind::If
          "else" => TokenKind::Else
          _ => TokenKind::Identifier(ident)
        }
        let end_pos = convert_pos(self.lexer.get_loc())
        { kind, loc: { start: start_pos, end: end_pos } }
      } else if ch.is_ascii_digit() {
        let mut num = ""
        while true {
          match self.lexer.peek() {
            Some(c) =>
              if c.is_ascii_digit() {
                num = num + c.to_string()
                self.lexer.advance()
              } else {
                break
              }
            None => break
          }
        }
        let end_pos = convert_pos(self.lexer.get_loc())
        { kind: Number(num), loc: { start: start_pos, end: end_pos } }
      } else if ch == '"' || ch == '\'' {
        let quote = ch
        self.lexer.advance()
        let mut str_val = ""
        while true {
          match self.lexer.peek() {
            Some(c) => {
              if c == quote {
                self.lexer.advance()
                break
              }
              str_val = str_val + c.to_string()
              self.lexer.advance()
            }
            None => abort("Unterminated string literal")
          }
        }
        let end_pos = convert_pos(self.lexer.get_loc())
        {
          kind: StringLiteral(str_val),
          loc: { start: start_pos, end: end_pos },
        }
      } else {
        self.lexer.advance()
        let kind = match ch {
          '=' => TokenKind::Assign
          ';' => TokenKind::Semi
          '(' => TokenKind::LParen
          ')' => TokenKind::RParen
          '{' => TokenKind::LBrace
          '}' => TokenKind::RBrace
          ',' => TokenKind::Comma
          '.' => TokenKind::Dot
          '+' => TokenKind::Plus
          '-' => TokenKind::Minus
          '*' => TokenKind::Star
          '/' => TokenKind::Slash
          _ => TokenKind::EOF // Unknown char, treat as EOF for now or error
        }
        let end_pos = convert_pos(self.lexer.get_loc())
        { kind, loc: { start: start_pos, end: end_pos } }
      }
  }
}

///|
fn Parser::expect(self : Parser, kind : TokenKind) -> Unit {
  if self.current.kind == kind {
    self.advance_token()
  } else {
    // Basic error handling
    abort(
      "Expected " +
      kind.to_string() +
      " but got " +
      self.current.kind.to_string(),
    )
  }
}

///|
fn Parser::parse_program(self : Parser) -> ASTNode {
  let body = []
  while self.current.kind != EOF {
    body.push(self.parse_statement())
  }
  create_program(body)
}

///|
fn Parser::parse_statement(self : Parser) -> ASTNode {
  match self.current.kind {
    Let | Const | Var => self.parse_variable_declaration()
    Function => self.parse_function_declaration()
    Return => self.parse_return_statement()
    LBrace => self.parse_block_statement()
    _ => self.parse_expression_statement()
  }
}

///|
fn Parser::parse_block_statement(self : Parser) -> ASTNode {
  let start_loc = self.current.loc
  self.expect(LBrace)
  let body = []
  while self.current.kind != RBrace && self.current.kind != EOF {
    body.push(self.parse_statement())
  }
  self.expect(RBrace)
  // Approximation of end location
  let end_loc = self.current.loc
  {
    node_type: BlockStatement,
    loc: Some({ start: start_loc.start, end: end_loc.end }),
    body,
    operator: None,
    left: None,
    right: None,
    argument: None,
    declarations: [],
    kind: None,
    id: None,
    init: None,
    params: [],
    callee: None,
    name: None,
    value: None,
    raw: None,
    condition: None,
    consequent: None,
    alternate: None,
    properties: [],
    elements: [],
    key: None,
    node_method: None,
    shorthand: None,
  }
}

///|
fn Parser::parse_variable_declaration(self : Parser) -> ASTNode {
  let start_loc = self.current.loc
  let kind = match self.current.kind {
    Let => VariableKind::Let
    Const => VariableKind::Const
    Var => VariableKind::Var
    _ => abort("Unreachable")
  }
  self.advance_token() // consume let/const/var
  let declarations = []
  // Only support single declaration for now: let x = 1;
  match self.current.kind {
    Identifier(name) => {
      let id = create_identifier(name, Some(self.current.loc))
      self.advance_token()
      let mut init = None
      if self.current.kind == Assign {
        self.advance_token()
        init = Some(self.parse_expression())
      }
      let declarator = {
        node_type: VariableDeclarator,
        loc: None, // TODO: range
        id: Some(id),
        init,
        body: [],
        operator: None,
        left: None,
        right: None,
        argument: None,
        declarations: [],
        kind: None,
        params: [],
        callee: None,
        name: None,
        value: None,
        raw: None,
        condition: None,
        consequent: None,
        alternate: None,
        properties: [],
        elements: [],
        key: None,
        node_method: None,
        shorthand: None,
      }
      declarations.push(declarator)
    }
    _ => abort("Expected identifier")
  }
  if self.current.kind == Semi {
    self.advance_token()
  }
  {
    node_type: VariableDeclaration,
    loc: Some({ start: start_loc.start, end: self.current.loc.end }),
    kind: Some(kind),
    declarations,
    body: [],
    operator: None,
    left: None,
    right: None,
    argument: None,
    id: None,
    init: None,
    params: [],
    callee: None,
    name: None,
    value: None,
    raw: None,
    condition: None,
    consequent: None,
    alternate: None,
    properties: [],
    elements: [],
    key: None,
    node_method: None,
    shorthand: None,
  }
}

///|
fn Parser::parse_function_declaration(self : Parser) -> ASTNode {
  let start_loc = self.current.loc
  self.expect(Function)
  let mut id = None
  match self.current.kind {
    Identifier(name) => {
      id = Some(create_identifier(name, Some(self.current.loc)))
      self.advance_token()
    }
    _ => () // Anonymous function? Not for Declaration usually
  }
  self.expect(LParen)
  let params = []
  while self.current.kind != RParen && self.current.kind != EOF {
    match self.current.kind {
      Identifier(name) => {
        params.push(create_identifier(name, Some(self.current.loc)))
        self.advance_token()
        if self.current.kind == Comma {
          self.advance_token()
        }
      }
      _ => abort("Expected parameter name")
    }
  }
  self.expect(RParen)
  let body = self.parse_block_statement()
  {
    node_type: FunctionDeclaration,
    loc: Some({ start: start_loc.start, end: body.loc.unwrap().end }),
    id,
    params,
    body: [body],
    operator: None,
    left: None,
    right: None,
    argument: None,
    declarations: [],
    kind: None,
    init: None,
    callee: None,
    name: None,
    value: None,
    raw: None,
    condition: None,
    consequent: None,
    alternate: None,
    properties: [],
    elements: [],
    key: None,
    node_method: None,
    shorthand: None,
  }
}

///|
fn Parser::parse_return_statement(self : Parser) -> ASTNode {
  let start_loc = self.current.loc
  self.expect(Return)
  let mut argument = None
  if self.current.kind != Semi {
    argument = Some(self.parse_expression())
  }
  if self.current.kind == Semi {
    self.advance_token()
  }
  {
    node_type: ReturnStatement,
    loc: Some({ start: start_loc.start, end: self.current.loc.end }),
    argument,
    body: [],
    operator: None,
    left: None,
    right: None,
    declarations: [],
    kind: None,
    id: None,
    init: None,
    params: [],
    callee: None,
    name: None,
    value: None,
    raw: None,
    condition: None,
    consequent: None,
    alternate: None,
    properties: [],
    elements: [],
    key: None,
    node_method: None,
    shorthand: None,
  }
}

///|
fn Parser::parse_expression_statement(self : Parser) -> ASTNode {
  let start_loc = self.current.loc
  let expr = self.parse_expression()
  if self.current.kind == Semi {
    self.advance_token()
  }
  {
    node_type: ExpressionStatement,
    loc: Some({ start: start_loc.start, end: self.current.loc.end }),
    body: [],
    argument: Some(expr),
    operator: None,
    left: None,
    right: None,
    declarations: [],
    kind: None,
    id: None,
    init: None,
    params: [],
    callee: None,
    name: None,
    value: None,
    raw: None,
    condition: None,
    consequent: None,
    alternate: None,
    properties: [],
    elements: [],
    key: None,
    node_method: None,
    shorthand: None,
  }
}

///|
fn Parser::parse_expression(self : Parser) -> ASTNode {
  self.parse_binary_expression()
}

///|
fn Parser::parse_binary_expression(self : Parser) -> ASTNode {
  let left = self.parse_primary()
  if self.current.kind == Plus ||
    self.current.kind == Minus ||
    self.current.kind == Star ||
    self.current.kind == Slash {
    let operator = match self.current.kind {
      Plus => "+"
      Minus => "-"
      Star => "*"
      Slash => "/"
      _ => ""
    }
    self.advance_token()
    let right = self.parse_primary()
    {
      node_type: BinaryExpression,
      loc: None,
      operator: Some(operator),
      left: Some(left),
      right: Some(right),
      body: [],
      argument: None,
      declarations: [],
      kind: None,
      id: None,
      init: None,
      params: [],
      callee: None,
      name: None,
      value: None,
      raw: None,
      condition: None,
      consequent: None,
      alternate: None,
      properties: [],
      elements: [],
      key: None,
      node_method: None,
      shorthand: None,
    }
  } else {
    left
  }
}

///|
fn Parser::parse_primary(self : Parser) -> ASTNode {
  let mut node = match self.current.kind {
    Identifier(name) => {
      let node = create_identifier(name, Some(self.current.loc))
      self.advance_token()
      node
    }
    Number(val) => {
      let node = create_literal(val, val, Some(self.current.loc))
      self.advance_token()
      node
    }
    StringLiteral(val) => {
      let node = create_literal(val, "\"" + val + "\"", Some(self.current.loc))
      self.advance_token()
      node
    }
    LParen => {
      self.advance_token()
      let expr = self.parse_expression()
      self.expect(RParen)
      expr
    }
    _ => abort("Unexpected token: " + self.current.kind.to_string())
  }
  while true {
    if self.current.kind == Dot {
      self.advance_token()
      match self.current.kind {
        Identifier(name) => {
          let property = create_identifier(name, Some(self.current.loc))
          self.advance_token()
          node = {
            node_type: MemberExpression,
            loc: None, // TODO: range
            // using left for object, right for property as placeholders
            left: Some(node),
            right: Some(property),
            body: [],
            operator: None,
            argument: None,
            declarations: [],
            kind: None,
            id: None,
            init: None,
            params: [],
            callee: None,
            name: None,
            value: None,
            raw: None,
            condition: None,
            consequent: None,
            alternate: None,
            properties: [],
            elements: [],
            key: None,
            node_method: None,
            shorthand: None,
          }
        }
        _ => abort("Expected identifier after dot")
      }
    } else if self.current.kind == LParen {
      self.advance_token()
      let args = []
      while self.current.kind != RParen && self.current.kind != EOF {
        args.push(self.parse_expression())
        if self.current.kind == Comma {
          self.advance_token()
        }
      }
      self.expect(RParen)
      node = {
        node_type: CallExpression,
        loc: None,
        callee: Some(node),
        params: args,
        body: [],
        operator: None,
        left: None,
        right: None,
        argument: None,
        declarations: [],
        kind: None,
        id: None,
        init: None,
        name: None,
        value: None,
        raw: None,
        condition: None,
        consequent: None,
        alternate: None,
        properties: [],
        elements: [],
        key: None,
        node_method: None,
        shorthand: None,
      }
    } else {
      break
    }
  }
  node
}

///|
pub fn parse(code : String) -> ASTNode {
  let parser = Parser::new(code)
  parser.parse_program()
}

//|

///|
fn parse_bigint(s : String) -> BigInt {
  BigInt::from_string(s)
}

///|
fn Parser::parse_primary(self : Parser) -> Expression {
  let token = self.peek()
  match token.kind {
    TokenKind::BooleanLiteral => {
      self.advance()
      Expression::BooleanLiteral({ value: token.value == "true" })
    }
    TokenKind::NumericLiteral => {
      self.advance()
      let s = token.value.to_string()
      if s is [.. val_str, 'n'] {
        let val_str = val_str.to_string()
        let val = parse_bigint(val_str)
        Expression::BigIntLiteral({ value: val })
      } else {
        Expression::NumericLiteral({
          value: @strconv.parse_double(s) catch {
            _ => 0.0
          },
        })
      }
    }
    TokenKind::StringLiteral => {
      self.advance()
      Expression::StringLiteral({
        value: unescape_string_literal(token.value.to_string()),
      })
    }
    TokenKind::RegularExpressionLiteral => {
      self.advance()
      let (pattern, flags) = parse_regex_token(token.value)
      Expression::RegExpLiteral({ pattern, flags })
    }
    TokenKind::NullLiteral => {
      self.advance()
      Expression::NullLiteral
    }
    TokenKind::Identifier =>
      if token.value == "async" && self.lookahead().kind == TokenKind::Function {
        self.advance() // consume async
        self.parse_function_expression(async_=true)
      } else {
        self.advance()
        Expression::Identifier(Identifier::{
          name: token.value.to_string(),
          optional: false,
          typeAnnotation: None,
        })
      }
    TokenKind::This => {
      self.advance()
      Expression::ThisExpression
    }
    TokenKind::LParen => {
      self.advance()
      if self.peek().kind == TokenKind::RParen {
        self.advance()
        Expression::SequenceExpression({ expressions: [] })
      } else {
        let expr = self.parse_expression()
        self.consume(TokenKind::RParen)
        expr
      }
    }
    TokenKind::LBracket => self.parse_array_literal()
    TokenKind::LBrace => self.parse_object_literal()
    TokenKind::Function => self.parse_function_expression()
    TokenKind::Class => self.parse_class_expression()
    TokenKind::Async =>
      if self.lookahead().kind is TokenKind::Function {
        self.advance()
        self.parse_function_expression(async_=true)
      } else {
        self.advance()
        Expression::Identifier(Identifier::{
          name: "async",
          optional: false,
          typeAnnotation: None,
        })
      }
    // TokenKind::Semicolon => {
    //   self.advance()
    //   Expression::EmptyExpression
    // }
    _ => {
      let token = self.peek()
      self.errors.push(
        "Unexpected token in parse_primary: \{token.kind} at \{token.line}:\{token.column}, value: \{token.value}",
      )
      self.advance()
      Expression::NullLiteral
    }
  }
}

///|
fn Parser::parse_array_literal(self : Parser) -> Expression {
  self.consume(TokenKind::LBracket)
  let elems : Array[ArrayElement] = []
  while self.peek().kind != TokenKind::RBracket {
    match self.peek().kind {
      TokenKind::Comma => {
        self.advance()
        elems.push(ArrayElement::OmittedExpression)
      }
      TokenKind::EOF =>
        // TODO: Error handling
        break
      _ => {
        if self.peek().kind == TokenKind::Ellipsis {
          self.advance()
          let arg = self.parse_assignment()
          elems.push(ArrayElement::SpreadElement(argument=arg))
        } else {
          let expr = self.parse_assignment()
          elems.push(ArrayElement::Expression(expr))
        }
        if self.peek().kind == TokenKind::Comma {
          self.advance()
        }
      }
    }
  }
  self.consume(TokenKind::RBracket)
  Expression::ArrayLiteralExpression(ArrayExpression::{ elements: elems })
}

///|
fn Parser::parse_object_literal(self : Parser) -> Expression {
  self.consume(TokenKind::LBrace)
  let properties : Array[ObjectMember] = []
  while self.peek().kind != TokenKind::RBrace {
    if self.peek().kind == TokenKind::Ellipsis {
      self.advance()
      let arg = self.parse_assignment()
      properties.push(
        ObjectMember::SpreadElement(SpreadElement::{ argument: arg }),
      )
      if self.peek().kind == TokenKind::Comma {
        self.advance()
      }
    } else {
      // Parse Key (LOOKAHEAD for Accessor)
      // Check if it's get/set
      let mut is_accessor = false
      let mut accessor_kind = MethodKind::Get
      let token = self.peek()
      if token.kind == TokenKind::Identifier &&
        (token.value == "get" || token.value == "set") {
        // Check next token
        let next_token = self.lookahead()
        match next_token.kind {
          TokenKind::Identifier
          | TokenKind::StringLiteral
          | TokenKind::NumericLiteral
          | TokenKind::LBracket => {
            is_accessor = true
            accessor_kind = if token.value == "get" {
              MethodKind::Get
            } else {
              MethodKind::Set
            }
          }
          _ => ()
        }
      }
      if is_accessor {
        // Consume 'get' or 'set'
        self.advance()
        let (real_key, real_computed) = if self.peek().kind ==
          TokenKind::LBracket {
          self.advance()
          let expr = self.parse_assignment()
          self.consume(TokenKind::RBracket)
          (expr, true)
        } else {
          (self.parse_identifier_name(), false)
        }
        let params = self.parse_function_params()
        let body = self.parse_block_statement()
        properties.push(
          ObjectMember::ObjectMethod(ObjectMethod::{
            key: real_key,
            kind: accessor_kind,
            static_: false,
            computed: real_computed,
            params,
            body,
            generator: false,
            async_: false,
            value: real_key, // Placeholder
            decorators: [],
            typeParameters: None,
            variance: None,
          }),
        )
      } else {
        // Not accessor, parse key normally
        let (key, computed) = if self.peek().kind == TokenKind::LBracket {
          self.advance()
          let expr = self.parse_assignment()
          self.consume(TokenKind::RBracket)
          (expr, true)
        } else {
          (self.parse_identifier_name(), false)
        }

        // Check for Method definition (shorthand method)
        if self.peek().kind == TokenKind::LParen {
          let params = self.parse_function_params()
          let body = self.parse_block_statement()
          properties.push(
            ObjectMember::ObjectMethod(ObjectMethod::{
              key,
              kind: MethodKind::Method,
              static_: false,
              computed,
              params,
              body,
              generator: false,
              async_: false,
              value: key, // Placeholder
              decorators: [],
              typeParameters: None,
              variance: None,
            }),
          )
        } else if self.peek().kind == TokenKind::Colon {
          self.advance()
          let value = self.parse_assignment()
          properties.push(
            ObjectMember::ObjectProperty(ObjectProperty::{
              key,
              value,
              shorthand: false,
              computed,
              decorators: [],
            }),
          )
        } else {
          // Shorthand property
          properties.push(
            ObjectMember::ObjectProperty(ObjectProperty::{
              key,
              value: key, // Value is same as key expression (Identifier)
              shorthand: true,
              computed,
              decorators: [],
            }),
          )
        }
      }
      if self.peek().kind == TokenKind::Comma {
        self.advance()
      }
    }
  }
  self.consume(TokenKind::RBrace)
  Expression::ObjectExpression(ObjectExpression::{ properties, })
}

///|
fn Parser::parse_function_expression(
  self : Parser,
  async_? : Bool = false,
) -> Expression {
  self.consume(TokenKind::Function)
  let generator = if self.peek().kind == TokenKind::Star {
    self.advance()
    true
  } else {
    false
  }
  let id = if self.peek().kind == TokenKind::Identifier {
    let token = self.peek()
    self.advance()
    Option::Some(Identifier::{
      name: token.value.to_string(),
      optional: false,
      typeAnnotation: None,
    })
  } else {
    None
  }
  let params = self.parse_function_params()
  let body = self.parse_block_statement()
  Expression::FunctionExpression({
    id,
    params,
    body,
    generator,
    async_,
    expression: false,
    typeParameters: None,
    returnType: None,
  })
}

///|
fn Parser::parse_function_params(self : Parser) -> Array[Pattern] {
  self.consume(TokenKind::LParen)
  let params = []
  while self.peek().kind != TokenKind::RParen {
    match self.peek().kind {
      TokenKind::Identifier => {
        let token = self.peek()
        self.advance()
        params.push(
          Pattern::Identifier(Identifier::{
            name: token.value.to_string(),
            optional: false,
            typeAnnotation: None,
          }),
        )
      }
      _ => {
        let token = self.peek()
        self.errors.push(
          "Only identifier params supported for now: " + token.kind.to_string(),
        )
        self.advance()
      }
    }
    if self.peek().kind == TokenKind::Comma {
      self.advance()
    } else {
      break
    }
  }
  self.consume(TokenKind::RParen)
  params
}

///|
fn Parser::parse_identifier(self : Parser) -> Identifier {
  let token = self.peek()
  if token.kind == TokenKind::Identifier {
    self.advance()
    Identifier::{
      name: token.value.to_string(),
      optional: false,
      typeAnnotation: None,
    }
  } else {
    self.errors.push("Expected identifier, got \{token.kind}")
    self.advance()
    Identifier::{ name: "", optional: false, typeAnnotation: None }
  }
}

///|
fn Parser::parse_class_expression(self : Parser) -> Expression {
  self.consume(TokenKind::Class)
  let mut id = None
  if self.peek().kind == TokenKind::Identifier {
    id = Some(self.parse_identifier())
  }
  let mut superClass = None
  if self.peek().kind == TokenKind::Extends {
    self.advance()
    superClass = Some(self.parse_expression())
  }
  let body = self.parse_class_body()
  Expression::ClassExpression(ClassExpression::{
    id,
    superClass,
    body,
    decorators: [],
    typeParameters: None,
    superTypeArguments: None,
    abstract_: false,
    implements: None,
  })
}

///|
fn Parser::parse_class_body(self : Parser) -> ClassBody {
  self.consume(TokenKind::LBrace)
  let body = []
  while self.peek().kind != TokenKind::RBrace &&
        self.peek().kind != TokenKind::EOF {
    if self.peek().kind == TokenKind::Semicolon {
      self.advance()
      continue
    }
    body.push(self.parse_class_member())
  }
  self.consume(TokenKind::RBrace)
  ClassBody::{ body, }
}

///|
fn Parser::parse_class_member(self : Parser) -> ClassMember {
  // Check for static
  let mut static_ = false
  if self.peek().kind == TokenKind::Static {
    // Lookahead to see if it is just a method named static
    let next = self.lookahead()
    let k = next.kind
    if k == TokenKind::LParen ||
      k == TokenKind::LessThan ||
      k == TokenKind::Equal ||
      k == TokenKind::Semicolon ||
      k == TokenKind::Colon {
      // method/prop named static
    } else {
      self.advance()
      static_ = true
    }
  }
  let mut is_accessor = false
  let mut accessor_kind = MethodKind::Get
  if self.peek().kind == TokenKind::Identifier &&
    (self.peek().value == "get" || self.peek().value == "set") {
    let next = self.lookahead()
    match next.kind {
      TokenKind::Identifier
      | TokenKind::StringLiteral
      | TokenKind::NumericLiteral
      | TokenKind::LBracket => {
        is_accessor = true
        accessor_kind = if self.peek().value == "get" {
          MethodKind::Get
        } else {
          MethodKind::Set
        }
      }
      _ => ()
    }
  }
  if is_accessor {
    self.advance() // consume get/set
  }
  let mut generator = false
  if self.peek().kind == TokenKind::Star {
    self.advance()
    generator = true
  }
  let mut async_ = false
  if !is_accessor && !generator && self.peek().kind == TokenKind::Async {
    // Check if it is async method or just method named async
    let next = self.lookahead()
    match next.kind {
      TokenKind::Identifier
      | TokenKind::StringLiteral
      | TokenKind::NumericLiteral
      | TokenKind::LBracket
      | TokenKind::Star => {
        self.advance()
        async_ = true
        if self.peek().kind == TokenKind::Star {
          self.advance()
          generator = true
        }
      }
      _ => ()
    }
  }

  // Parse key
  let (key, computed) = if self.peek().kind == TokenKind::LBracket {
    self.advance()
    let expr = self.parse_assignment()
    self.consume(TokenKind::RBracket)
    (expr, true)
  } else {
    (self.parse_identifier_name(), false)
  }

  // Check for method body
  let is_method = self.peek().kind == TokenKind::LParen ||
    (is_accessor && self.peek().kind == TokenKind::LParen) ||
    (async_ && self.peek().kind == TokenKind::LParen) ||
    (generator && self.peek().kind == TokenKind::LParen)
  if is_method {
    let params = self.parse_function_params()
    let body = self.parse_block_statement()
    let key_is_constructor = match key {
      Expression::Identifier(id) => id.name == "constructor"
      _ => false
    }
    let kind = if is_accessor {
      accessor_kind
    } else if !computed && !static_ && key_is_constructor {
      MethodKind::Constructor
    } else {
      MethodKind::Method
    }
    ClassMember::ClassMethod(ClassMethod::{
      key,
      kind,
      static_,
      computed,
      params,
      body,
      generator,
      async_,
      accessibility: None,
      override_: None,
      abstract_: None,
      optional: None,
      decorators: [],
      variance: None,
    })
  } else {
    // Property
    let value : Expression? = if self.peek().kind == TokenKind::Equal {
      self.advance()
      Some(self.parse_assignment())
    } else {
      None
    }
    if self.peek().kind == TokenKind::Semicolon {
      self.advance()
    }
    ClassMember::ClassProperty(ClassProperty::{
      key,
      value,
      typeAnnotation: None,
      static_,
      computed,
      accessibility: None,
      optional: None,
      readonly_: None,
      definite: None,
      decorators: [],
      variance: None,
      override_: None,
      abstract_: None,
    })
  }
}

//|

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
      let val = @strconv.parse_double(token.value) catch { _ => 0.0 }
      Expression::NumericLiteral({ value: val })
    }
    TokenKind::StringLiteral => {
      self.advance()
      Expression::StringLiteral({ value: token.value })
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
      self.advance()
      // println("Unexpected token in parse_primary: \{token.kind}")
      abort("Unexpected token in parse_primary: \{token.kind}")
    }
  }
}

fn Parser::parse_array_literal(self : Parser) -> Expression {
  self.consume(TokenKind::LBracket)
  let elements : Array[ArrayElement] = []
  while self.peek().kind != TokenKind::RBracket {
    if self.peek().kind == TokenKind::Comma {
      elements.push(ArrayElement::OmittedExpression)
      self.advance()
    } else if self.peek().kind == TokenKind::Ellipsis {
      self.advance()
      let arg = self.parse_assignment()
      elements.push(ArrayElement::SpreadElement(argument=arg))
      if self.peek().kind == TokenKind::Comma {
        self.advance()
      }
    } else {
      let expr = self.parse_assignment()
      elements.push(ArrayElement::Expression(expr))
      if self.peek().kind == TokenKind::Comma {
        self.advance()
      } else if self.peek().kind != TokenKind::RBracket {
        // TODO: Error handling
        break
      }
    }
  }
  self.consume(TokenKind::RBracket)
  Expression::ArrayLiteralExpression(ArrayExpression::{ elements, })
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
      _ => abort("Only identifier params supported for now")
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

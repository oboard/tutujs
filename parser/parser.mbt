///|
using @tokens {type TokenKind}

///|
using @lexer {type LexToken}

///|
pub(all) struct Parser {
  tokens : Array[LexToken]
  mut pos : Int
}

///|
pub fn Parser::new(tokens : Array[LexToken]) -> Parser {
  { tokens, pos: 0 }
}

///|
pub fn parse(tokens : Array[LexToken]) -> Program {
  let p = Parser::new(tokens).parse_program()
  p
}

///|
pub fn Parser::parse_program(self : Parser) -> Program {
  let body = []
  while self.peek().kind != TokenKind::EndOfFile {
    let stmt = self.parse_statement()
    body.push(stmt)
  }
  { sourceType: Module, body, directives: [], interpreter: None }
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
fn Parser::parse_expression(self : Parser) -> Expression {
  self.parse_assignment()
}

///|
fn Parser::parse_assignment(self : Parser) -> Expression {
  let left = self.parse_conditional()
  let token = self.peek()
  match token.kind {
    TokenKind::Equal => {
      self.advance()
      let right = self.parse_assignment()
      let pattern = self.to_pattern(left)
      Expression::AssignmentExpression({
        operator: AssignmentOperator::Assign,
        left: pattern,
        right,
      })
    }
    TokenKind::PlusEqual => {
      self.advance()
      let right = self.parse_assignment()
      let pattern = self.to_pattern(left)
      Expression::AssignmentExpression({
        operator: AssignmentOperator::Plus,
        left: pattern,
        right,
      })
    }
    TokenKind::MinusEqual => {
      self.advance()
      let right = self.parse_assignment()
      let pattern = self.to_pattern(left)
      Expression::AssignmentExpression({
        operator: AssignmentOperator::MinusAssign,
        left: pattern,
        right,
      })
    }
    TokenKind::StarEqual => {
      self.advance()
      let right = self.parse_assignment()
      let pattern = self.to_pattern(left)
      Expression::AssignmentExpression({
        operator: AssignmentOperator::MultiplyAssign,
        left: pattern,
        right,
      })
    }
    TokenKind::SlashEqual => {
      self.advance()
      let right = self.parse_assignment()
      let pattern = self.to_pattern(left)
      Expression::AssignmentExpression({
        operator: AssignmentOperator::DivideAssign,
        left: pattern,
        right,
      })
    }
    TokenKind::PercentEqual => {
      self.advance()
      let right = self.parse_assignment()
      let pattern = self.to_pattern(left)
      Expression::AssignmentExpression({
        operator: AssignmentOperator::PercentAssign,
        left: pattern,
        right,
      })
    }
    TokenKind::LeftShiftEqual => {
      self.advance()
      let right = self.parse_assignment()
      let pattern = self.to_pattern(left)
      Expression::AssignmentExpression({
        operator: AssignmentOperator::LeftShiftAssign,
        left: pattern,
        right,
      })
    }
    TokenKind::RightShiftEqual => {
      self.advance()
      let right = self.parse_assignment()
      let pattern = self.to_pattern(left)
      Expression::AssignmentExpression({
        operator: AssignmentOperator::RightShiftAssign,
        left: pattern,
        right,
      })
    }
    TokenKind::UnsignedRightShiftEqual => {
      self.advance()
      let right = self.parse_assignment()
      let pattern = self.to_pattern(left)
      Expression::AssignmentExpression({
        operator: AssignmentOperator::UnsignedRightShiftAssign,
        left: pattern,
        right,
      })
    }
    TokenKind::AmpersandEqual => {
      self.advance()
      let right = self.parse_assignment()
      let pattern = self.to_pattern(left)
      Expression::AssignmentExpression({
        operator: AssignmentOperator::BitwiseAndAssign,
        left: pattern,
        right,
      })
    }
    TokenKind::CaretEqual => {
      self.advance()
      let right = self.parse_assignment()
      let pattern = self.to_pattern(left)
      Expression::AssignmentExpression({
        operator: AssignmentOperator::BitwiseXorAssign,
        left: pattern,
        right,
      })
    }
    TokenKind::PipeEqual => {
      self.advance()
      let right = self.parse_assignment()
      let pattern = self.to_pattern(left)
      Expression::AssignmentExpression({
        operator: AssignmentOperator::BitwiseOrAssign,
        left: pattern,
        right,
      })
    }
    _ => left
  }
}

///|
fn Parser::to_pattern(self : Parser, expr : Expression) -> Pattern {
  match expr {
    Identifier(id) => Pattern::Identifier(id)
    MemberExpression(expr) => Pattern::MemberExpression(expr)
    ArrayLiteralExpression(expr) => {
      let elements = []
      for elem in expr.elements {
        match elem {
          Expression(expr) => elements.push(self.to_pattern(expr))
          SpreadElement(argument=arg) =>
            elements.push(
              Pattern::RestElement({
                argument: self.to_pattern(arg),
                optional: None,
                typeAnnotation: None,
              }),
            )
          OmittedExpression => elements.push(OmittedExpression)
        }
      }
      Pattern::ArrayPattern({ elements, optional: None, typeAnnotation: None })
    }
    ObjectExpression(expr) => {
      let properties : Array[AssignmentProperty] = []
      for prop in expr.properties {
        match prop {
          ObjectProperty(prop) =>
            properties.push({
              key: prop.key,
              value: self.to_pattern(prop.value),
              shorthand: prop.shorthand,
              computed: prop.computed,
              decorators: prop.decorators,
            })
          SpreadElement(_) =>
            abort("Spread element not supported in object pattern yet")
          ObjectMethod(_) =>
            abort("Invalid object method in assignment pattern")
        }
      }
      Pattern::ObjectPattern({
        properties,
        optional: None,
        typeAnnotation: None,
      })
    }
    AssignmentExpression(expr) =>
      if expr.operator == AssignmentOperator::Assign {
        Pattern::AssignmentPattern({
          left: expr.left,
          right: expr.right,
          optional: None,
          typeAnnotation: None,
        })
      } else {
        abort("Invalid assignment operator in pattern")
      }
    _ =>
      // TODO: Improve error handling
      abort("Invalid left-hand side in assignment")
  }
}

///|
fn Parser::parse_conditional(self : Parser) -> Expression {
  let test_expr = self.parse_logical_or()
  if self.peek().kind == TokenKind::Question {
    self.advance()
    let consequent = self.parse_assignment()
    self.consume(TokenKind::Colon)
    let alternate = self.parse_assignment()
    Expression::ConditionalExpression({
      test_: test_expr,
      consequent,
      alternate,
    })
  } else {
    test_expr
  }
}

///|
fn Parser::parse_logical_or(self : Parser) -> Expression {
  let mut left = self.parse_logical_and()
  while self.peek().kind == TokenKind::BarBar {
    self.advance()
    let right = self.parse_logical_and()
    left = Expression::LogicalExpression({
      operator: LogicalOperator::LogicalOr,
      left,
      right,
    })
  }
  left
}

///|
fn Parser::parse_logical_and(self : Parser) -> Expression {
  let mut left = self.parse_bitwise_or()
  while self.peek().kind == TokenKind::AmpersandAmpersand {
    self.advance()
    let right = self.parse_bitwise_or()
    left = Expression::LogicalExpression({
      operator: LogicalOperator::LogicalAnd,
      left,
      right,
    })
  }
  left
}

///|
fn Parser::parse_equality(self : Parser) -> Expression {
  let mut left = self.parse_relational()
  while self.peek().kind
        is (TokenKind::EqualEqual
        | TokenKind::ExclamationEqual
        | TokenKind::EqualEqualEqual
        | TokenKind::ExclamationEqualEqual) {
    let op_token = self.peek()
    self.advance()
    let right = self.parse_relational()
    let operator = match op_token.kind {
      TokenKind::EqualEqual => BinaryOperator::Equal
      TokenKind::ExclamationEqual => BinaryOperator::NotEqual
      TokenKind::EqualEqualEqual => BinaryOperator::StrictEqual
      TokenKind::ExclamationEqualEqual => BinaryOperator::StrictNotEqual
      _ => BinaryOperator::Equal // Should not happen
    }
    left = Expression::BinaryExpression({ operator, left, right })
  }
  left
}

///|
fn Parser::parse_relational(self : Parser) -> Expression {
  let mut left = self.parse_shift()
  while self.peek().kind
        is (TokenKind::LessThan
        | TokenKind::LessThanOrEqual
        | TokenKind::GreaterThan
        | TokenKind::GreaterThanOrEqual
        | TokenKind::In
        | TokenKind::Instanceof) {
    let op_token = self.peek()
    self.advance()
    let right = self.parse_shift()
    let operator = match op_token.kind {
      TokenKind::LessThan => BinaryOperator::LessThan
      TokenKind::LessThanOrEqual => BinaryOperator::LessThanOrEqual
      TokenKind::GreaterThan => BinaryOperator::GreaterThan
      TokenKind::GreaterThanOrEqual => BinaryOperator::GreaterThanOrEqual
      TokenKind::In => BinaryOperator::In
      TokenKind::Instanceof => BinaryOperator::Instanceof
      _ => BinaryOperator::LessThan // Should not happen
    }
    left = Expression::BinaryExpression({ operator, left, right })
  }
  left
}

///|
fn Parser::parse_shift(self : Parser) -> Expression {
  let mut left = self.parse_additive()
  while self.peek().kind
        is (TokenKind::LeftShift
        | TokenKind::RightShift
        | TokenKind::UnsignedRightShift) {
    let op_token = self.peek()
    self.advance()
    let right = self.parse_additive()
    let operator = match op_token.kind {
      TokenKind::LeftShift => BinaryOperator::LeftShift
      TokenKind::RightShift => BinaryOperator::RightShift
      TokenKind::UnsignedRightShift => BinaryOperator::UnsignedRightShift
      _ => BinaryOperator::LeftShift // Should not happen
    }
    left = Expression::BinaryExpression({ operator, left, right })
  }
  left
}

///|
fn Parser::parse_additive(self : Parser) -> Expression {
  let mut left = self.parse_multiplicative()
  while self.peek().kind is (TokenKind::Plus | TokenKind::Minus) {
    let op_token = self.peek()
    self.advance()
    let right = self.parse_multiplicative()
    let operator = match op_token.kind {
      TokenKind::Plus => BinaryOperator::Plus
      TokenKind::Minus => BinaryOperator::Minus
      _ => BinaryOperator::Plus // Should not happen
    }
    left = Expression::BinaryExpression({ operator, left, right })
  }
  left
}

///|
fn Parser::parse_multiplicative(self : Parser) -> Expression {
  let mut left = self.parse_unary()
  while self.peek().kind
        is (TokenKind::Star | TokenKind::Slash | TokenKind::Percent) {
    let op_token = self.peek()
    self.advance()
    let right = self.parse_unary()
    let operator = match op_token.kind {
      TokenKind::Star => BinaryOperator::Star
      TokenKind::Slash => BinaryOperator::Slash
      TokenKind::Percent => BinaryOperator::Percent
      _ => BinaryOperator::Star // Should not happen
    }
    left = Expression::BinaryExpression({ operator, left, right })
  }
  left
}

///|
fn Parser::parse_bitwise_and(self : Parser) -> Expression {
  let mut left = self.parse_equality()
  while self.peek().kind == TokenKind::Ampersand {
    // let op_token = self.peek()
    self.advance()
    let right = self.parse_equality()
    let operator = BinaryOperator::BitwiseAnd
    left = Expression::BinaryExpression({ operator, left, right })
  }
  left
}

///|
fn Parser::parse_bitwise_xor(self : Parser) -> Expression {
  let mut left = self.parse_bitwise_and()
  while self.peek().kind == TokenKind::Caret {
    // let op_token = self.peek()
    self.advance()
    let right = self.parse_bitwise_and()
    let operator = BinaryOperator::BitwiseXor
    left = Expression::BinaryExpression({ operator, left, right })
  }
  left
}

///|
fn Parser::parse_bitwise_or(self : Parser) -> Expression {
  let mut left = self.parse_bitwise_xor()
  while self.peek().kind == TokenKind::Pipe {
    // let op_token = self.peek()
    self.advance()
    let right = self.parse_bitwise_xor()
    let operator = BinaryOperator::BitwiseOr
    left = Expression::BinaryExpression({ operator, left, right })
  }
  left
}

///|
fn Parser::parse_unary(self : Parser) -> Expression {
  let token = self.peek()
  match token.kind {
    TokenKind::Delete
    | TokenKind::Void
    | TokenKind::Typeof
    | TokenKind::Plus
    | TokenKind::Minus
    | TokenKind::Ampersand
    | TokenKind::Pipe => {
      self.advance()
      let argument = self.parse_unary()
      let operator = match token.kind {
        TokenKind::Delete => UnaryOperator::Delete
        TokenKind::Void => UnaryOperator::Void
        TokenKind::Typeof => UnaryOperator::Typeof
        TokenKind::Plus => UnaryOperator::Plus
        TokenKind::Minus => UnaryOperator::Minus
        TokenKind::Ampersand => UnaryOperator::BitwiseNot
        TokenKind::Pipe => UnaryOperator::Not
        _ => UnaryOperator::Not // Should not happen
      }
      Expression::UnaryExpression({ operator, prefix: true, argument })
    }
    TokenKind::PlusPlus | TokenKind::MinusMinus => {
      self.advance()
      let argument = self.parse_unary()
      let operator = match token.kind {
        TokenKind::PlusPlus => UpdateOperator::Increment
        TokenKind::MinusMinus => UpdateOperator::Decrement
        _ => UpdateOperator::Increment // Should not happen
      }
      Expression::UpdateExpression({ operator, prefix: true, argument })
    }
    _ => self.parse_update_postfix()
  }
}

///|
fn Parser::parse_update_postfix(self : Parser) -> Expression {
  let lhs = self.parse_lhs()
  let token = self.peek()
  match token.kind {
    TokenKind::PlusPlus => {
      self.advance()
      Expression::UpdateExpression({
        operator: UpdateOperator::Increment,
        prefix: false,
        argument: lhs,
      })
    }
    TokenKind::MinusMinus => {
      self.advance()
      Expression::UpdateExpression({
        operator: UpdateOperator::Decrement,
        prefix: false,
        argument: lhs,
      })
    }
    _ => lhs
  }
}

///|
fn Parser::parse_lhs(self : Parser) -> Expression {
  if self.peek().kind == TokenKind::New {
    self.parse_new_expression()
  } else {
    self.parse_call_expression()
  }
}

///|
fn Parser::parse_new_expression(self : Parser) -> Expression {
  self.advance() // consume 'new'
  let callee = if self.peek().kind == TokenKind::New {
    self.parse_new_expression()
  } else {
    self.parse_member_expression()
  }
  if self.peek().kind == TokenKind::LParen {
    let arguments = self.parse_arguments()
    Expression::NewExpression({
      callee,
      arguments,
      optional: false,
      typeArguments: None,
    })
  } else {
    Expression::NewExpression({
      callee,
      arguments: [],
      optional: false,
      typeArguments: None,
    })
  }
}

///|
fn Parser::parse_member_expression(self : Parser) -> Expression {
  let mut object = self.parse_primary()
  while true {
    match self.peek().kind {
      TokenKind::LBracket => {
        self.advance()
        let property = self.parse_expression()
        self.consume(TokenKind::RBracket)
        object = Expression::MemberExpression({
          object,
          property,
          computed: true,
          optional: None,
        })
      }
      TokenKind::Dot => {
        self.advance()
        let property = self.parse_identifier_name()
        object = Expression::MemberExpression({
          object,
          property,
          computed: false,
          optional: None,
        })
      }
      _ => break
    }
  }
  object
}

///|
fn Parser::parse_call_expression(self : Parser) -> Expression {
  let mut callee = self.parse_member_expression()
  while true {
    match self.peek().kind {
      TokenKind::LParen => {
        let arguments = self.parse_arguments()
        callee = Expression::CallExpression({
          callee,
          arguments,
          optional: false,
          typeArguments: None,
        })
      }
      TokenKind::LBracket => {
        self.advance()
        let property = self.parse_expression()
        self.consume(TokenKind::RBracket)
        callee = Expression::MemberExpression({
          object: callee,
          property,
          computed: true,
          optional: None,
        })
      }
      TokenKind::Dot => {
        self.advance()
        let property = self.parse_identifier_name()
        callee = Expression::MemberExpression({
          object: callee,
          property,
          computed: false,
          optional: None,
        })
      }
      _ => break
    }
  }
  callee
}

///|
fn Parser::parse_arguments(self : Parser) -> Array[Expression] {
  self.consume(TokenKind::LParen)
  let args = []
  if self.peek().kind != TokenKind::RParen {
    while true {
      args.push(self.parse_assignment()) // ArgumentList allows AssignmentExpression
      if self.peek().kind == TokenKind::Comma {
        self.advance()
      } else {
        break
      }
    }
  }
  self.consume(TokenKind::RParen)
  args
}

///|
fn Parser::parse_identifier_name(self : Parser) -> Expression {
  let token = self.peek()
  match token.kind {
    TokenKind::Identifier => {
      self.advance()
      Expression::Identifier(Identifier::{
        name: token.value.to_string(),
        optional: false,
        typeAnnotation: None,
      })
    }
    _ =>
      // Allow keywords as identifier names in member access (e.g. promise.catch)
      if token.kind.is_keyword() {
        self.advance()
        Expression::Identifier(Identifier::{
          name: token.value.to_string(),
          optional: false,
          typeAnnotation: None,
        })
      } else {
        self.advance()
        Expression::Identifier(Identifier::{
          name: "",
          optional: false,
          typeAnnotation: None,
        }) // Error
      }
  }
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
      let val = @strconv.parse_double(token.value) catch { _ => 0.0 }
      Expression::NumericLiteral({ value: val })
    }
    TokenKind::StringLiteral => {
      self.advance()
      Expression::StringLiteral({ value: token.value })
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
      let expr = self.parse_expression()
      self.consume(TokenKind::RParen)
      expr
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

///|
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
      // Parse Key
      let (key, computed) = if self.peek().kind == TokenKind::LBracket {
        self.advance()
        let expr = self.parse_assignment()
        self.consume(TokenKind::RBracket)
        (expr, true)
      } else {
        (self.parse_identifier_name(), false)
      }
      if self.peek().kind == TokenKind::Colon {
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
        if self.peek().kind == TokenKind::Comma {
          self.advance()
        }
      } else {
        // Shorthand or Method
        // TODO: Handle methods
        match key {
          Identifier(_) =>
            properties.push(
              ObjectMember::ObjectProperty(ObjectProperty::{
                key,
                value: key,
                shorthand: true,
                computed,
                decorators: [],
              }),
            )
          _ =>
            // Error or method?
            ()
        }
        if self.peek().kind == TokenKind::Comma {
          self.advance()
        }
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

///|
fn Parser::parse_statement(self : Parser) -> Statement {
  // println("DEBUG: parse_statement peek=\(self.peek().kind)")
  match self.peek().kind {
    TokenKind::LBrace => Statement::BlockStatement(self.parse_block_statement())
    TokenKind::Return => self.parse_return_statement()
    TokenKind::Function => self.parse_function_declaration()
    TokenKind::Async =>
      if self.lookahead().kind == TokenKind::Function {
        self.advance() // consume 'async'
        self.parse_function_declaration(async_=true)
      } else {
        let expr = self.parse_expression()
        if self.peek().kind == TokenKind::Semicolon {
          self.advance()
        }
        Statement::ExpressionStatement({ expression: expr, directive: None })
      }
    TokenKind::Identifier => {
      let expr = self.parse_expression()
      if self.peek().kind == TokenKind::Semicolon {
        self.advance()
      }
      Statement::ExpressionStatement({ expression: expr, directive: None })
    }
    _ => {
      let expr = self.parse_expression()
      if self.peek().kind == TokenKind::Semicolon {
        self.advance()
      }
      Statement::ExpressionStatement({ expression: expr, directive: None })
    }
  }
}

///|
fn Parser::parse_block_statement(self : Parser) -> BlockStatement {
  self.consume(TokenKind::LBrace)
  let body = []
  while self.peek().kind != TokenKind::RBrace &&
        self.peek().kind != TokenKind::EndOfFile {
    body.push(self.parse_statement())
  }
  self.consume(TokenKind::RBrace)
  { body, directives: [] }
}

///|
fn Parser::parse_return_statement(self : Parser) -> Statement {
  self.consume(TokenKind::Return)
  let arg : Expression? = if self.peek().kind == TokenKind::Semicolon {
    None
  } else {
    Option::Some(self.parse_expression())
  }
  if self.peek().kind == TokenKind::Semicolon {
    self.advance()
  }
  Statement::ReturnStatement({ argument: arg })
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
fn Parser::parse_function_declaration(
  self : Parser,
  async_? : Bool = false,
) -> Statement {
  // println("DEBUG: parse_function_declaration async=\(async_)")
  self.consume(TokenKind::Function)
  let generator = if self.peek().kind == TokenKind::Star {
    self.advance()
    true
  } else {
    false
  }
  let id = if self.peek().kind is TokenKind::Identifier {
    let token = self.peek()
    self.advance()
    Identifier::{
      name: token.value.to_string(),
      optional: false,
      typeAnnotation: None,
    }
  } else {
    Identifier::{ name: "", optional: false, typeAnnotation: None }
  }
  let params = self.parse_function_params()
  let body = self.parse_block_statement()
  Statement::FunctionDeclaration({
    id,
    params,
    body,
    generator,
    async_,
    expression: false,
    typeParameters: None,
    returnType: None,
    declare_: false,
  })
}

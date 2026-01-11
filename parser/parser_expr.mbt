///|

///|
pub fn Parser::parse_expression(self : Parser) -> Expression {
  self.parse_sequence_expression()
}

///|
fn Parser::parse_sequence_expression(self : Parser) -> Expression {
  let left = self.parse_assignment()
  if self.peek().kind == TokenKind::Comma {
    let expressions = [left]
    while self.peek().kind == TokenKind::Comma {
      self.advance()
      expressions.push(self.parse_assignment())
    }
    Expression::SequenceExpression({ expressions, })
  } else {
    left
  }
}

///|
fn Parser::parse_assignment(self : Parser) -> Expression {
  let left = self.parse_conditional()
  let token = self.peek()
  match token.kind {
    TokenKind::Arrow => {
      self.advance()
      let params = match left {
        Identifier(id) => [Pattern::Identifier(id)]
        SequenceExpression(seq) => {
          let params = []
          for expr in seq.expressions {
            params.push(self.to_pattern(expr))
          }
          params
        }
        _ => [self.to_pattern(left)]
      }
      let body = if self.peek().kind == TokenKind::LBrace {
        FunctionBody::BlockStatement(self.parse_block_statement())
      } else {
        FunctionBody::Expression(self.parse_assignment())
      }
      Expression::ArrowFunctionExpression({
        params,
        body,
        generator: false,
        async_: false,
        expression: match body {
          FunctionBody::Expression(_) => true
          _ => false
        },
        typeParameters: None,
        returnType: None,
      })
    }
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
    TokenKind::StarStarEqual => {
      self.advance()
      let right = self.parse_assignment()
      let pattern = self.to_pattern(left)
      Expression::AssignmentExpression({
        operator: AssignmentOperator::ExponentAssign,
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
    if op_token.kind == TokenKind::In {
      // In operator is always allowed in this context based on current requirements
    }
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
  let mut left = self.parse_exponentiation()
  while self.peek().kind
        is (TokenKind::Star | TokenKind::Slash | TokenKind::Percent) {
    let op_token = self.peek()
    self.advance()
    let right = self.parse_exponentiation()
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
fn Parser::parse_exponentiation(self : Parser) -> Expression {
  let left = self.parse_unary()
  if self.peek().kind == TokenKind::StarStar {
    self.advance()
    let right = self.parse_exponentiation() // Right associative
    Expression::BinaryExpression({
      operator: BinaryOperator::Exponent,
      left,
      right,
    })
  } else {
    left
  }
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
    | TokenKind::Tilde
    | TokenKind::Exclamation => {
      self.advance()
      let argument = self.parse_unary()
      let operator = match token.kind {
        TokenKind::Delete => UnaryOperator::Delete
        TokenKind::Void => UnaryOperator::Void
        TokenKind::Typeof => UnaryOperator::Typeof
        TokenKind::Plus => UnaryOperator::Plus
        TokenKind::Minus => UnaryOperator::Minus
        TokenKind::Tilde => UnaryOperator::BitwiseNot
        TokenKind::Exclamation => UnaryOperator::Not
        _ => UnaryOperator::Not // Should not happen
      }
      Expression::PrefixUnaryExpression({ operator, prefix: true, argument })
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
  self.parse_call_expression()
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
  let mut callee = if self.peek().kind == TokenKind::New {
    self.parse_new_expression()
  } else {
    self.parse_member_expression()
  }
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
        if self.peek().kind == TokenKind::RParen {
          break
        }
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
    TokenKind::StringLiteral => {
      self.advance()
      Expression::StringLiteral({ value: token.value })
    }
    TokenKind::NumericLiteral => {
      self.advance()
      let val = @strconv.parse_double(token.value) catch { _ => 0.0 }
      Expression::NumericLiteral({ value: val })
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

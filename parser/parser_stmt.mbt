///|

///|
fn Parser::parse_expression_statement(self : Parser) -> ExpressionStatement {
  let expression = self.parse_expression()
  let mut directive = None
  if self.peek().kind == TokenKind::Semicolon {
    self.advance()
  }
  match expression {
    Expression::StringLiteral(s) => {
      if s.value == "use strict" {
        directive = Some(
          Directive::{ value: DirectiveLiteral::{ value: s.value.to_string() } },
        )
      }
    }
    _ => ()
  }
  { expression, directive }
}

///|
fn Parser::parse_statement(self : Parser) -> Statement {
  match self.peek().kind {
    TokenKind::LBrace => Statement::BlockStatement(self.parse_block_statement())
    TokenKind::Return => self.parse_return_statement()
    TokenKind::Function => self.parse_function_declaration()
    TokenKind::Var | TokenKind::Let | TokenKind::Const =>
      self.parse_variable_declaration()
    TokenKind::If => self.parse_if_statement()
    TokenKind::While => self.parse_while_statement()
    TokenKind::Do => self.parse_do_while_statement()
    TokenKind::For => self.parse_for_statement()
    TokenKind::Switch => self.parse_switch_statement()
    TokenKind::Break => self.parse_break_statement()
    TokenKind::Continue => self.parse_continue_statement()
    TokenKind::Throw => self.parse_throw_statement()
    TokenKind::Try => self.parse_try_statement()
    TokenKind::Debugger => self.parse_debugger_statement()
    TokenKind::With => self.parse_with_statement()
    TokenKind::Async =>
      if self.lookahead().kind == TokenKind::Function {
        self.advance() // consume 'async'
        self.parse_function_declaration(async_=true)
      } else {
        let expr = self.parse_expression()
        if self.peek().kind == TokenKind::Colon {
          match expr {
            Expression::Identifier(id) =>
              return self.parse_labeled_statement(id)
            _ => ()
          }
        }
        if self.peek().kind == TokenKind::Semicolon {
          self.advance()
        }
        Statement::ExpressionStatement({ expression: expr, directive: None })
      }
    TokenKind::Identifier =>
      if self.peek_at(1).kind == TokenKind::Colon {
        let token = self.peek()
        self.advance() // consume identifier
        let label = Identifier::{
          name: token.value.to_string(),
          optional: false,
          typeAnnotation: None,
        }
        self.parse_labeled_statement(label)
      } else {
        Statement::ExpressionStatement(self.parse_expression_statement())
      }
    _ => Statement::ExpressionStatement(self.parse_expression_statement())
  }
}

///|
fn Parser::parse_block_statement(self : Parser) -> BlockStatement {
  self.consume(TokenKind::LBrace)
  let body = []
  let directives = []
  while self.peek().kind != TokenKind::RBrace &&
        self.peek().kind != TokenKind::EOF {
    let stmt = self.parse_statement()
    body.push(stmt)
    match stmt {
      Statement::ExpressionStatement(expr_stmt) => {
        match expr_stmt.directive {
          Some(d) => directives.push(d)
          None => ()
        }
      }
      _ => ()
    }
  }
  self.consume(TokenKind::RBrace)
  { body, directives }
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

///|
fn Parser::parse_variable_declaration(self : Parser) -> Statement {
  let kind = match self.peek().kind {
    TokenKind::Var => VariableKind::Var
    TokenKind::Let => VariableKind::Let
    TokenKind::Const => VariableKind::Const
    _ => abort("Unexpected token in variable declaration")
  }
  self.advance()
  let declarations = []
  while true {
    // We use parse_lhs to avoid consuming 'in' operator in for-in loops
    let expr = self.parse_lhs()
    let id = self.to_pattern(expr)
    let init = if self.peek().kind == TokenKind::Equal {
      self.advance()
      Some(self.parse_assignment())
    } else {
      None
    }
    declarations.push(VariableDeclarator::{ id, init, definite: false })
    if self.peek().kind == TokenKind::Comma {
      self.advance()
    } else {
      break
    }
  }
  if self.peek().kind == TokenKind::Semicolon {
    self.advance()
  }
  Statement::VariableDeclaration({ declarations, kind, declare_: false })
}

///|
fn Parser::parse_if_statement(self : Parser) -> Statement {
  self.consume(TokenKind::If)
  self.consume(TokenKind::LParen)
  let test_ = self.parse_expression()
  self.consume(TokenKind::RParen)
  let consequent = self.parse_statement()
  let alternate = if self.peek().kind == TokenKind::Else {
    self.advance()
    Option::Some(self.parse_statement())
  } else {
    None
  }
  Statement::IfStatement({ test_, consequent, alternate })
}

///|
fn Parser::parse_while_statement(self : Parser) -> Statement {
  self.consume(TokenKind::While)
  self.consume(TokenKind::LParen)
  let test_ = self.parse_expression()
  self.consume(TokenKind::RParen)
  let body = self.parse_statement()
  Statement::WhileStatement({ test_, body })
}

///|
fn Parser::parse_do_while_statement(self : Parser) -> Statement {
  self.consume(TokenKind::Do)
  let body = self.parse_statement()
  self.consume(TokenKind::While)
  self.consume(TokenKind::LParen)
  let test_ = self.parse_expression()
  self.consume(TokenKind::RParen)
  if self.peek().kind == TokenKind::Semicolon {
    self.advance()
  }
  Statement::DoWhileStatement({ body, test_ })
}

///|
fn Parser::parse_break_statement(self : Parser) -> Statement {
  self.consume(TokenKind::Break)
  let label = if self.peek().kind == TokenKind::Identifier &&
    self.has_newline_before(self.peek()) == false {
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
  if self.peek().kind == TokenKind::Semicolon {
    self.advance()
  }
  Statement::BreakStatement({ label, })
}

///|
fn Parser::parse_continue_statement(self : Parser) -> Statement {
  self.consume(TokenKind::Continue)
  let label = if self.peek().kind == TokenKind::Identifier &&
    self.has_newline_before(self.peek()) == false {
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
  if self.peek().kind == TokenKind::Semicolon {
    self.advance()
  }
  Statement::ContinueStatement({ label, })
}

///|
fn Parser::parse_debugger_statement(self : Parser) -> Statement {
  self.consume(TokenKind::Debugger)
  if self.peek().kind == TokenKind::Semicolon {
    self.advance()
  }
  Statement::DebuggerStatement(DebuggerStatement::{  })
}

///|
fn Parser::parse_throw_statement(self : Parser) -> Statement {
  self.consume(TokenKind::Throw)
  if self.has_newline_before(self.peek()) {
    abort("Unexpected newline after throw")
  }
  let argument = self.parse_expression()
  if self.peek().kind == TokenKind::Semicolon {
    self.advance()
  }
  Statement::ThrowStatement({ argument, })
}

///|
fn Parser::parse_try_statement(self : Parser) -> Statement {
  self.consume(TokenKind::Try)
  let block = self.parse_block_statement()
  let handler = if self.peek().kind == TokenKind::Catch {
    self.advance()
    let param = if self.peek().kind == TokenKind::LParen {
      self.consume(TokenKind::LParen)
      let expr = self.parse_expression()
      let pattern = self.to_pattern(expr)
      self.consume(TokenKind::RParen)
      Option::Some(pattern)
    } else {
      None
    }
    let body = self.parse_block_statement()
    Option::Some(CatchClause::{ param, body })
  } else {
    None
  }
  let finalizer = if self.peek().kind == TokenKind::Finally {
    self.advance()
    Option::Some(self.parse_block_statement())
  } else {
    None
  }
  if handler is None && finalizer is None {
    abort("Missing catch or finally clause")
  }
  Statement::TryStatement({ block, handler, finalizer })
}

///|
fn Parser::parse_switch_statement(self : Parser) -> Statement {
  self.consume(TokenKind::Switch)
  self.consume(TokenKind::LParen)
  let discriminant = self.parse_expression()
  self.consume(TokenKind::RParen)
  self.consume(TokenKind::LBrace)
  let cases = []
  while self.peek().kind != TokenKind::RBrace &&
        self.peek().kind != TokenKind::EOF {
    cases.push(self.parse_switch_case())
  }
  self.consume(TokenKind::RBrace)
  Statement::SwitchStatement({ discriminant, cases })
}

///|
fn Parser::parse_switch_case(self : Parser) -> SwitchCase {
  let test_ = if self.peek().kind == TokenKind::Case {
    self.advance()
    Option::Some(self.parse_expression())
  } else {
    self.consume(TokenKind::Default)
    None
  }
  self.consume(TokenKind::Colon)
  let consequent = []
  while self.peek().kind != TokenKind::Case &&
        self.peek().kind != TokenKind::Default &&
        self.peek().kind != TokenKind::RBrace &&
        self.peek().kind != TokenKind::EOF {
    consequent.push(self.parse_statement())
  }
  { test_, consequent }
}

///|
fn Parser::parse_variable_declaration_node(
  self : Parser,
) -> VariableDeclaration {
  let kind = match self.peek().kind {
    TokenKind::Var => VariableKind::Var
    TokenKind::Let => VariableKind::Let
    TokenKind::Const => VariableKind::Const
    _ => abort("Expected var, let, or const")
  }
  self.advance()
  let declarations = []
  while true {
    let expr = self.parse_lhs()
    let id = self.to_pattern(expr)
    let init = if self.peek().kind == TokenKind::Equal {
      self.advance()
      Some(self.parse_assignment())
    } else {
      None
    }
    declarations.push(VariableDeclarator::{ id, init, definite: false })
    if self.peek().kind == TokenKind::Comma {
      self.advance()
    } else {
      break
    }
  }
  { declarations, kind, declare_: false }
}

///|
fn Parser::scan_for_loop_separator(self : Parser) -> TokenKind? {
  let mut depth = 0
  let mut offset = 0
  while self.pos + offset < self.tokens.length() {
    let token = self.tokens[self.pos + offset]
    match token.kind {
      TokenKind::LParen | TokenKind::LBrace | TokenKind::LBracket =>
        depth = depth + 1
      TokenKind::RParen | TokenKind::RBrace | TokenKind::RBracket => {
        depth = depth - 1
        if depth < 0 {
          return None // Should not happen in valid syntax
        }
      }
      TokenKind::In | TokenKind::Identifier =>
        if depth == 0 {
          if token.kind == TokenKind::In {
            return Some(TokenKind::In)
          }
          if token.value == "of" {
            return Some(TokenKind::Identifier) // "of"
          }
        }
      TokenKind::Semicolon =>
        if depth == 0 {
          return Some(TokenKind::Semicolon)
        }
      _ => ()
    }
    offset = offset + 1
  }
  None
}

///|
fn Parser::parse_for_statement(self : Parser) -> Statement {
  self.consume(TokenKind::For)
  let await_ = if self.peek().kind == TokenKind::Await {
    self.advance()
    true
  } else {
    false
  }
  self.consume(TokenKind::LParen)
  if self.peek().kind == TokenKind::Semicolon {
    self.advance()
    let test_ = if self.peek().kind != TokenKind::Semicolon {
      Option::Some(self.parse_expression())
    } else {
      None
    }
    self.consume(TokenKind::Semicolon)
    let update = if self.peek().kind != TokenKind::RParen {
      Option::Some(self.parse_expression())
    } else {
      None
    }
    self.consume(TokenKind::RParen)
    let body = self.parse_statement()
    return Statement::ForStatement({ init: None, test_, update, body })
  }
  let is_decl = match self.peek().kind {
    TokenKind::Var | TokenKind::Let | TokenKind::Const => true
    _ => false
  }
  if is_decl {
    let decl = self.parse_variable_declaration_node()
    if self.peek().kind == TokenKind::In {
      self.advance()
      let right = self.parse_expression()
      self.consume(TokenKind::RParen)
      let body = self.parse_statement()
      return Statement::ForInStatement({
        left: ForInLeft::VariableDeclaration(decl),
        right,
        body,
        await_,
      })
    } else if self.peek().kind == TokenKind::Identifier &&
      self.peek().value == "of" {
      self.advance()
      let right = self.parse_expression()
      self.consume(TokenKind::RParen)
      let body = self.parse_statement()
      return Statement::ForOfStatement({
        left: ForOfLeft::VariableDeclaration(decl),
        right,
        body,
        await_,
      })
    } else {
      self.consume(TokenKind::Semicolon)
      let test_ = if self.peek().kind != TokenKind::Semicolon {
        Option::Some(self.parse_expression())
      } else {
        None
      }
      self.consume(TokenKind::Semicolon)
      let update = if self.peek().kind != TokenKind::RParen {
        Option::Some(self.parse_expression())
      } else {
        None
      }
      self.consume(TokenKind::RParen)
      let body = self.parse_statement()
      return Statement::ForStatement({
        init: Option::Some(ForInit::VariableDeclaration(decl)),
        test_,
        update,
        body,
      })
    }
  } else {
    // Scan ahead to distinguish for-in/of from normal for loop
    let separator = self.scan_for_loop_separator()
    match separator {
      Some(TokenKind::In) | Some(TokenKind::Identifier) => {
        // It's a for-in or for-of loop. Parse LHS without consuming 'in/of'.
        // Since we know 'in/of' is at the top level, we can use parse_lhs or parse_expression.
        // But parse_expression would consume 'in'.
        // We can parse until the separator.
        // Or simpler: since we are sure it is a for-in/of loop, the left side MUST be a LHS.
        // And parse_lhs stops at 'in'.
        let expr = self.parse_lhs()
        if self.peek().kind == TokenKind::In {
          self.advance()
          let right = self.parse_expression()
          self.consume(TokenKind::RParen)
          let body = self.parse_statement()
          let pattern = self.to_pattern(expr)
          return Statement::ForInStatement({
            left: ForInLeft::Pattern(pattern),
            right,
            body,
            await_,
          })
        } else if self.peek().kind == TokenKind::Identifier &&
          self.peek().value == "of" {
          self.advance()
          let right = self.parse_expression()
          self.consume(TokenKind::RParen)
          let body = self.parse_statement()
          let pattern = self.to_pattern(expr)
          return Statement::ForOfStatement({
            left: ForOfLeft::Pattern(pattern),
            right,
            body,
            await_,
          })
        } else {
          // Should not happen if scan logic is correct
          abort("Unexpected token in for-loop")
        }
      }
      _ => {
        // Normal for loop
        let expr = self.parse_expression()
        self.consume(TokenKind::Semicolon)
        let test_ = if self.peek().kind != TokenKind::Semicolon {
          Option::Some(self.parse_expression())
        } else {
          None
        }
        self.consume(TokenKind::Semicolon)
        let update = if self.peek().kind != TokenKind::RParen {
          Option::Some(self.parse_expression())
        } else {
          None
        }
        self.consume(TokenKind::RParen)
        let body = self.parse_statement()
        return Statement::ForStatement({
          init: Option::Some(ForInit::Expression(expr)),
          test_,
          update,
          body,
        })
      }
    }
  }
}

///|
fn Parser::parse_labeled_statement(
  self : Parser,
  label : Identifier,
) -> Statement {
  self.consume(TokenKind::Colon)
  let body = self.parse_statement()
  Statement::LabeledStatement({ label, body })
}

///|
fn Parser::parse_with_statement(self : Parser) -> Statement {
  self.consume(TokenKind::With)
  self.consume(TokenKind::LParen)
  let object = self.parse_expression()
  self.consume(TokenKind::RParen)
  let body = self.parse_statement()
  Statement::WithStatement({ object, body })
}

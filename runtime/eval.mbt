///|
pub suberror EvalError {
  Return(JSValue)
  Break(String?)
  Continue(String?)
} derive(Show)

///|
pub fn Context::eval(self : Context, code : &Show) -> JSValue {
  let lex = code.to_string() |> @lexer.parse
  // println(lex)
  let ast = lex |> @parser.parse
  // println(ast)
  let mut res = JSValue::Undefined
  for node in ast.body {
    try {
      res = self.evaluate(Statement(node))
    } catch {
      EvalError::Return(v) => return v // Top-level return
      EvalError::Break(_) => () // Illegal at top-level in strict JS, but lenient here
      EvalError::Continue(_) => () // Illegal
    }
  }
  res
}

///|
fn Context::evaluate(
  self : Context,
  node : @parser.NodeType,
) -> JSValue raise EvalError {
  match node {
    Declaration(declaration) =>
      match declaration {
        FunctionDeclaration({ id, params, body, .. }) => {
          let param_names = []
          for param in params {
            match param {
              Identifier({ name, .. }) => param_names.push(name)
              _ => ()
            }
          }
          let func = JSFunction::{
            name: Some(id.name),
            params: param_names,
            body,
            context: self,
          }
          self.scope.set(id.name, Function(func))
          Undefined
        }
        VariableDeclaration({ declarations, .. }) => {
          for decl in declarations {
            match decl.id {
              Identifier({ name, .. }) => {
                let val = match decl.init {
                  Some(expr) => self.evaluate(Expression(expr))
                  None => Undefined
                }
                self.scope.set(name, val)
              }
              _ => ()
            }
          }
          Undefined
        }
        _ => Undefined
      }
    Statement(statement) =>
      match statement {
        ExpressionStatement({ expression, .. }) =>
          self.evaluate(Expression(expression))
        ReturnStatement({ argument }) => {
          let val = match argument {
            Some(arg) => self.evaluate(Expression(arg))
            None => Undefined
          }
          raise EvalError::Return(val)
        }
        IfStatement({ test_, consequent, alternate }) =>
          if self.evaluate(Expression(test_)).is_truthy() {
            self.evaluate(Statement(consequent))
          } else {
            match alternate {
              Some(stmt) => self.evaluate(Statement(stmt))
              None => Undefined
            }
          }
        BreakStatement({ label }) => {
          let l = match label {
            Some(id) => Some(id.name)
            None => None
          }
          raise EvalError::Break(l)
        }
        ContinueStatement({ label }) => {
          let l = match label {
            Some(id) => Some(id.name)
            None => None
          }
          raise EvalError::Continue(l)
        }
        BlockStatement({ body, .. }) => {
          let mut res = JSValue::Undefined
          for stmt in body {
            res = self.evaluate(Statement(stmt))
          }
          res
        }
        WhileStatement({ test_, body }) => {
          while self.evaluate(Expression(test_)).is_truthy() {
            try self.evaluate(Statement(body)) |> ignore catch {
              EvalError::Break(label) =>
                match label {
                  Some(_) => raise EvalError::Break(label)
                  None => break
                }
              EvalError::Continue(label) =>
                match label {
                  Some(_) => raise EvalError::Continue(label)
                  None => continue
                }
              EvalError::Return(v) => raise EvalError::Return(v)
            }
          }
          Undefined
        }
        DoWhileStatement({ body, test_ }) => {
          while true {
            try self.evaluate(Statement(body)) |> ignore catch {
              EvalError::Break(label) =>
                match label {
                  Some(_) => raise EvalError::Break(label)
                  None => break
                }
              EvalError::Continue(label) =>
                match label {
                  Some(_) => raise EvalError::Continue(label)
                  None => continue
                }
              EvalError::Return(v) => raise EvalError::Return(v)
            }
            if not(self.evaluate(Expression(test_)).is_truthy()) {
              break
            }
          }
          Undefined
        }
        ForStatement({ init, test_, update, body }) => {
          // Init
          match init {
            Some(decl) =>
              self.evaluate(Declaration(VariableDeclaration(decl))) |> ignore
            None => ()
          }
          while true {
            // Test
            match test_ {
              Some(expr) =>
                if not(self.evaluate(Expression(expr)).is_truthy()) {
                  break
                }
              None => ()
            }
            // Body
            try self.evaluate(Statement(body)) |> ignore catch {
              EvalError::Break(label) =>
                match label {
                  Some(_) => raise EvalError::Break(label)
                  None => break
                }
              EvalError::Continue(label) =>
                match label {
                  Some(_) => raise EvalError::Continue(label)
                  None => ()
                }
              EvalError::Return(v) => raise EvalError::Return(v)
            }
            // Update
            match update {
              Some(expr) => self.evaluate(Expression(expr)) |> ignore
              None => ()
            }
          }
          Undefined
        }
        SwitchStatement({ discriminant, cases }) => {
          let val = self.evaluate(Expression(discriminant))
          let mut match_found = false
          for case_ in cases {
            if match_found {
              // Fallthrough execution
              for stmt in case_.consequent {
                try self.evaluate(Statement(stmt)) |> ignore catch {
                  EvalError::Break(_) => break // Break breaks out of switch
                  // Continue inside switch applies to enclosing loop, propagate it? 
                  // JS semantics: continue in switch applies to loop.
                  EvalError::Continue(l) => raise EvalError::Continue(l)
                  EvalError::Return(v) => raise EvalError::Return(v)
                }
              }
            } else {
              let should_exec = match case_.test_ {
                Some(test_expr) => {
                  let test_val = self.evaluate(Expression(test_expr))
                  val.strict_equal(test_val)
                }
                None => true // Default case
              }
              if should_exec {
                match_found = true
                for stmt in case_.consequent {
                  try self.evaluate(Statement(stmt)) |> ignore catch {
                    EvalError::Break(_) => return Undefined // Break switch
                    EvalError::Continue(l) => raise EvalError::Continue(l)
                    EvalError::Return(v) => raise EvalError::Return(v)
                  }
                }
              }
            }
            // If we broke out of inner loop (Wait, break in Moonbit breaks the loop 'for case_ in cases')
            // We need to verify if 'Break' caught was for switch or loop.
            // My implementation above catches Break and returns Undefined, which stops the 'for case_ in cases' loop.
            // Correct.
          }
          Undefined
        }
        FunctionDeclaration(decl) =>
          self.evaluate(Declaration(FunctionDeclaration(decl)))
        VariableDeclaration(decl) =>
          self.evaluate(Declaration(VariableDeclaration(decl)))
        _ => Undefined
      }
    Expression(expression) =>
      match expression {
        CallExpression({ callee, arguments, .. }) => {
          let callee_val = self.evaluate(Expression(callee))
          match callee_val {
            Function(func) => {
              let new_ctx = new(parent=func.context)
              for i, arg_expr in arguments {
                if i < func.params.length() {
                  let arg_val = self.evaluate(Expression(arg_expr))
                  new_ctx.scope.set(func.params[i], arg_val)
                }
              }
              let mut res = JSValue::Undefined
              try {
                for stmt in func.body.body {
                  res = new_ctx.evaluate(Statement(stmt))
                }
                res // Return last statement value if no explicit return
              } catch {
                EvalError::Return(v) => v
                EvalError::Break(l) => raise EvalError::Break(l)
                EvalError::Continue(l) => raise EvalError::Continue(l)
              }
            }
            _ => Undefined
          }
        }
        ConditionalExpression({ test_, consequent, alternate }) =>
          if self.evaluate(Expression(test_)).is_truthy() {
            self.evaluate(Expression(consequent))
          } else {
            self.evaluate(Expression(alternate))
          }
        BinaryExpression({ operator, left, right }) => {
          let left = self.evaluate(Expression(left))
          let right = self.evaluate(Expression(right))
          match operator {
            Minus => left - right
            Plus => left + right
            StrictNotEqual => Boolean(left != right)
            StrictEqual => Boolean(left == right)
            NotEqual => Boolean(!left.unstrict_equal(right))
            Equal => Boolean(left.unstrict_equal(right))
            LessThan => Boolean(left < right)
            LessThanOrEqual => Boolean(left <= right)
            GreaterThan => Boolean(left > right)
            GreaterThanOrEqual => Boolean(left >= right)
            BitwiseOr => left.bitwise_or(right)
            BitwiseXor => left.bitwise_xor(right)
            BitwiseAnd => left.bitwise_and(right)
            In => Boolean(left.op_in(right))
            Divide => left / right
            Multiply => left * right
            Percent => left % right
            Slash => left / right
            Star => left * right
            UnsignedRightShift => left.unsigned_right_shift(right)
            RightShift => left.right_shift(right)
            LeftShift => left.left_shift(right)
            Instanceof => Boolean(left.instanceof(right))
          }
        }
        LogicalExpression({ operator, left, right }) => {
          let left_val = self.evaluate(Expression(left))
          match operator {
            LogicalOr =>
              if left_val.is_truthy() {
                left_val
              } else {
                self.evaluate(Expression(right))
              }
            LogicalAnd =>
              if left_val.is_truthy() {
                self.evaluate(Expression(right))
              } else {
                left_val
              }
          }
        }
        Identifier({ name, .. }) => {
          let start : Context? = Some(self)
          loop start {
            Some(ctx) =>
              match ctx.scope.get(name) {
                Some(v) => break v
                None => continue ctx.parent
              }
            None => break Undefined
          }
        }
        PrefixUnaryExpression({ operator, argument, .. }) => {
          let val = self.evaluate(Expression(argument))
          match operator {
            Not => Boolean(!val.is_truthy())
            Minus =>
              match val {
                Number(n) => Number(-n)
                String(s) =>
                  Number(
                    (-@strconv.parse_double(s)) catch {
                      _ => @double.not_a_number
                    },
                  )
                Boolean(b) => Number(-(if b { 1 } else { 0 }))
                Null => Number(-0.0)
                _ => Number(@double.not_a_number) // TODO: ToNumber
              }
            Plus =>
              match val {
                Number(n) => Number(n)
                String(s) =>
                  Number(
                    @strconv.parse_double(s) catch {
                      _ => @double.not_a_number
                    },
                  )
                Boolean(b) => Number(if b { 1 } else { 0 })
                Null => Number(0.0)
                _ => Number(@double.not_a_number) // TODO: ToNumber
              }
            Typeof => {
              let type_str = match val {
                Undefined => "undefined"
                Null => "object"
                Boolean(_) => "boolean"
                Number(_) => "number"
                String(_) => "string"
                Function(_) => "function"
                Object(_) => "object"
                BigInt(_) => "bigint"
                Symbol(_) => "symbol"
              }
              String(type_str)
            }
            Void => Undefined
            _ => Undefined
          }
        }
        ObjectExpression({ properties }) => {
          let obj_props = Map::new()
          for prop in properties {
            match prop {
              ObjectProperty({ key, value, computed, .. }) => {
                let key_str = if computed {
                  let k = self.evaluate(Expression(key))
                  match k {
                    String(s) => s.to_string()
                    _ => k.to_string()
                  }
                } else {
                  match key {
                    Identifier({ name, .. }) => name
                    StringLiteral({ value }) => value.to_string()
                    _ => "unknown"
                  }
                }
                let val = self.evaluate(Expression(value))
                obj_props.set(key_str, val)
              }
              _ => ()
            }
          }
          Object({ properties: obj_props, prototype: Some(Null) })
        }
        ArrayLiteralExpression({ elements }) => {
          let arr_props = Map::new()
          let mut len = 0
          for element in elements {
            match element {
              Expression(expr) => {
                let val = self.evaluate(Expression(expr))
                arr_props.set(len.to_string(), val)
                len += 1
              }
              _ => ()
            }
          }
          arr_props.set("length", Number(len.to_double()))
          Object({ properties: arr_props, prototype: Some(Null) })
        }
        ArrowFunctionExpression({ params, body, .. }) => {
          let param_names = []
          for param in params {
            match param {
              Identifier({ name, .. }) => param_names.push(name)
              _ => ()
            }
          }
          let block_body = match body {
            BlockStatement(block) => block
            Expression(expr) =>
              @parser.BlockStatement::{
                body: [
                  @parser.Statement::ReturnStatement(@parser.ReturnStatement::{
                    argument: Some(expr),
                  }),
                ],
                directives: [],
              }
          }
          let func = JSFunction::{
            name: None,
            params: param_names,
            body: block_body,
            context: self,
          }
          Function(func)
        }
        _ => Undefined
      }
    Pattern(_) => Undefined
  }
}

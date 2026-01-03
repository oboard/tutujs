///|
pub fn Context::eval(self : Context, code : &Show) -> JSValue {
  let lex = code.to_string() |> @lexer.parse
  println(lex)
  let ast = lex |> @parser.parse
  println(ast)
  let mut res = JSValue::Undefined
  for node in ast.body {
    res = self.evaluate(Statement(node))
  }
  res
}

///|
fn Context::evaluate(self : Context, node : @parser.NodeType) -> JSValue {
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
        ReturnStatement({ argument }) =>
          match argument {
            Some(arg) => self.evaluate(Expression(arg))
            None => Undefined
          }
        BlockStatement({ body, .. }) => {
          let mut res = JSValue::Undefined
          for stmt in body {
            res = self.evaluate(Statement(stmt))
          }
          res
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
              let mut returned = false
              for stmt in func.body.body {
                match stmt {
                  ReturnStatement({ argument }) => {
                    res = match argument {
                      Some(arg) => new_ctx.evaluate(Expression(arg))
                      None => Undefined
                    }
                    returned = true
                    break
                  }
                  // Handle block statements that might contain returns
                  BlockStatement({ body, .. }) => {
                    let mut block_returned = false
                    let mut block_res = JSValue::Undefined
                    for s in body {
                      match s {
                        ReturnStatement({ argument }) => {
                          block_res = match argument {
                            Some(arg) => new_ctx.evaluate(Expression(arg))
                            None => Undefined
                          }
                          block_returned = true
                          break
                        }
                        _ => new_ctx.evaluate(Statement(s)) |> ignore
                      }
                    }
                    if block_returned {
                      res = block_res
                      returned = true
                      break
                    }
                  }
                  _ => new_ctx.evaluate(Statement(stmt)) |> ignore
                }
              }
              if returned {
                res
              } else {
                Undefined
              }
            }
            _ => Undefined
          }
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
        StringLiteral({ value }) => String(value)
        NumericLiteral({ value }) => Number(value)
        BooleanLiteral({ value }) => Boolean(value)
        NullLiteral => Null
        RegExpLiteral(_) =>
          Object({ properties: Map::new(), prototype: Some(Null) })
        _ => Undefined
      }
    _ => Undefined
  }
}

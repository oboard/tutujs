///|
pub(all) struct Context {
  scope : Map[String, JSValue]
  parent : Context?
} derive(Eq, ToJson, FromJson, Show)

///|
pub fn Context::new(parent? : Context) -> Context {
  { scope: Map::new(), parent }
}

///|
pub impl Compare for Context with compare(_, _) -> Int {
  0
}

///|
pub impl Hash for Context with hash_combine(self, hasher) -> Unit {
  hasher.combine(self.scope.length())
}

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
            name: id.name,
            params: param_names,
            body,
            context: self,
          }
          self.scope.set(id.name, Function(func))
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
        _ => Undefined
      }
    Expression(expression) =>
      match expression {
        CallExpression({ callee, arguments, .. }) => {
          let callee_val = self.evaluate(Expression(callee))
          match callee_val {
            Function(func) => {
              let new_ctx = Context::new(parent=func.context)
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
            _ => Undefined
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

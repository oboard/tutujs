///|
using @value {type JSValue}

///|
pub struct Context {
  scope : Map[String, JSValue]
  parent : Context?
}

///|
pub fn Context::new(parent? : Context) -> Context {
  { scope: Map::new(), parent }
}

///|
pub fn Context::eval(self : Context, code : &Show) -> JSValue {
  let ast = code.to_string() |> @lexer.parse |> @parser.parse
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
    Statement(statement) =>
      match statement {
        ExpressionStatement({ expression, .. }) =>
          self.evaluate(Expression(expression))
        _ => Undefined
      }
    Expression(expression) =>
      match expression {
        BinaryExpression({ operator, left, right }) => {
          let left = self.evaluate(Expression(left))
          let right = self.evaluate(Expression(right))
          match operator {
            In => Undefined
            BitwiseAnd => Undefined
            BitwiseXor => Undefined
            BitwiseOr => Undefined
            Modulo => Undefined
            Divide => Undefined
            Multiply => Undefined
            Minus => left - right
            Percent => Undefined
            Slash => Undefined
            Star => Undefined
            Plus => left + right
            UnsignedRightShift => Undefined
            RightShift => Undefined
            LeftShift => Undefined
            GreaterThanOrEqual => Undefined
            GreaterThan => Undefined
            LessThanOrEqual => Undefined
            LessThan => Undefined
            StrictNotEqual => Boolean(left != right)
            StrictEqual => Boolean(left == right)
            NotEqual => Boolean(!left.unstrict_equal(right))
            Equal => Boolean(left.unstrict_equal(right))
            Instanceof => Undefined
          }
        }
        NumericLiteral({ value }) => Number(value)
        StringLiteral({ value }) => String(value)
        Identifier({ name, .. }) =>
          match self.scope.get(name) {
            Some(value) => value
            None => Undefined
          }
        _ => Undefined
      }
    _ => Undefined
  }
}

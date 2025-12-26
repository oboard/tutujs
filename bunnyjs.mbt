///|
using @value {type JSValue}

///|
pub struct Context {
  global_scope : Map[String, @value.JSValue]
}

///|
pub fn Context::new() -> Context {
  { global_scope: Map::new() }
}

///|
pub fn Context::eval(self : Context, code : String) -> @value.JSValue {
  let ast = @parser.parse(code)
  println(ast)
  self.evaluate(ast)
}

///|
fn Context::evaluate(self : Context, node : @parser.ASTNode) -> @value.JSValue {
  match node.node_type {
    Program => {
      let mut result = JSValue::Undefined
      for stmt in node.body {
        result = self.evaluate(stmt)
      }
      result
    }
    ExpressionStatement =>
      match node.argument {
        Some(expr) => self.evaluate(expr)
        None => Undefined
      }
    Literal =>
      // 简单的字面量处理
      match node.value {
        Some(val) =>
          if node.raw is Some(['\"' | '\'' | '`', .., '\"' | '\'' | '`']) {
            String(val)
          } else {
            // 假设是数字，这里应该更严谨
            try {
              let num = @strconv.parse_double(val)
              Number(num)
            } catch {
              _ => String(val) // fallback
            }
          }
        None => Undefined
      }
    Identifier =>
      match node.name {
        Some(name) =>
          match self.global_scope.get(name) {
            Some(val) => val
            None => Undefined // 或者抛错
          }
        None => Undefined
      }
    VariableDeclaration => {
      for decl in node.declarations {
        match decl.id {
          Some(id_node) =>
            match id_node.name {
              Some(name) => {
                let init_val = match decl.init {
                  Some(init_expr) => self.evaluate(init_expr)
                  None => Undefined
                }
                self.global_scope.set(name, init_val)
              }
              None => ()
            }
          None => ()
        }
      }
      Undefined
    }
    CallExpression => {
      // 特殊处理 console.log
      // 实际上应该先计算 callee，如果是 console.log 再处理
      // 这里简化处理
      let mut is_console_log = false
      match node.callee {
        Some(callee) =>
          if callee.node_type is MemberExpression {
            // 检查 object 和 property
            match (callee.left, callee.right) {
              (Some(obj), Some(prop)) =>
                match (obj.name, prop.name) {
                  (Some("console"), Some("log")) => is_console_log = true
                  _ => ()
                }
              _ => ()
            }
          }
        None => ()
      }
      if is_console_log {
        for arg in node.params {
          let val = self.evaluate(arg)
          println(val)
        }
        Undefined
      } else {
        // TODO: 实现通用函数调用
        Undefined
      }
    }
    _ => Undefined
  }
}

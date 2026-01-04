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
pub fn Context::invoke(
  self : Context,
  func : JSFunction,
  this_val : JSValue,
  args : Array[JSValue],
) -> JSValue raise EvalError {
  match func.body {
    User(block) => {
      let new_ctx = new(parent=func.context)
      new_ctx.scope.set("this", this_val)
      for i, val in args {
        if i < func.params.length() {
          new_ctx.scope.set(func.params[i], val)
        }
      }
      let mut res = JSValue::Undefined
      try {
        for stmt in block.body {
          res = new_ctx.evaluate(Statement(stmt))
        }
        res
      } catch {
        EvalError::Return(v) => v
        EvalError::Break(l) => raise EvalError::Break(l)
        EvalError::Continue(l) => raise EvalError::Continue(l)
      }
    }
    Native(f) => f(self, this_val, args)
  }
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
          let func_proto = match self.resolve("Function") {
            Function(f) => f.properties.get("prototype")
            _ => None
          }
          let func_props = @hashmap.new()
          let func = match func_proto {
            Some(proto) =>
              JSFunction::new(
                name=id.name,
                params=param_names,
                body=User(body),
                context=self,
                properties=func_props,
                prototype=proto,
              )
            None =>
              JSFunction::new(
                name=id.name,
                params=param_names,
                body=User(body),
                context=self,
                properties=func_props,
              )
          }
          let func_val = JSValue::Function(func)

          // Setup prototype property
          let obj_proto = match self.resolve("Object") {
            Function(f) => f.properties.get("prototype")
            _ => None
          }
          let proto_props = @hashmap.new()
          let proto_obj = JSObject::{
            properties: proto_props,
            prototype: obj_proto,
          }
          let proto_val = JSValue::Object(proto_obj)
          proto_props.set("constructor", func_val)
          func_props.set("prototype", proto_val)
          self.scope.set(id.name, func_val)
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
            Some(init_node) =>
              match init_node {
                VariableDeclaration(decl) =>
                  self.evaluate(Declaration(VariableDeclaration(decl)))
                  |> ignore
                Expression(expr) => self.evaluate(Expression(expr)) |> ignore
              }
            None => ()
          }
          while true {
            // Test
            match test_ {
              Some(expr) => {
                let test_val = self.evaluate(Expression(expr))
                // println("Test: " + test_val.to_string())
                if not(test_val.is_truthy()) {
                  break
                }
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
              Some(expr) =>
                // println("Update before: " + expr.to_string())
                self.evaluate(Expression(expr)) |> ignore
              // println("Update after")
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
        NewExpression({ callee, arguments, .. }) => {
          let ctor_val = self.evaluate(Expression(callee))
          let args_values = []
          for arg in arguments {
            args_values.push(self.evaluate(Expression(arg)))
          }
          match ctor_val {
            Function(func) => {
              let proto = match func.properties.get("prototype") {
                Some(p) => Some(p)
                None => Some(Null)
              }
              let new_obj = JSValue::Object({
                properties: @hashmap.new(),
                prototype: proto,
              })
              let res = match func.body {
                User(block) => {
                  let new_ctx = new(parent=func.context)
                  new_ctx.scope.set("this", new_obj)
                  for i, val in args_values {
                    if i < func.params.length() {
                      new_ctx.scope.set(func.params[i], val)
                    }
                  }
                  let mut ret_val = JSValue::Undefined
                  try {
                    for stmt in block.body {
                      ret_val = new_ctx.evaluate(Statement(stmt))
                    }
                  } catch {
                    EvalError::Return(v) => ret_val = v
                    EvalError::Break(l) => raise EvalError::Break(l)
                    EvalError::Continue(l) => raise EvalError::Continue(l)
                  }
                  ret_val
                }
                Native(f) => f(self, new_obj, args_values)
              }
              match res {
                Object(_) | Function(_) => res
                _ => new_obj
              }
            }
            _ => Undefined
          }
        }
        CallExpression({ callee, arguments, .. }) => {
          let (callee_val, this_val) = match callee {
            MemberExpression({ object, property, computed, .. }) => {
              let obj_val = self.evaluate(Expression(object))
              let prop_name = if computed {
                self.evaluate(Expression(property)).to_string()
              } else {
                match property {
                  Identifier({ name, .. }) => name
                  _ => "unknown"
                }
              }
              (self.get_property(obj_val, prop_name), obj_val)
            }
            _ => (self.evaluate(Expression(callee)), JSValue::Undefined)
          }
          match callee_val {
            Function(func) => {
              let args_values = []
              for arg in arguments {
                args_values.push(self.evaluate(Expression(arg)))
              }
              self.invoke(func, this_val, args_values)
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
            StrictNotEqual => Boolean(!left.strict_equal(right))
            StrictEqual => Boolean(left.strict_equal(right))
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
        MemberExpression({ object, property, computed, .. }) => {
          let obj_val = self.evaluate(Expression(object))
          let prop_name = if computed {
            self.evaluate(Expression(property)).to_string()
          } else {
            match property {
              Identifier({ name, .. }) => name
              _ => "unknown"
            }
          }
          self.get_property(obj_val, prop_name)
        }
        Identifier({ name, .. }) => self.resolve(name)
        ThisExpression => self.resolve("this")
        NumericLiteral({ value }) => Number(value)
        StringLiteral({ value }) => String(value)
        BooleanLiteral({ value }) => Boolean(value)
        NullLiteral => Null
        PrefixUnaryExpression({ operator, argument, .. }) =>
          match operator {
            Delete =>
              match argument {
                MemberExpression({ object, property, computed, .. }) => {
                  let obj_val = self.evaluate(Expression(object))
                  let prop_name = if computed {
                    self.evaluate(Expression(property)).to_string()
                  } else {
                    match property {
                      Identifier({ name, .. }) => name
                      _ => "unknown"
                    }
                  }
                  match obj_val {
                    Object(obj) => {
                      obj.properties.remove(prop_name)
                      Boolean(true)
                    }
                    Function(func) => {
                      func.properties.remove(prop_name)
                      Boolean(true)
                    }
                    _ => Boolean(true)
                  }
                }
                Identifier({ name, .. }) => {
                  self.scope.remove(name)
                  Boolean(true)
                }
                _ => {
                  self.evaluate(Expression(argument)) |> ignore
                  Boolean(true)
                }
              }
            _ => {
              let val = self.evaluate(Expression(argument))
              match operator {
                Not => Boolean(!val.is_truthy())
                Minus => Number(-val.to_number())
                Plus => Number(val.to_number())
                BitwiseNot => val.bitwise_not()
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
          }
        ObjectExpression({ properties }) => {
          let obj_props = @hashmap.new()
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
          let arr_props = @hashmap.new()
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
          let proto = match self.resolve("Array") {
            Function(f) =>
              match f.properties.get("prototype") {
                Some(p) => Some(p)
                None => Some(Null)
              }
            _ => Some(Null)
          }
          Object({ properties: arr_props, prototype: proto })
        }
        FunctionExpression({ id, params, body, .. }) => {
          let param_names = []
          for param in params {
            match param {
              Identifier({ name, .. }) => param_names.push(name)
              _ => ()
            }
          }
          let name = match id {
            Some(ident) => Some(ident.name)
            None => None
          }
          let func_proto = match self.resolve("Function") {
            Function(f) => f.properties.get("prototype")
            _ => None
          }
          let func_props = @hashmap.new()
          let func = JSFunction::{
            name,
            params: param_names,
            body: User(body),
            context: self,
            properties: func_props,
            prototype: func_proto,
          }
          let func_val = JSValue::Function(func)
          let obj_proto = match self.resolve("Object") {
            Function(f) => f.properties.get("prototype")
            _ => None
          }
          let proto_props = @hashmap.new()
          let proto_obj = JSObject::{
            properties: proto_props,
            prototype: obj_proto,
          }
          let proto_val = JSValue::Object(proto_obj)
          proto_props.set("constructor", func_val)
          func_props.set("prototype", proto_val)
          func_val
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
          let func_proto = match self.resolve("Function") {
            Function(f) => f.properties.get("prototype")
            _ => None
          }
          let func = JSFunction::{
            name: None,
            params: param_names,
            body: User(block_body),
            context: self,
            properties: @hashmap.new(),
            prototype: func_proto,
          }
          Function(func)
        }
        AssignmentExpression({ operator, left, right }) => {
          let val = self.evaluate(Expression(right))
          match left {
            MemberExpression({ object, property, computed, .. }) => {
              let obj_val = self.evaluate(Expression(object))
              let prop_name = if computed {
                self.evaluate(Expression(property)).to_string()
              } else {
                match property {
                  Identifier({ name, .. }) => name
                  _ => "unknown"
                }
              }
              match operator {
                Assign => {
                  obj_val.set_property(prop_name, val)
                  val
                }
                _ => Undefined
              }
            }
            Identifier({ name, .. }) =>
              match operator {
                Assign => {
                  let curr : Context? = Some(self)
                  let mut found = false
                  loop curr {
                    Some(ctx) =>
                      match ctx.scope.get(name) {
                        Some(_) => {
                          ctx.scope.set(name, val)
                          found = true
                          break
                        }
                        None => continue ctx.parent
                      }
                    None => break
                  }
                  if not(found) {
                    let mut root = self
                    loop root.parent {
                      Some(p) => {
                        root = p
                        continue p.parent
                      }
                      None => break
                    }
                    root.scope.set(name, val)
                  }
                  val
                }
                _ => Undefined
              }
            _ => Undefined
          }
        }
        UpdateExpression({ operator, prefix, argument }) =>
          match argument {
            Identifier({ name, .. }) => {
              let curr : Context? = Some(self)
              let mut target_ctx : Context? = None
              let mut current_val = JSValue::Undefined
              loop curr {
                Some(ctx) =>
                  match ctx.scope.get(name) {
                    Some(v) => {
                      target_ctx = Some(ctx)
                      current_val = v
                      break
                    }
                    None => continue ctx.parent
                  }
                None => break
              }
              let num_val = match current_val {
                Number(n) => n
                _ => 0.0
              }
              let new_val = match operator {
                Increment => num_val + 1.0
                Decrement => num_val - 1.0
              }
              match target_ctx {
                Some(ctx) => ctx.scope.set(name, Number(new_val))
                None => {
                  let mut root = self
                  loop root.parent {
                    Some(p) => {
                      root = p
                      continue p.parent
                    }
                    None => break
                  }
                  root.scope.set(name, Number(new_val))
                }
              }
              if prefix {
                Number(new_val)
              } else {
                Number(num_val)
              }
            }
            _ => Undefined
          }
        _ => Undefined
      }
    Pattern(_) => Undefined
  }
}

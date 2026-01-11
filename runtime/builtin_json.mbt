//|

///|
pub fn create_json_object(object_proto : JSValue) -> JSValue {
  let json_obj = JSObject::{
    properties: @hashmap.new(),
    prototype: Some(object_proto),
  }

  // JSON.parse
  let parse_fn = Native(fn(ctx, _this_val, args) {
    if args is [arg0, ..] {
      let text = arg0.to_string()
      let lexer = @lexer.Lexer::new(text)
      let tokens = lexer.tokenize()
      let parser = @parser.Parser::new(tokens)
      // JSON can be object, array, string, number, boolean, null
      // These are all parsed by parse_expression (which includes primary)
      // But we need to handle EOF check?
      let expr = parser.parse_expression()

      // Evaluate the expression in a clean context?
      // Actually we can just evaluate it in current context because JSON shouldn't contain variables
      // But to be safe against side effects (if parser allowed them), we just rely on eval.
      // Since our parser parses JS, it might parse function calls etc if we are not careful.
      // But for now, we assume valid JSON input which parses to literals.
      ctx.evaluate(Expression(expr)) catch {
        _ => JSValue::Undefined // SyntaxError ideally
      }
    } else {
      JSValue::Undefined // SyntaxError
    }
  })
  let parse_obj = JSFunction::new(name="parse", body=parse_fn)
  json_obj["parse"] = JSValue::Function(parse_obj)

  // JSON.stringify
  let stringify_fn = Native(fn(_ctx, _this_val, args) {
    if args is [value, ..] {
      // TODO: Handle replacer and space
      stringify(value)
    } else {
      JSValue::Undefined
    }
  })
  let stringify_obj = JSFunction::new(name="stringify", body=stringify_fn)
  json_obj["stringify"] = JSValue::Function(stringify_obj)
  JSValue::Object(json_obj)
}

///|
fn stringify(value : JSValue) -> JSValue {
  match value {
    String(s) => JSValue::String("\"" + escape_string(s.to_string()) + "\"")
    Number(n) =>
      if n.is_nan() || n.is_inf() {
        JSValue::String("null")
      } else {
        JSValue::String(n.to_string())
      }
    Boolean(b) => JSValue::String(b.to_string())
    Null => JSValue::String("null")
    Undefined => JSValue::Undefined // Should return Undefined for direct call, but omitted in object
    Object(o) => {
      // Check for toJSON?

      // Is it Array?
      let is_array = match o.properties.get("length") {
        Some(Number(_)) => true // Simple heuristic
        _ => false
      }
      if is_array {
        let mut res = "["
        let len = match o.properties.get("length") {
          Some(Number(n)) => n.to_int()
          _ => 0
        }
        for i = 0; i < len; i = i + 1 {
          if i > 0 {
            res = res + ","
          }
          let val = match o.properties.get(i.to_string()) {
            Some(v) => v
            None => Undefined
          }
          match stringify(val) {
            String(s) => res = res + s.to_string()
            Undefined => res = res + "null" // Array elements become null if undefined
            _ => res = res + "null"
          }
        }
        res = res + "]"
        JSValue::String(res)
      } else {
        let mut res = "{"
        let mut first = true
        for k, v in o.properties {
          match stringify(v) {
            String(s) => {
              if not(first) {
                res = res + ","
              }
              res = res + "\"" + escape_string(k) + "\":" + s.to_string()
              first = false
            }
            _ => () // Skip undefined values
          }
        }
        res = res + "}"
        JSValue::String(res)
      }
    }
    Function(_) => JSValue::Undefined // Functions are ignored
    Symbol(_) => JSValue::Undefined
    BigInt(_) => JSValue::Undefined // TypeError in spec, but undefined here for safety
    Internal(_) => JSValue::String("{}")
  }
}

///|
fn escape_string(s : String) -> String {
  // TODO: Implement proper escaping
  s
}

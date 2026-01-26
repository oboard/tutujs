///|
pub type JSValue = Value

///|
pub type Context = Vm

///|
pub impl Add for JSValue with add(self, other) -> JSValue {
  eval_add(self, other) catch {
    _ => value_undefined()
  }
}

///|
pub impl Sub for JSValue with sub(self, other) -> JSValue {
  eval_binary(@engine.BinaryOp::Sub, self, other) catch {
    _ => value_undefined()
  }
}

///|
pub impl Mul for JSValue with mul(self, other) -> JSValue {
  eval_binary(@engine.BinaryOp::Mul, self, other) catch {
    _ => value_undefined()
  }
}

///|
pub impl Div for JSValue with div(self, other) -> JSValue {
  eval_binary(@engine.BinaryOp::Div, self, other) catch {
    _ => value_undefined()
  }
}

///|
pub impl Mod for JSValue with mod(self, other) -> JSValue {
  eval_binary(@engine.BinaryOp::Mod, self, other) catch {
    _ => value_undefined()
  }
}

///|
pub impl Show for JSValue with output(self, logger) -> Unit {
  match self {
    Number(n) => n.output(logger)
    String(s) => logger.write_string(s)
    Bool(b) => b.output(logger)
    _ => ()
  }
}

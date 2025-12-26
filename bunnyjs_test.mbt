///|
test "interpreter_console_log" {
  let ctx = Context::new()
  let code = "let x = 42; console.log(x);"
  let _ = ctx.eval(code)
  // 目前我们只能验证它不 panic，以及通过 side effect (println) 输出。
  // 在真实的单元测试中，我们可能需要 mock console.log 或者捕获输出，
  // 但 MoonBit 的测试框架可能还没有标准的方法来捕获 stdout。
}

///|
test "interpreter_literal" {
  let ctx = Context::new()
  let result = ctx.eval("123")
  assert_eq(result, Number(123.0))
}

///|
test "interpreter_string" {
  let ctx = Context::new()
  let result = ctx.eval("'hello'")
  assert_eq(result, String("hello"))
}

///|
test "interpreter_variable" {
  let ctx = Context::new()
  let _ = ctx.eval("let a = 10;")
  let result = ctx.eval("a")
  assert_eq(result, Number(10.0))
}

///|
test "function_call" {
  let ctx = Context::new()
  let _ = ctx.eval("function add(x, y) { return x + y }")
  let result = ctx.eval("add(3, 4)")
  assert_eq(result, Number(7.0))
}

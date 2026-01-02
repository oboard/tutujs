///|
test "function declaration and call" {
  let ctx = @bunnyjs.Context::new()
  ctx.eval("function f(x) { return x + 1; }") |> ignore
  @json.inspect(ctx.eval("f(1)"), content=["Number", 2])
}

///|
test "function closure" {
  let ctx = @bunnyjs.Context::new()
  // Note: FunctionExpression is not fully implemented in Declaration match, but FunctionDeclaration body uses BlockStatement.
  // If I use function expression in return: `return function(y) ...`
  // `Expression` match needs to handle `FunctionExpression`.
  // `value/eval.mbt` has `Expression` match.
  // I did NOT implement `FunctionExpression` in `value/eval.mbt`.
  // I only implemented `CallExpression`, `BinaryExpression`, `LogicalExpression`, `Identifier`, `Literals`.
  // `FunctionExpression` is missing.
  // So closures via return function expression won't work yet.
  // But nested function declaration works?

  // function makeAdder(x) { function add(y) { return x + y; } return add; }
  // This requires `return add` (Identifier). Identifier works.
  // And `add` must be defined in `makeAdder` scope.
  // `FunctionDeclaration` adds to current scope.

  ctx.eval(
    "function makeAdder(x) { function add(y) { return x + y; } return add; }",
  )
  |> ignore
  @json.inspect(ctx.eval("makeAdder(5)(2)"), content=["Number", 7])
}

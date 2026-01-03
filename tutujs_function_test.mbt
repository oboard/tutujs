///|
test "function declaration and call" {
  let ctx = @tutujs.Context::new()
  ctx.eval("function f(x) { return x + 1; }") |> ignore
  @json.inspect(ctx.eval("f(1)"), content=["Number", 2])
}

///|
test "function closure" {
  let ctx = @tutujs.Context::new()
  ctx.eval(
    "function makeAdder(x) { function add(y) { return x + y; } return add; }",
  )
  |> ignore
  @json.inspect(ctx.eval("makeAdder(5)(2)"), content=["Number", 7])
}

///|
test "arrow function" {
  let ctx = @tutujs.Context::new()
  ctx.eval("const f = (x) => x + 1;") |> ignore
  @json.inspect(ctx.eval("f(1)"), content=["Number", 2])
}

///|
test "arrow function closure" {
  let ctx = @tutujs.Context::new()
  ctx.eval(
    "const makeAdder = (x) => { const add = (y) => x + y; return add; };",
  )
  |> ignore
  @json.inspect(ctx.eval("makeAdder(5)(2)"), content=["Number", 7])
}

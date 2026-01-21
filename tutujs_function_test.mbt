///|
test "function declaration and call" {
  let ctx = @tutujs.Context::new()
  ctx.eval("function f(x) { return x + 1; }") |> ignore
  json_inspect(ctx.eval("f(1)"), content=["Number", 2])
}

///|
test "function closure" {
  let ctx = @tutujs.Context::new()
  ctx.eval(
    "function makeAdder(x) { function add(y) { return x + y; } return add; }",
  )
  |> ignore
  json_inspect(ctx.eval("makeAdder(5)(2)"), content=["Number", 7])
}

///|
test "arrow function" {
  let ctx = @tutujs.Context::new()
  ctx.eval("const f = (x) => x + 1;") |> ignore
  json_inspect(ctx.eval("f(1)"), content=["Number", 2])
}

///|
test "arrow function closure" {
  let ctx = @tutujs.Context::new()
  ctx.eval(
    "const makeAdder = (x) => { const add = (y) => x + y; return add; };",
  )
  |> ignore
  json_inspect(ctx.eval("makeAdder(5)(2)"), content=["Number", 7])
}

///|
test "new Function constructor" {
  let ctx = @tutujs.Context::new()
  json_inspect(ctx.eval("(new Function('return 1'))()"), content=["Number", 1])
  json_inspect(ctx.eval("(new Function('a', 'b', 'return a + b'))(1, 2)"), content=[
    "Number", 3,
  ])
}

///|
test "function prototype chain" {
  let ctx = @tutujs.Context::new()

  // Identity checks
  json_inspect(ctx.eval("Function === Function"), content=["Bool", true])
  json_inspect(ctx.eval("Object === Object"), content=["Bool", true])
  json_inspect(ctx.eval("Function.prototype === Function.prototype"), content=[
    "Bool", true,
  ])

  // Constructor check
  json_inspect(ctx.eval("Function.prototype.constructor === Function"), content=[
    "Bool", true,
  ])
  json_inspect(ctx.eval("(new Function()).constructor === Function"), content=[
    "Bool", true,
  ])

  // Instanceof check
  json_inspect(ctx.eval("(new Function()) instanceof Function"), content=[
    "Bool", true,
  ])
  ctx.eval("function f() {}") |> ignore
  json_inspect(ctx.eval("f instanceof Function"), content=["Bool", true])
  json_inspect(ctx.eval("f.prototype.constructor === f"), content=["Bool", true])
}

///|
test "function call" {
  let ctx = @tutujs.Context::new()
  ctx.eval("function add(a, b) { return a + b; }") |> ignore
  json_inspect(ctx.eval("add.call(null, 1, 2)"), content=["Number", 3])
  ctx.eval("function getThis() { return this; }") |> ignore
  // In our simple runtime, global 'this' might be undefined or global object.
  // But call with explicit this should work.
  ctx.eval("var obj = { val: 42 };") |> ignore
  json_inspect(ctx.eval("getThis.call(obj).val"), content=["Number", 42])
}

///|
test "function apply" {
  let ctx = @tutujs.Context::new()
  ctx.eval("function add(a, b) { return a + b; }") |> ignore
  json_inspect(ctx.eval("add.apply(null, [1, 2])"), content=["Number", 3])
  ctx.eval("var obj = { val: 100 };") |> ignore
  ctx.eval("function getVal() { return this.val; }") |> ignore
  json_inspect(ctx.eval("getVal.apply(obj)"), content=["Number", 100])
}

///|
test "Math object" {
  let ctx = @tutujs.Context::new()

  // Math constants
  inspect(ctx.eval("Math.PI"), content="3.141592653589793")
  inspect(ctx.eval("Math.E"), content="2.718281828459045")

  // Math methods
  inspect(ctx.eval("Math.abs(-5)"), content="5")
  inspect(ctx.eval("Math.abs(5)"), content="5")
  inspect(ctx.eval("Math.floor(3.7)"), content="3")
  inspect(ctx.eval("Math.ceil(3.2)"), content="4")
  inspect(ctx.eval("Math.max(1, 2, 3)"), content="3")
  inspect(ctx.eval("Math.min(1, 2, 3)"), content="1")
}

///|
test "Number constructor" {
  let ctx = @tutujs.Context::new()

  // Number() call
  inspect(ctx.eval("Number(123)"), content="123")
  inspect(ctx.eval("typeof Number(123)"), content="number")

  // new Number()
  inspect(ctx.eval("new Number(123).valueOf()"), content="123")
  inspect(ctx.eval("typeof new Number(123)"), content="object")

  // Properties
  inspect(ctx.eval("Number.MAX_VALUE > 0"), content="true")
  inspect(ctx.eval("Number.NaN"), content="NaN")
}

///|
test "String constructor fixes" {
  let ctx = @tutujs.Context::new()

  // String() call
  inspect(ctx.eval("String('abc')"), content="abc")
  inspect(ctx.eval("typeof String('abc')"), content="string")

  // new String()
  inspect(ctx.eval("new String('abc').valueOf()"), content="abc")
  inspect(ctx.eval("typeof new String('abc')"), content="object")
  inspect(ctx.eval("new String('abc').length"), content="3")
}

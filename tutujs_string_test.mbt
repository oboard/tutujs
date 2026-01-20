///|
test "string constructor and literal" {
  let ctx = @tutujs.Context::new()
  @json.inspect(ctx.eval("'hello'"), content=["String", "hello"])
  @json.inspect(ctx.eval("new String('hello').valueOf()"), content=[
    "String", "hello",
  ])
  @json.inspect(ctx.eval("typeof new String('hello')"), content=[
    "String", "object",
  ])
  @json.inspect(ctx.eval("typeof 'hello'"), content=["String", "string"])
}

///|
test "string properties" {
  let ctx = @tutujs.Context::new()
  @json.inspect(ctx.eval("'hello'.length"), content=["Number", 5])
  @json.inspect(ctx.eval("new String('hello').length"), content=["Number", 5])
}

///|
test "string methods" {
  let ctx = @tutujs.Context::new()
  @json.inspect(ctx.eval("'hello'.charAt(1)"), content=["String", "e"])
  @json.inspect(ctx.eval("'hello'.toString()"), content=["String", "hello"])
}

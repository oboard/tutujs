///|
test "arithmetic" {
  let context = @bunnyjs.Context::new()
  @json.inspect(context.eval("1 == 1"), content=["Boolean", true])
  @json.inspect(context.eval("1 === 1"), content=["Boolean", true])
  @json.inspect(context.eval("1 + 1"), content=["Number", 2])
  @json.inspect(context.eval("1 - 1"), content=["Number", 0])
  @json.inspect(context.eval("\"Hello World\""), content=[
    "String", "Hello World",
  ])
  @json.inspect(context.eval("`Hello` + `World`"), content=[
    "String", "HelloWorld",
  ])
}

///|
test "logical OR" {
  let context = @bunnyjs.Context::new()
  @json.inspect(context.eval("true || false"), content=["Boolean", true])
  @json.inspect(context.eval("false || true"), content=["Boolean", true])
  @json.inspect(context.eval("false || false"), content=["Boolean", false])
  @json.inspect(context.eval("1 || 0"), content=["Number", 1])
  @json.inspect(context.eval("0 || 1"), content=["Number", 1])
  @json.inspect(context.eval("0 || null"), content="Null")
  // @json.inspect(context.eval("\"Hello\" || \"World\""), content=["String", "Hello"])
  // @json.inspect(context.eval("\"\" || \"World\""), content=["String", "World"])
  // @json.inspect(context.eval("null || undefined"), content=["Undefined", null])
}

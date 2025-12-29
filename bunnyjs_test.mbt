///|
test " arithmetic" {
  let context = @bunnyjs.Context::new()
  @json.inspect(context.eval("1 == 1"), content=["Boolean", true])
  @json.inspect(context.eval("1 === 1"), content=["Boolean", true])
  @json.inspect(context.eval("1 + 1"), content=["Number", 2])
  @json.inspect(context.eval("1 - 1"), content=["Number", 0])
}

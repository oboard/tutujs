///|
test "Date.parse" {
  let ctx = Context::create_global()
  let result = ctx.eval(parse("Date.parse('2023-01-01')"))
  inspect(result, content="1672531200000")
}

///|
test "Date.parse invalid" {
  let ctx = Context::create_global()
  let result = ctx.eval(parse("Date.parse('invalid')"))
  inspect(result, content="NaN")
}

///|
test "Date.parse empty" {
  let ctx = Context::create_global()
  let result = ctx.eval(parse("Date.parse('')"))
  inspect(result, content="NaN")
}

///|
test "Date.parse ISO" {
  let ctx = Context::create_global()
  let result = ctx.eval(parse("Date.parse('2023-01-01T12:00:00.000Z')"))
  inspect(result, content="1672574400000")
}

///|
test "Date.parse extreme past" {
  let ctx = Context::create_global()
  let result = ctx.eval(parse("Date.parse('0001-01-01T00:00:00.000Z')"))
  inspect(result, content="-62135596800000")
}

///|
test "Date.parse extreme future" {
  let ctx = Context::create_global()
  let result = ctx.eval(parse("Date.parse('9999-12-31T23:59:59.999Z')"))
  inspect(result, content="253402300799999")
}

///|
test "Date.parse very large year" {
  let ctx = Context::create_global()
  let result = ctx.eval(parse("Date.parse('+275760-09-13T00:00:00.000Z')"))
  @json.inspect(result, content=["Number", 8640000000000000])
}

///|
test "Date.parse very small year" {
  let ctx = Context::create_global()
  let result = ctx.eval(parse("Date.parse('-271821-04-20T00:00:00.000Z')"))
  @json.inspect(result, content=["Number", -8640000000000000])
}

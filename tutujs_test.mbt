///|
test "arithmetic" {
  let context = @tutujs.Context::new()
  json_inspect(context.eval("1 == 1"), content=["Bool", true])
  json_inspect(context.eval("1 === 1"), content=["Bool", true])
  json_inspect(context.eval("1 + 1"), content=["Number", 2])
  json_inspect(context.eval("1 - 1"), content=["Number", 0])
  json_inspect(context.eval("\"Hello World\""), content=[
    "String", "Hello World",
  ])
  json_inspect(context.eval("`Hello` + `World`"), content=[
    "String", "HelloWorld",
  ])
}

///|
test "type coercion" {
  let context = @tutujs.Context::new()
  fn eval(s : String) {
    context.eval(s) catch {
      _ => @runtime.value_undefined()
    }
  }

  json_inspect(eval("true || false"), content=["Bool", true])
  json_inspect(eval("false || true"), content=["Bool", true])
  json_inspect(eval("false || false"), content=["Bool", false])
  json_inspect(eval("1 || 0"), content=["Number", 1])
  json_inspect(eval("0 || 1"), content=["Number", 1])
  json_inspect(eval("0 || null"), content="Null")
  json_inspect(eval("\"Hello\" || \"World\""), content=["String", "Hello"])
  json_inspect(eval("\"\" || \"World\""), content=["String", "World"])
  json_inspect(eval("null || undefined"), content="Undefined")
  json_inspect(eval("undefined || null"), content="Null")
  json_inspect(eval("true && false"), content=["Bool", false])
  json_inspect(eval("true && true"), content=["Bool", true])
  json_inspect(eval("1 && 0"), content=["Number", 0])
  json_inspect(eval("\"Hello\" && \"World\""), content=["String", "World"])
  json_inspect(eval("\"\" && \"World\""), content=["String", ""])
  json_inspect(eval("null && undefined"), content="Null")
  json_inspect(eval("undefined && null"), content="Undefined")
  json_inspect(eval("!true"), content=["Bool", false])
  json_inspect(eval("!false"), content=["Bool", true])
  json_inspect(eval("!0"), content=["Bool", true])
  json_inspect(eval("!1"), content=["Bool", false])
  json_inspect(eval("!\"Hello\""), content=["Bool", false])
  json_inspect(eval("!\"\""), content=["Bool", true])
  json_inspect(eval("!null"), content=["Bool", true])
  json_inspect(eval("!undefined"), content=["Bool", true])
  json_inspect(eval("NaN && 0"), content=["Number", @double.not_a_number])
  json_inspect(eval("0 && NaN"), content=["Number", 0])
  json_inspect(eval("NaN && 1"), content=["Number", @double.not_a_number])
  json_inspect(eval("1 && NaN"), content=["Number", @double.not_a_number])
  json_inspect(eval("NaN || 0"), content=["Number", 0])
  json_inspect(eval("0 || NaN"), content=["Number", @double.not_a_number])
  json_inspect(eval("NaN || 1"), content=["Number", 1])
  json_inspect(eval("1 || NaN"), content=["Number", 1])
  json_inspect(eval("+'1'"), content=["Number", 1])
  json_inspect(eval("-'1'"), content=["Number", -1])
  json_inspect(eval("-false"), content=["Number", -0])
  json_inspect(eval("-true"), content=["Number", -1])
  json_inspect(eval("null || 'test'"), content=["String", "test"])
  json_inspect(eval("undefined || 42"), content=["Number", 42])
  json_inspect(eval("'' || false"), content=["Bool", false])
  json_inspect(eval("null && 'test'"), content="Null")
  json_inspect(eval("undefined && 42"), content="Undefined")
  json_inspect(eval("'' && false"), content=["String", ""])
  json_inspect(eval("!NaN"), content=["Bool", true])
  json_inspect(eval("!'test'"), content=["Bool", false])
  json_inspect(eval("![1, 2, 3]"), content=["Bool", false])
  json_inspect(eval("!{key: 'value'}"), content=["Bool", false])
  json_inspect(eval("+'test'"), content=["Number", @double.not_a_number])
  json_inspect(eval("+'123.45'"), content=["Number", 123.45])
  json_inspect(eval("-'test'"), content=["Number", @double.not_a_number])
  json_inspect(eval("-'123.45'"), content=["Number", -123.45])
  json_inspect(eval("+'true'"), content=["Number", @double.not_a_number])
  json_inspect(eval("+'false'"), content=["Number", @double.not_a_number])
  json_inspect(eval("-null"), content=["Number", -0])
  json_inspect(eval("-undefined"), content=["Number", @double.not_a_number])
}

///|
test "oeprator" {
  let context = @tutujs.Context::new()
  inspect(context.eval("1 + 1") + context.eval("1 + 1"), content="4")
}

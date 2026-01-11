///|
test "bigint_array" {
  let code = "[100000000000000000000000000000000000000000000000000000000000000000000000000000000001n]"
  let tokens = @lexer.parse(code)
  let parser = Parser::new(tokens)
  let _ = parser.parse_program()

}

///|
test "Hello World" {
  @json.inspect(@lexer.parse("Hello World"), content=[
    { "kind": "Identifier", "value": "Hello", "line": 1, "column": 1 },
    { "kind": "Identifier", "value": "World", "line": 1, "column": 6 },
    { "kind": "EOF", "value": "EOF", "line": 1, "column": 11 },
  ])
  @json.inspect(@lexer.parse("\"Hello World\""), content=[
    { "kind": "StringLiteral", "value": "Hello World", "line": 1, "column": 1 },
    { "kind": "EOF", "value": "EOF", "line": 1, "column": 12 },
  ])
  @json.inspect(@lexer.parse("'Hello World'"), content=[
    { "kind": "StringLiteral", "value": "Hello World", "line": 1, "column": 1 },
    { "kind": "EOF", "value": "EOF", "line": 1, "column": 12 },
  ])
  @json.inspect(@lexer.parse("`Hello World`"), content=[
    { "kind": "StringLiteral", "value": "Hello World", "line": 1, "column": 1 },
    { "kind": "EOF", "value": "EOF", "line": 1, "column": 12 },
  ])
  @json.inspect(@lexer.parse("`Hello\n World`"), content=[
    {
      "kind": "StringLiteral",
      "value": "Hello\n World",
      "line": 1,
      "column": 1,
    },
    { "kind": "EOF", "value": "EOF", "line": 1, "column": 13 },
  ])
}

///|
test "math" {
  @json.inspect(@lexer.parse("1 + 2"), content=[
    { "kind": "NumericLiteral", "value": "1", "line": 1, "column": 1 },
    { "kind": "Plus", "value": "+", "line": 1, "column": 2 },
    { "kind": "NumericLiteral", "value": "2", "line": 1, "column": 3 },
    { "kind": "EOF", "value": "EOF", "line": 1, "column": 4 },
  ])
}

///|
test "bool" {
  @json.inspect(@lexer.parse("true"), content=[
    { "kind": "BooleanLiteral", "value": "true", "line": 1, "column": 1 },
    { "kind": "EOF", "value": "EOF", "line": 1, "column": 5 },
  ])
}

///|
test "function" {
  @json.inspect(@lexer.parse("function example() { return 1; }"), content=[
    { "kind": "Function", "value": "function", "line": 1, "column": 1 },
    { "kind": "Identifier", "value": "example", "line": 1, "column": 9 },
    { "kind": "LParen", "value": "(", "line": 1, "column": 16 },
    { "kind": "RParen", "value": ")", "line": 1, "column": 17 },
    { "kind": "LBrace", "value": "{", "line": 1, "column": 18 },
    { "kind": "Return", "value": "return", "line": 1, "column": 19 },
    { "kind": "NumericLiteral", "value": "1", "line": 1, "column": 25 },
    { "kind": "Semicolon", "value": ";", "line": 1, "column": 26 },
    { "kind": "RBrace", "value": "}", "line": 1, "column": 27 },
    { "kind": "EndOfFile", "value": "EOF", "line": 1, "column": 28 },
  ])
}

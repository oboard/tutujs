///|
test "Hello World" {
  json_inspect(@lexer.parse("Hello World"), content=[
    { "kind": "Identifier", "value": "Hello", "line": 1, "column": 1 },
    { "kind": "Identifier", "value": "World", "line": 1, "column": 7 },
    { "kind": "EOF", "value": "EOF", "line": 1, "column": 12 },
  ])
  json_inspect(@lexer.parse("\"Hello World\""), content=[
    { "kind": "StringLiteral", "value": "Hello World", "line": 1, "column": 1 },
    { "kind": "EOF", "value": "EOF", "line": 1, "column": 14 },
  ])
  json_inspect(@lexer.parse("'Hello World'"), content=[
    { "kind": "StringLiteral", "value": "Hello World", "line": 1, "column": 1 },
    { "kind": "EOF", "value": "EOF", "line": 1, "column": 14 },
  ])
  json_inspect(@lexer.parse("`Hello World`"), content=[
    { "kind": "StringLiteral", "value": "Hello World", "line": 1, "column": 1 },
    { "kind": "EOF", "value": "EOF", "line": 1, "column": 14 },
  ])
  json_inspect(@lexer.parse("`Hello\n World`"), content=[
    {
      "kind": "StringLiteral",
      "value": "Hello\n World",
      "line": 1,
      "column": 1,
    },
    { "kind": "EOF", "value": "EOF", "line": 1, "column": 15 },
  ])
}

///|
test "math" {
  json_inspect(@lexer.parse("1 + 2"), content=[
    { "kind": "NumericLiteral", "value": "1", "line": 1, "column": 1 },
    { "kind": "Plus", "value": "+", "line": 1, "column": 3 },
    { "kind": "NumericLiteral", "value": "2", "line": 1, "column": 5 },
    { "kind": "EOF", "value": "EOF", "line": 1, "column": 6 },
  ])
}

///|
test "bool" {
  json_inspect(@lexer.parse("true"), content=[
    { "kind": "BooleanLiteral", "value": "true", "line": 1, "column": 1 },
    { "kind": "EOF", "value": "EOF", "line": 1, "column": 5 },
  ])
}

///|
test "function" {
  json_inspect(@lexer.parse("function example() { return 1; }"), content=[
    { "kind": "Function", "value": "function", "line": 1, "column": 1 },
    { "kind": "Identifier", "value": "example", "line": 1, "column": 10 },
    { "kind": "LParen", "value": "(", "line": 1, "column": 17 },
    { "kind": "RParen", "value": ")", "line": 1, "column": 18 },
    { "kind": "LBrace", "value": "{", "line": 1, "column": 20 },
    { "kind": "Return", "value": "return", "line": 1, "column": 22 },
    { "kind": "NumericLiteral", "value": "1", "line": 1, "column": 29 },
    { "kind": "Semicolon", "value": ";", "line": 1, "column": 30 },
    { "kind": "RBrace", "value": "}", "line": 1, "column": 32 },
    { "kind": "EOF", "value": "EOF", "line": 1, "column": 33 },
  ])
}

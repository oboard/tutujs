///|
test "parse function declaration" {
  let code = "function foo() {}"
  json_inspect(code |> @lexer.parse |> @parser.parse, content={
    "sourceType": "Module",
    "body": [
      [
        "FunctionDeclaration",
        {
          "id": { "name": "foo", "optional": false },
          "params": [],
          "body": { "body": [], "directives": [] },
          "generator": false,
          "async_": false,
          "expression": false,
          "declare_": false,
        },
      ],
    ],
    "directives": [],
  })
}

///|
test "parse async function declaration" {
  let code = "async function foo() {}"
  json_inspect(code |> @lexer.parse |> @parser.parse, content={
    "sourceType": "Module",
    "body": [
      [
        "FunctionDeclaration",
        {
          "id": { "name": "foo", "optional": false },
          "params": [],
          "body": { "body": [], "directives": [] },
          "generator": false,
          "async_": true,
          "expression": false,
          "declare_": false,
        },
      ],
    ],
    "directives": [],
  })
}

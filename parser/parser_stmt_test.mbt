///|
test "parse while statement" {
  let code = "while (true) { break; }"
  let ast = code |> @lexer.parse |> @parser.parse
  // Just ensure it parses without error for now, or inspect structure
  inspect(ast.body.length(), content="1")
}

///|
test "parse do-while statement" {
  let code = "do { continue; } while (false);"
  let ast = code |> @lexer.parse |> @parser.parse
  inspect(ast.body.length(), content="1")
}

///|
test "parse for statement" {
  let code = "for (var i = 0; i < 10; i++) {}"
  let ast = code |> @lexer.parse |> @parser.parse
  inspect(ast.body.length(), content="1")
}

///|
test "parse problematic for loop" {
  let code = "for (let i = 1; i <= 3; i = i + 1) { sum = sum + i; }"
  let ast = code |> @lexer.parse |> @parser.parse
  json_inspect(ast, content={
    "sourceType": "Module",
    "body": [
      [
        "ForStatement",
        {
          "init": [
            "VariableDeclaration",
            {
              "declarations": [
                {
                  "id": ["Identifier", { "name": "i", "optional": false }],
                  "init": ["NumericLiteral", { "value": 1 }],
                  "definite": false,
                },
              ],
              "kind": "Let",
              "declare_": false,
            },
          ],
          "test_": [
            "BinaryExpression",
            {
              "operator": "LessThanOrEqual",
              "left": ["Identifier", { "name": "i", "optional": false }],
              "right": ["NumericLiteral", { "value": 3 }],
            },
          ],
          "update": [
            "AssignmentExpression",
            {
              "operator": "Assign",
              "left": ["Identifier", { "name": "i", "optional": false }],
              "right": [
                "BinaryExpression",
                {
                  "operator": "Plus",
                  "left": ["Identifier", { "name": "i", "optional": false }],
                  "right": ["NumericLiteral", { "value": 1 }],
                },
              ],
            },
          ],
          "body": [
            "BlockStatement",
            {
              "body": [
                [
                  "ExpressionStatement",
                  {
                    "expression": [
                      "AssignmentExpression",
                      {
                        "operator": "Assign",
                        "left": [
                          "Identifier",
                          { "name": "sum", "optional": false },
                        ],
                        "right": [
                          "BinaryExpression",
                          {
                            "operator": "Plus",
                            "left": [
                              "Identifier",
                              { "name": "sum", "optional": false },
                            ],
                            "right": [
                              "Identifier",
                              { "name": "i", "optional": false },
                            ],
                          },
                        ],
                      },
                    ],
                  },
                ],
              ],
              "directives": [],
            },
          ],
        },
      ],
    ],
    "directives": [],
  })
}

///|
test "parse for-in statement" {
  let code = "for (var i in obj) {}"
  let ast = code |> @lexer.parse |> @parser.parse
  inspect(ast.body.length(), content="1")
}

///|
test "parse for-of statement" {
  let code = "for (var i of arr) {}"
  let ast = code |> @lexer.parse |> @parser.parse
  inspect(ast.body.length(), content="1")
}

///|
test "parse switch statement" {
  let code = "switch (x) { case 1: break; default: }"
  let ast = code |> @lexer.parse |> @parser.parse
  inspect(ast.body.length(), content="1")
}

///|
test "parse if statement" {
  let code = "if (true) {} else {}"
  let ast = code |> @lexer.parse |> @parser.parse
  inspect(ast.body.length(), content="1")
}

///|
test "parse try statement" {
  let code = "try {} catch (e) {} finally {}"
  let ast = code |> @lexer.parse |> @parser.parse
  inspect(ast.body.length(), content="1")
}

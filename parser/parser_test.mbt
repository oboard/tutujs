///|
test "tokenize and parse" {
  @json.inspect("1 * 3 + 8" |> @lexer.parse |> @parser.parse, content={
    "sourceType": "Module",
    "body": [
      [
        "ExpressionStatement",
        {
          "expression": [
            "BinaryExpression",
            {
              "operator": "Plus",
              "left": [
                "BinaryExpression",
                {
                  "operator": "Star",
                  "left": ["NumericLiteral", { "value": 1 }],
                  "right": ["NumericLiteral", { "value": 3 }],
                },
              ],
              "right": ["NumericLiteral", { "value": 8 }],
            },
          ],
        },
      ],
    ],
    "directives": [],
  })
  @json.inspect("1 / 3 * 8 - 8" |> @lexer.parse |> @parser.parse, content={
    "sourceType": "Module",
    "body": [
      [
        "ExpressionStatement",
        {
          "expression": [
            "BinaryExpression",
            {
              "operator": "Minus",
              "left": [
                "BinaryExpression",
                {
                  "operator": "Star",
                  "left": [
                    "BinaryExpression",
                    {
                      "operator": "Slash",
                      "left": ["NumericLiteral", { "value": 1 }],
                      "right": ["NumericLiteral", { "value": 3 }],
                    },
                  ],
                  "right": ["NumericLiteral", { "value": 8 }],
                },
              ],
              "right": ["NumericLiteral", { "value": 8 }],
            },
          ],
        },
      ],
    ],
    "directives": [],
  })
}

///|
test "parse equality" {
  let code = "1 == 1"
  @json.inspect(code |> @lexer.parse |> @parser.parse, content={
    "sourceType": "Module",
    "body": [
      [
        "ExpressionStatement",
        {
          "expression": [
            "BinaryExpression",
            {
              "operator": "Equal",
              "left": ["NumericLiteral", { "value": 1 }],
              "right": ["NumericLiteral", { "value": 1 }],
            },
          ],
        },
      ],
    ],
    "directives": [],
  })
}

///|
test "parse strict equality" {
  @json.inspect("(1 === 1) == true" |> @lexer.parse |> @parser.parse, content={
    "sourceType": "Module",
    "body": [
      [
        "ExpressionStatement",
        {
          "expression": [
            "BinaryExpression",
            {
              "operator": "Equal",
              "left": [
                "BinaryExpression",
                {
                  "operator": "StrictEqual",
                  "left": ["NumericLiteral", { "value": 1 }],
                  "right": ["NumericLiteral", { "value": 1 }],
                },
              ],
              "right": ["BooleanLiteral", { "value": true }],
            },
          ],
        },
      ],
    ],
    "directives": [],
  })
}

///|
test "parse logical" {
  @json.inspect("true || false" |> @lexer.parse |> @parser.parse, content={
    "sourceType": "Module",
    "body": [
      [
        "ExpressionStatement",
        {
          "expression": [
            "LogicalExpression",
            {
              "operator": "LogicalOr",
              "left": ["BooleanLiteral", { "value": true }],
              "right": ["BooleanLiteral", { "value": false }],
            },
          ],
        },
      ],
    ],
    "directives": [],
  })
}

///|
test "parse logical precedence" {
  @json.inspect("true || false && true" |> @lexer.parse |> @parser.parse, content={
    "sourceType": "Module",
    "body": [
      [
        "ExpressionStatement",
        {
          "expression": [
            "LogicalExpression",
            {
              "operator": "LogicalOr",
              "left": ["BooleanLiteral", { "value": true }],
              "right": [
                "LogicalExpression",
                {
                  "operator": "LogicalAnd",
                  "left": ["BooleanLiteral", { "value": false }],
                  "right": ["BooleanLiteral", { "value": true }],
                },
              ],
            },
          ],
        },
      ],
    ],
    "directives": [],
  })
}

///|
test "parse array literal" {
  @json.inspect("[1, 2, , ...a]" |> @lexer.parse |> @parser.parse, content={
    "sourceType": "Module",
    "body": [
      [
        "ExpressionStatement",
        {
          "expression": [
            "ArrayLiteralExpression",
            {
              "elements": [
                ["Expression", ["NumericLiteral", { "value": 1 }]],
                ["Expression", ["NumericLiteral", { "value": 2 }]],
                "OmittedExpression",
                [
                  "SpreadElement",
                  {
                    "argument": [
                      "Identifier",
                      { "name": "a", "optional": false },
                    ],
                  },
                ],
              ],
            },
          ],
        },
      ],
    ],
    "directives": [],
  })
}

///|
test "function" {
  @json.inspect(
    (
      #|function example() { 
      #|  return 1;
      #|}
    )
    |> @lexer.parse
    |> @parser.parse,
    content={
      "sourceType": "Module",
      "body": [
        [
          "FunctionDeclaration",
          {
            "id": { "name": "example", "optional": false },
            "params": [],
            "body": {
              "body": [
                [
                  "ReturnStatement",
                  { "argument": ["NumericLiteral", { "value": 1 }] },
                ],
              ],
              "directives": [],
            },
            "generator": false,
            "async_": false,
            "expression": false,
            "declare_": false,
          },
        ],
      ],
      "directives": [],
    },
  )
}

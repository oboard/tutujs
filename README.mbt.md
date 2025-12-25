# BunnyJS

BunnyJS is a lightweight JavaScript Parser and Interpreter written entirely in [MoonBit](https://www.moonbitlang.com/).

## Introduction

This project aims to explore the potential of MoonBit in building programming language toolchains and to provide an embeddable, high-performance JavaScript runtime subset. It currently supports core JavaScript syntax parsing and basic execution capabilities.

## Key Features

*   **Lexer & Parser**: Handwritten recursive descent parser, independent of third-party generation tools.
    *   Supports variable declarations (`let`, `const`, `var`)
    *   Supports function declarations and calls
    *   Supports control flow statements (`if`, `while`, `return`)
    *   Supports basic expressions (binary operations, member access `obj.prop`, chained calls)
    *   Supports literals (numbers, strings)
*   **AST Definition**: Clear Abstract Syntax Tree structure, easy to extend and traverse.
*   **Pure MoonBit Implementation**: leverages MoonBit's strong type system and WASM compilation advantages for efficiency and safety.

## Roadmap & Status

- [x] **Lexer**: Basic tokenization (Keywords, Identifiers, Numbers, Strings, Operators)
- [x] **Parser**: Recursive descent parsing to AST
    - [x] Variable Declarations
    - [x] Function Declarations
    - [x] Control Flow (`if`, `while`, `return`)
    - [x] Expressions (Binary, Member, Call)
- [x] **Interpreter**: Basic runtime environment
    - [x] Global Scope & Variable Management
    - [x] Basic Expression Evaluation
    - [x] Built-in Function Support (e.g., `console.log`)
- [ ] **Advanced Features**
    - [ ] Object & Array Literals
    - [ ] Closures & Scope Chains
    - [ ] Prototypes & Inheritance
    - [ ] Standard Library (Math, Date, etc.)

## Quick Start

### Installation

Ensure you have installed the [MoonBit toolchain](https://www.moonbitlang.com/download/).

### Running Tests

```bash
moon test
```

### Usage Example

Parse and evaluate a simple piece of JavaScript code:

```moonbit
let ctx = Context::new()
let code = "let x = 10; console.log(x);"
let _ = ctx.eval(code)
```

## Contributing

Contributions are welcome! Feel free to submit Issues or Pull Requests to improve the parser's syntax coverage or enhance interpreter functionality.

## License

Apache License 2.0

# TutuJS Implementation Roadmap

## 1. ES1 / ES2 / ES3 (The Foundations)

### Syntax & Statements
- [x] Primitive Types (`Undefined`, `Null`, `Boolean`, `Number`, `String`)
- [x] Variable Declarations (`var`)
- [x] Function Declarations
- [x] `return` Statement
- [x] `if` / `else` Statements
- [x] Block Statements `{ ... }`
- [x] `while` Loops
- [x] `do...while` Loops
- [x] `for` Loops
- [x] `switch` Statements
- [x] `break` / `continue`
- [ ] `try` / `catch` / `throw`
- [ ] Labelled Statements

### Operators
- [x] Arithmetic (`+`, `-`, `*`, `/`, `%`)
- [x] Comparison (`<`, `>`, `<=`, `>=`)
- [x] Equality (`==`, `!=`, `===`, `!==`)
- [x] Logical (`&&`, `||`, `!`)
- [x] Bitwise (`&`, `|`, `^`, `~`)
- [x] Shift (`<<`, `>>`, `>>>`)
- [x] Assignment (`=`, `+=`, `-=`, etc.)
- [x] `typeof`
- [x] `void`
- [x] `in`
- [x] `instanceof` (Basic stub implemented)
- [x] Conditional (Ternary) `? :`
- [x] `new`
- [x] `this`
- [x] `delete`

### Built-in Objects & Runtime
- [x] Object Literals `{ a: 1 }`
- [x] Array Literals `[ 1, 2 ]` (Basic implementation)
- [x] Prototype Chain Logic
- [x] `Object` Constructor & Properties
- [x] `Function` Constructor & Properties
- [x] `Array` Constructor & Methods (`push`, `pop` implemented)
- [x] `String` Constructor & Methods
- [x] `Number` / `Boolean` Constructors
- [x] `Math` Object
- [ ] `Date` Object 
- [ ] `RegExp` Object
- [ ] `Error` Constructors (`Error`, `TypeError`, etc.)

## 2. ES5 (Stability & APIs)

- [x] Property Accessors (Getters/Setters)
- [x] `JSON` Object (`parse`, `stringify`)
- [x] Strict Mode Support
- [x] `Object` Methods (`keys`, `create`, `defineProperty`, `freeze`, etc.)
- [x] `Array` Iteration Methods (`forEach`, `map`, `filter`, `reduce`, `every`, `some`)
- [x] `Function.prototype.call`, `apply`
- [ ] `Function.prototype.bind`

## 3. ES6 / ES2015 (Modern Era)

### Syntax
- [x] `let` and `const`
- [x] Arrow Functions `() => {}`
- [ ] Classes (`class`, `extends`, `super`)
- [ ] Template Literals `` `Hello ${name}` ``
- [ ] Default Parameters `function(a = 1)`
- [ ] Rest Parameters `function(...args)`
- [ ] Spread Syntax `[...arr]` / `func(...args)`
- [ ] Destructuring Assignment `const {a} = obj`
- [ ] Object Literal Extensions (Shorthand properties, Computed keys)
- [ ] Modules (`import`, `export`)

### Runtime & Built-ins
- [x] `Symbol` Primitive
- [ ] `Map` / `Set`
- [ ] `WeakMap` / `WeakSet`
- [ ] Promises (`Promise`, `then`, `catch`)
- [ ] Iterators & Generators (`function*`, `yield`)
- [ ] `Reflect` API
- [ ] `Proxy` API

## 4. ESNext (2016+)

- [ ] Exponentiation Operator `**` (ES2016)
- [ ] `Array.prototype.includes` (ES2016)
- [ ] `async` / `await` (ES2017)
- [ ] `Object.values`, `Object.entries` (ES2017)
- [ ] Object Rest/Spread `const {a, ...rest} = obj` (ES2018)
- [ ] `Promise.finally` (ES2018)
- [ ] Asynchronous Iteration `for await...of` (ES2018)
- [ ] Optional Catch Binding `catch {}` (ES2019)
- [ ] `BigInt` (ES2020) - *Type support exists*
- [ ] Nullish Coalescing `??` (ES2020)
- [ ] Optional Chaining `?.` (ES2020)
- [ ] `globalThis` (ES2020)
- [ ] Logical Assignment (`||=`, `&&=`, `??=`) (ES2021)
- [ ] Top-level `await` (ES2022)

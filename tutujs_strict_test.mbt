///|
fn parse_and_eval(code : String) -> @runtime.JSValue {
  @runtime.Context::create_global().eval(code)
}

test "strict mode: global directive" {
  let code =
    #| "use strict";
    #| var strict = true; // Just to have some code
  let result = parse_and_eval(code)
  // We can't easily check the internal strict flag from outside, 
  // but we can check if strict mode behaviors are triggered.
  inspect(result, content="undefined")
}

///|
test "strict mode: assignment to read-only property throws" {
  let code =
    #| "use strict";
    #| var obj = {};
    #| Object.defineProperty(obj, "prop", {
    #|   get: function() { return 1; }
    #| });
    #| try {
    #|   obj.prop = 2;
    #| } catch (e) {
    #|   e
    #| }
  let result = parse_and_eval(code)
  inspect(result, content="TypeError: Cannot assign to read only property")
}

///|
test "strict mode: assignment to read-only property inside function" {
  let code =
    #| function test() {
    #|   "use strict";
    #|   var obj = {};
    #|   Object.defineProperty(obj, "prop", {
    #|     get: function() { return 1; }
    #|   });
    #|   obj.prop = 2;
    #| }
    #| try {
    #|   test();
    #| } catch (e) {
    #|   e
    #| }
  let result = parse_and_eval(code)
  inspect(result, content="TypeError: Cannot assign to read only property")
}

///|
test "non-strict mode: assignment to read-only property ignored" {
  let code =
    #| var obj = {};
    #| Object.defineProperty(obj, "prop", {
    #|   get: function() { return 1; }
    #| });
    #| obj.prop = 2;
    #| obj.prop
  let result = parse_and_eval(code)
  inspect(result, content="1")
}

///|
test "strict mode: assignment to non-object throws" {
  let code =
    #| "use strict";
    #| try {
    #|   var n = 1;
    #|   n.prop = 2;
    #| } catch (e) {
    #|   e
    #| }
  let result = parse_and_eval(code)
  inspect(result, content="TypeError: Cannot set property on non-object")
}

///|
test "non-strict mode: assignment to non-object ignored (or handled differently)" {
  let code =
    #| var n = 1;
    #| n.prop = 2;
    #| n.prop
  let result = parse_and_eval(code)
  inspect(result, content="undefined")
}

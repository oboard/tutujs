///|
test "while loop" {
  let code =
    #|
    #| let i = 0;
    #| while (i < 3) {
    #|   i = i + 1;
    #| }
    #| i;
    #|
  @json.inspect(@runtime.Context::new().eval(code), content=["Number", 3])
}

///|
test "while loop with break" {
  let code =
    #|
    #| let i = 0;
    #| while (true) {
    #|   i = i + 1;
    #|   if (i >= 3) {
    #|     break;
    #|   }
    #| }
    #| i;
    #|
  @json.inspect(@runtime.Context::new().eval(code), content=["Number", 3])
}

///|
test "while loop with continue" {
  let code =
    #|
    #| let i = 0;
    #| let sum = 0;
    #| while (i < 5) {
    #|   i = i + 1;
    #|   if (i == 2) {
    #|     continue;
    #|   }
    #|   sum = sum + i;
    #| }
    #| sum; // 1 + 3 + 4 + 5 = 13
    #|
  @json.inspect(@runtime.Context::new().eval(code), content=["Number", 13])
}

///|
test "do...while loop" {
  let code =
    #|
    #| let i = 0;
    #| do {
    #|   i = i + 1;
    #| } while (i < 3);
    #| i;
    #|
  @json.inspect(@runtime.Context::new().eval(code), content=["Number", 3])
}

///|
test "for loop" {
  let code =
    #|
    #| let sum = 0;
    #| for (let i = 1; i <= 3; i = i + 1) {
    #|   sum = sum + i;
    #| }
    #| sum;
    #|
  @json.inspect(@runtime.Context::new().eval(code), content=["Number", 6])
}

///|
test "switch statement" {
  let code =
    #|
    #| let x = 2;
    #| let result = "";
    #| switch (x) {
    #|   case 1:
    #|     result = "one";
    #|     break;
    #|   case 2:
    #|     result = "two";
    #|     break;
    #|   default:
    #|     result = "other";
    #| }
    #| result;
    #|
  @json.inspect(@runtime.Context::new().eval(code), content=["String", "two"])
}

///|
test "ternary operator" {
  let code =
    #|
    #| let x = 10;
    #| let y = x > 5 ? "big" : "small";
    #| y;
    #|
  @json.inspect(@runtime.Context::new().eval(code), content=["String", "big"])
}

///|
test "ternary operator nested" {
  let code =
    #|
    #| var x = 10;
    #| var y = x > 15 ? "huge" : (x > 5 ? "big" : "small");
    #| y;
    #|
  @json.inspect(@runtime.Context::new().eval(code), content=["String", "big"])
}

///|
test "ternary operator truthiness" {
  let code =
    #|
    #| var a = 1 ? "true" : "false";
    #| var b = 0 ? "true" : "false";
    #| var c = "" ? "true" : "false";
    #| var d = "hello" ? "true" : "false";
    #| a + b + c + d;
    #|
  @json.inspect(@runtime.Context::new().eval(code), content=[
    "String", "truefalsefalsetrue",
  ])
}

///|
test "ternary operator precedence" {
  let code =
    #|
    #| var a = true;
    #| var b = false;
    #| var x = a ? b ? "1" : "2" : "3"; // true ? (false ? "1" : "2") : "3" -> "2"
    #| x;
    #|
  @json.inspect(@runtime.Context::new().eval(code), content=["String", "2"])
}

///|
test "instanceof operator" {
  let code =
    #|
    #| var arr = [1, 2, 3];
    #| var isArr = arr instanceof Array;
    #| var isObj = arr instanceof Object;
    #| var isStr = arr instanceof String;
    #| isArr ? (isObj ? (isStr ? "all" : "arr+obj") : "arr") : "none";
    #|
  @json.inspect(@runtime.Context::new().eval(code), content=[
    "String", "arr+obj",
  ])
}

///|
test "for loop (fix verification)" {
  let code =
    #|
    #| var sum = 0;
    #| for (var i = 0; i < 10; i = i + 1) {
    #|   sum = sum + i;
    #| }
    #| sum;
    #|
  @json.inspect(@runtime.Context::new().eval(code), content=["Number", 45])
}

///|
test "object properties" {
  let code =
    #|
    #| var o = { x: 1, y: 2 };
    #| o.z = 3;
    #| o.x + o.y + o.z;
    #|
  @json.inspect(@runtime.Context::new().eval(code), content=["Number", 6])
}

///|
test "fibonacci recursive" {
  let code =
    #|
    #| function fib(n) {
    #|   if (n < 2) { return n; }
    #|   return fib(n - 1) + fib(n - 2);
    #| }
    #| fib(6);
    #|
  @json.inspect(@runtime.Context::new().eval(code), content=["Number", 8])
}

///|
test "array push and pop" {
  let code =
    #|
    #| var arr = [1, 2, 3];
    #| arr.push(4);
    #| var last = arr.pop();
    #| arr.length + last; // 3 + 4 = 7
    #|
  @json.inspect(@runtime.Context::new().eval(code), content=["Number", 7])
}

///|
test "array constructor" {
  let code =
    #|
    #| var arr = new Array(3);
    #| arr[0] = 10;
    #| arr.length + arr[0]; // 3 + 10 = 13
    #|
  @json.inspect(@runtime.Context::new().eval(code), content=["Number", 13])
}

///|
test "array literal prototype" {
  let code =
    #|
    #| var arr = [];
    #| arr.push(1);
    #| arr[0];
    #|
  @json.inspect(@runtime.Context::new().eval(code), content=["Number", 1])
}

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

///|
test "object_accessor" {
  let ctx = Context::new()
  // Test Getter
  let code1 =
    #| var obj = {
    #|   x: 10,
    #|   get doubleX() {
    #|     return this.x * 2;
    #|   }
    #| };
    #| obj.doubleX;
  let res1 = ctx.eval(code1)
  assert_eq(res1, Number(20.0))

  // Test Setter
  let code2 =
    #| var obj = {
    #|   _v: 0,
    #|   set v(val) {
    #|     this._v = val;
    #|   },
    #|   get v() {
    #|     return this._v;
    #|   }
    #| };
    #| obj.v = 100;
    #| obj.v;
  let res2 = ctx.eval(code2)
  assert_eq(res2, Number(100.0))

  // Test Method Shorthand
  let code3 =
    #| var obj = {
    #|   sayHello() {
    #|     return "Hello";
    #|   }
    #| };
    #| obj.sayHello();
  let res3 = ctx.eval(code3)
  assert_eq(res3, String("Hello"))
}

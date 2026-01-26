///|
pub using @runtime {type Context}

///|
pub fn new_context() -> Context {
  let ctx = @runtime.Context::new()
  init_console(ctx)
  ctx
}

///|
fn init_console(ctx : Context) -> Unit {
  let code =
    #| if (typeof console === "undefined") { console = {}; }
    #| console.log = print;
  try! (ctx.eval(code) |> ignore)
}

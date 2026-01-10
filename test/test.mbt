///|
fn test_from(path : String) -> Unit raise Error {
  let code = @fs.read_file_to_string(path) catch {
    e => fail("Read file error" + e.to_string())
  }
  let ctx = @runtime.Context::create_global()
  match ctx.eval_safe(code) {
    Ok(_) => ()
    Err(msg) => fail("Test failed: " + @runtime.format_js_error(msg))
  }
}

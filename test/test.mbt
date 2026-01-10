///|
fn test_from(path : String) -> Unit raise Error {
  let harness_dir = "test/test262/harness/"
  let assert_js = @fs.read_file_to_string(harness_dir + "assert.js") catch {
    _ => ""
  }
  let sta_js = @fs.read_file_to_string(harness_dir + "sta.js") catch { _ => "" }
  let code = @fs.read_file_to_string(path) catch {
    e => fail("Read file error" + e.to_string())
  }
  let full_code = assert_js + "\n" + sta_js + "\n" + code
  let ctx = @runtime.Context::create_global()
  match ctx.eval_safe(full_code) {
    Ok(_) => ()
    Err(msg) => fail("Test failed: " + @runtime.format_js_error(msg))
  }
}

///|
pub fn test_from(path : String) -> Unit raise Error {
  let harness_dir = "test/test262/harness/"
  let assert_js = @fs.read_file_to_string(harness_dir + "assert.js") catch {
    _ => ""
  }
  let sta_js = @fs.read_file_to_string(harness_dir + "sta.js") catch { _ => "" }
  let code = @fs.read_file_to_string(path) catch {
    e => fail("Read file error" + e.to_string())
  }
  let mut harness_code = assert_js + "\n" + sta_js + "\n"
  if code.contains("onlyStrict") {
    harness_code = "\"use strict\";\n" + harness_code
  }
  if code.contains("propertyHelper.js") {
    let ph = @fs.read_file_to_string(harness_dir + "propertyHelper.js") catch {
      _ => ""
    }
    harness_code = harness_code + ph + "\n"
  }
  if code.contains("fnGlobalObject.js") {
    let ph = @fs.read_file_to_string(harness_dir + "fnGlobalObject.js") catch {
      _ => ""
    }
    harness_code = harness_code + ph + "\n"
  }
  if code.contains("compareArray.js") {
    let ph = @fs.read_file_to_string(harness_dir + "compareArray.js") catch {
      _ => ""
    }
    harness_code = harness_code + ph + "\n"
  }
  if code.contains("isConstructor.js") {
    let ph = @fs.read_file_to_string(harness_dir + "isConstructor.js") catch {
      _ => ""
    }
    harness_code = harness_code + ph + "\n"
  }
  if code.contains("assertRelativeDateMs.js") {
    let ph = @fs.read_file_to_string(harness_dir + "assertRelativeDateMs.js") catch {
      _ => ""
    }
    harness_code = harness_code + ph + "\n"
  }
  if code.contains("dateConstants.js") {
    let ph = @fs.read_file_to_string(harness_dir + "dateConstants.js") catch {
      _ => ""
    }
    harness_code = harness_code + ph + "\n"
  }
  // Shim for $262.createRealm if not present
  harness_code = harness_code +
    "if (typeof $262 === 'undefined') { var $262 = {}; }\n"
  harness_code = harness_code +
    "if (typeof $262.createRealm === 'undefined') {\n"
  harness_code = harness_code +
    "  $262.createRealm = function() { return { global: globalThis }; };\n"
  harness_code = harness_code + "}\n"
  let full_code = harness_code + code
  let ctx = @runtime.Context::create_global()
  match ctx.eval_safe(full_code) {
    Ok(_) => ()
    Err(msg) => fail("Test failed: " + @runtime.format_js_error(msg))
  }
}

///|
fn load_harness_file(harness_dir : String, name : String) -> String {
  let path = harness_dir + name
  @fs.read_file_to_string(path) catch {
    _ => ""
  }
}

///|
fn run_test262(path : String) -> Unit {
  let harness_dir = "test/test262/harness/"
  let assert_js = load_harness_file(harness_dir, "assert.js")
  let sta_js = load_harness_file(harness_dir, "sta.js")
  let code = @fs.read_file_to_string(path) catch { _ => "" }
  if code == "" {
    println("FAIL \{path} Read file error")
    return
  }
  let mut harness_code = assert_js + "\n" + sta_js + "\n"
  if code.contains("onlyStrict") {
    harness_code = "\"use strict\";\n" + harness_code
  }
  if code.contains("propertyHelper.js") {
    let ph = load_harness_file(harness_dir, "propertyHelper.js")
    harness_code = harness_code + ph + "\n"
  }
  if code.contains("fnGlobalObject.js") {
    let ph = load_harness_file(harness_dir, "fnGlobalObject.js")
    harness_code = harness_code + ph + "\n"
  }
  if code.contains("compareArray.js") {
    let ph = load_harness_file(harness_dir, "compareArray.js")
    harness_code = harness_code + ph + "\n"
  }
  if code.contains("isConstructor.js") {
    let ph = load_harness_file(harness_dir, "isConstructor.js")
    harness_code = harness_code + ph + "\n"
  }
  if code.contains("assertRelativeDateMs.js") {
    let ph = load_harness_file(harness_dir, "assertRelativeDateMs.js")
    harness_code = harness_code + ph + "\n"
  }
  if code.contains("dateConstants.js") {
    let ph = load_harness_file(harness_dir, "dateConstants.js")
    harness_code = harness_code + ph + "\n"
  }
  harness_code = harness_code +
    "if (typeof $262 === 'undefined') { var $262 = {}; }\n"
  harness_code = harness_code +
    "if (typeof $262.createRealm === 'undefined') {\n"
  harness_code = harness_code +
    "  $262.createRealm = function() { return { global: globalThis }; };\n"
  harness_code = harness_code + "}\n"
  let full_code = harness_code + code
  let ctx = @runtime.create_global()
  let is_negative = code.contains("negative:")
  match ctx.eval_safe(full_code) {
    Ok(_) =>
      if is_negative {
        println("FAIL \{path} Expected error but got success")
      } else {
        println("PASS \{path}")
      }
    Err(msg) =>
      if is_negative {
        println("PASS \{path}")
      } else {
        let formatted = @runtime.format_js_error(msg)
        println("FAIL \{path} \{formatted}")
      }
  }
}

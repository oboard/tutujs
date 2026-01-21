///|
fn load_harness_file(harness_dir : StringView, name : StringView) -> String {
  let path = harness_dir + name
  @fs.read_file_to_string(path.to_string()) catch {
    _ => ""
  }
}

///|
fn get_includes(code : String) -> Array[StringView] {
  let marker = "includes: ["
  let parts = code.split(marker).collect()
  if parts.length() < 2 {
    return []
  }
  let after = parts[1]
  let parts2 = after.split("]").collect()
  if parts2.length() == 0 {
    return []
  }
  let content = parts2[0]
  content.split(",").map(fn(p) { p.trim() }).filter(fn(s) { s != "" }).collect()
}

///|
fn run_test262(path : String) -> Unit {
  let harness_dir = "test/test262/harness/"
  let code = @fs.read_file_to_string(path) catch { _ => "" }
  if code == "" {
    println("FAIL \{path} Read file error")
    return
  }

  // 1. Detect Strict Mode
  let is_strict = code.contains("onlyStrict")

  // 2. Detect Negative Test
  let is_negative = code.contains("negative:") && code.contains("phase:")

  // 3. Build Harness
  let mut harness_code = ""

  // Always load assert.js and sta.js
  harness_code += load_harness_file(harness_dir, "assert.js") + "\n"
  harness_code += load_harness_file(harness_dir, "sta.js") + "\n"
  if is_strict {
    harness_code = "\"use strict\";\n" + harness_code
  }

  // 4. Load explicit includes
  let includes = get_includes(code)
  includes.each(fn(inc) {
    harness_code += load_harness_file(harness_dir, inc) + "\n"
  })

  // 5. Fallback for implicit dependencies
  if code.contains("propertyHelper.js") &&
    not(includes.contains("propertyHelper.js")) {
    harness_code += load_harness_file(harness_dir, "propertyHelper.js") + "\n"
  }
  if code.contains("fnGlobalObject.js") &&
    not(includes.contains("fnGlobalObject.js")) {
    harness_code += load_harness_file(harness_dir, "fnGlobalObject.js") + "\n"
  }
  if code.contains("compareArray.js") &&
    not(includes.contains("compareArray.js")) {
    harness_code += load_harness_file(harness_dir, "compareArray.js") + "\n"
  }
  if code.contains("isConstructor.js") &&
    not(includes.contains("isConstructor.js")) {
    harness_code += load_harness_file(harness_dir, "isConstructor.js") + "\n"
  }
  if code.contains("assertRelativeDateMs.js") &&
    not(includes.contains("assertRelativeDateMs.js")) {
    harness_code += load_harness_file(harness_dir, "assertRelativeDateMs.js") +
      "\n"
  }
  if code.contains("dateConstants.js") &&
    not(includes.contains("dateConstants.js")) {
    harness_code += load_harness_file(harness_dir, "dateConstants.js") + "\n"
  }

  // 6. $262 Mock
  harness_code += "if (typeof $262 === 'undefined') { var $262 = {}; }\n"
  harness_code += "if (typeof $262.createRealm === 'undefined') { $262.createRealm = function() { return { global: globalThis }; }; }\n"
  harness_code += "if (typeof $262.global === 'undefined') { $262.global = globalThis; }\n"
  harness_code += "if (typeof $262.agent === 'undefined') { $262.agent = { start: function(){}, broadcast: function(){}, getReport: function(){}, sleep: function(){} }; }\n"
  harness_code += "if (typeof $262.gc === 'undefined') { $262.gc = function() {}; }\n"
  harness_code += "if (typeof $262.detachArrayBuffer === 'undefined') { $262.detachArrayBuffer = function() {}; }\n"
  let full_code = harness_code + code
  let ctx = @runtime.Context::new()
  let _ = ctx.eval(full_code) catch {
    e => {
      if is_negative {
        println("PASS \{path}")
      } else {
        println("FAIL \{path} \{e}")
      }
      @runtime.value_undefined()
    }
  }
  if is_negative {
    println("FAIL \{path} Expected error but got success")
  } else {
    println("PASS \{path}")
  }
}

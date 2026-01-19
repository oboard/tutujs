///|
test "String charAt/length surrogate pair" {
  let ctx = Context::create_global()
  let check = fn(code : String) {
    match ctx.eval_safe(code) {
      Ok(_) => ()
      Err(e) => abort("Failed: " + code + ", error: " + e.to_string())
    }
  }

  // JS behavior: "\ud834\udf06".length === 2
  check(
    "if ('\ud834\udf06'.length !== 2) throw 'Surrogate pair length should be 2, got ' + '\ud834\udf06'.length",
  )

  // JS behavior: "\ud834\udf06".charAt(0) === "\ud834"
  // check("if ('\ud834\udf06'.charAt(0) !== '\ud834') throw 'charAt(0) failed'")

  // JS behavior: "\ud834\udf06".charAt(1) === "\udf06"
  // check("if ('\ud834\udf06'.charAt(1) !== '\udf06') throw 'charAt(1) failed'")
}

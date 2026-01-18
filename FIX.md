bun test/manage_db.js 可以获取测试，

根据FAIL的错误信息修复 ./runtime/ 然后再调用bun test/manage_db.js获取更多的测试来修复，不要停下来

验证修复需要你运行
moon build --target native && _build/native/release/build/main/main.exe test262 ~/Development/moonbit-packages/tutujs/test/test262/test/annexB/built-ins/Date/prototype/setYear/not-a-constructor.js

你需要做的事情是
while [存在FAIL的测试] {
  bun test/manage_db.js
  [FIX_CODE]
  moon build --target native && _build/native/release/build/main/main.exe test262 [TEST_FILE_PATH]
}

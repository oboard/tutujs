///|
test "RegExp Constructor and Test" {
  let obj_proto = JSValue::Object(JSObject::new(properties=@hashmap.new()))
  let regexp_ctor_val = create_regexp_object(obj_proto, JSValue::Undefined)
  let regexp_ctor = match regexp_ctor_val {
    Function(f) => f
    _ => abort("RegExp is not a function")
  }
  let ctx = Context::new()

  // Test new RegExp("abc")
  let regexp_prototype = regexp_ctor.properties.get("prototype").unwrap()
  let new_re_obj_props = @hashmap.new()
  let new_re_obj = JSValue::Object(
    JSObject::new(properties=new_re_obj_props, prototype=regexp_prototype),
  )
  let _ = match regexp_ctor.body {
    Native(n) => n(ctx, new_re_obj, [JSValue::String("abc")])
    _ => abort("RegExp body is not native")
  }

  // Check internal slot
  match new_re_obj {
    Object(obj) => {
      match obj.properties.get("__internal_regexp__") {
        Some(Internal(RegExp(_, pattern))) =>
          if pattern != "abc" {
            abort("RegExp pattern mismatch")
          }
        _ => abort("new RegExp() did not set internal regexp slot")
      }

      // Test .test() method
      // We need to find 'test' method on prototype
      // regexp_ctor.properties["prototype"] is the prototype object
      let proto_val = regexp_ctor.properties.get("prototype").unwrap()
      let test_method = match proto_val {
        Object(p) => p.properties.get("test").unwrap()
        _ => abort("RegExp.prototype is not object")
      }
      let test_fn = match test_method {
        Function(f) => f
        _ => abort("test is not function")
      }

      // Call test("abcdef") -> true
      let res_true = match test_fn.body {
        Native(n) => n(ctx, new_re_obj, [JSValue::String("abcdef")])
        _ => abort("test body not native")
      }
      match res_true {
        Boolean(true) => ()
        _ => abort("test('abcdef') should be true")
      }

      // Call test("xyz") -> false
      let res_false = match test_fn.body {
        Native(n) => n(ctx, new_re_obj, [JSValue::String("xyz")])
        _ => abort("test body not native")
      }
      match res_false {
        Boolean(false) => ()
        _ => abort("test('xyz') should be false")
      }
    }
    _ => abort("new RegExp() did not return object")
  }
}

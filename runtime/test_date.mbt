///|
test "Date Constructor and Methods" {
  let obj_proto = JSValue::Object(JSObject::new(properties=@hashmap.new()))
  let date_ctor_val = create_date_object(obj_proto)
  let date_ctor = match date_ctor_val {
    Function(f) => f
    _ => abort("Date is not a function")
  }
  let ctx = Context::new()

  // Test Date() -> String
  let date_str = match date_ctor.body {
    Native(n) => n(ctx, JSValue::Undefined, [])
    _ => abort("Date body is not native")
  }
  match date_str {
    String(_) => ()
    _ => abort("Date() should return a string")
  }

  // Test new Date() -> Object
  // We need to simulate 'new' operator which creates object and calls constructor
  // But here we can just call constructor with 'this' as new object (simplified simulation)
  // Actually, create_date_object logic:
  // if is_constructor_call (this is Object) -> sets internal slot
  //

  let new_date_obj_props = @hashmap.new()
  let new_date_obj = JSValue::Object(
    JSObject::new(
      properties=new_date_obj_props,
      prototype=date_ctor.base.prototype.unwrap(),
    ),
  )
  let _ = match date_ctor.body {
    Native(n) => n(ctx, new_date_obj, [])
    _ => abort("Date body is not native")
  }

  // Check internal slot
  match new_date_obj {
    Object(obj) =>
      match obj.properties.get("__internal_date__") {
        Some(Internal(Date(_))) => ()
        _ => abort("new Date() did not set internal date slot")
      }
    _ => abort("new Date() did not return object")
  }

  // Test new Date("2000-01-01T00:00:00Z")
  let iso_date_obj_props = @hashmap.new()
  let iso_date_obj = JSValue::Object(
    JSObject::new(
      properties=iso_date_obj_props,
      prototype=date_ctor.base.prototype.unwrap(),
    ),
  )
  let _ = match date_ctor.body {
    Native(n) => n(ctx, iso_date_obj, [JSValue::String("2000-01-01T00:00:00")])
    _ => abort("Date body is not native")
  }
  match iso_date_obj {
    Object(obj) =>
      match obj.properties.get("__internal_date__") {
        Some(Internal(Date(zdt))) => {
          if zdt.year() != 2000 {
            abort("ISO Date parsing failed: wrong year")
          }
          if zdt.month() != 1 {
            abort("ISO Date parsing failed: wrong month")
          }
          if zdt.day() != 1 {
            abort("ISO Date parsing failed: wrong day")
          }
        }
        _ => abort("new Date(string) did not set internal date slot")
      }
    _ => abort("new Date(string) did not return object")
  }
}

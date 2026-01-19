///|
fn validate_regexp_flags(
  ctx : Context,
  flags : String,
) -> @regexp.RegexpFlags raise EvalError {
  let mut global = false
  let mut ignore_case = false
  let mut multiline = false
  let mut dot_all = false
  let mut unicode = false
  let mut sticky = false
  let mut has_indices = false
  let mut unicode_sets = false
  for c in flags {
    match c {
      'g' =>
        if global {
          ctx.throw_syntax_error("Invalid regular expression flags")
        } else {
          global = true
        }
      'i' =>
        if ignore_case {
          ctx.throw_syntax_error("Invalid regular expression flags")
        } else {
          ignore_case = true
        }
      'm' =>
        if multiline {
          ctx.throw_syntax_error("Invalid regular expression flags")
        } else {
          multiline = true
        }
      's' =>
        if dot_all {
          ctx.throw_syntax_error("Invalid regular expression flags")
        } else {
          dot_all = true
        }
      'u' =>
        if unicode {
          ctx.throw_syntax_error("Invalid regular expression flags")
        } else {
          unicode = true
        }
      'y' =>
        if sticky {
          ctx.throw_syntax_error("Invalid regular expression flags")
        } else {
          sticky = true
        }
      'd' =>
        if has_indices {
          ctx.throw_syntax_error("Invalid regular expression flags")
        } else {
          has_indices = true
        }
      'v' =>
        if unicode_sets {
          ctx.throw_syntax_error("Invalid regular expression flags")
        } else {
          unicode_sets = true
        }
      _ => ctx.throw_syntax_error("Invalid regular expression flags")
    }
  }
  if unicode && unicode_sets {
    ctx.throw_syntax_error("Invalid regular expression flags")
  }
  let mut res_flags = ""
  if has_indices { res_flags = res_flags + "d" }
  if global { res_flags = res_flags + "g" }
  if ignore_case { res_flags = res_flags + "i" }
  if multiline { res_flags = res_flags + "m" }
  if dot_all { res_flags = res_flags + "s" }
  if unicode { res_flags = res_flags + "u" }
  if unicode_sets { res_flags = res_flags + "v" }
  if sticky { res_flags = res_flags + "y" }
  {
    compile: res_flags,
    global,
    ignore_case,
    multiline,
    dot_all,
    unicode,
    sticky,
    has_indices,
    unicode_sets,
  }
}

///|
pub fn create_regexp_constructor(
  regexp_proto : JSValue,
  func_proto : JSValue,
) -> JSValue {
  let regexp_ctor_fn = Native(fn(ctx, this_val, args) raise EvalError {
    let pattern_arg = if args.length() > 0 { args[0] } else { Undefined }
    let flags_arg = if args.length() > 1 { args[1] } else { Undefined }
    let mut pattern_str = ""
    let mut flags_str = ""

    // Check if pattern is already a RegExp object
    let mut pattern_is_regexp = false
    let mut pattern_source = ""
    let mut pattern_flags = ""
    match pattern_arg {
      Object(obj) =>
        match obj.properties.get("__internal_regexp__") {
          Some(Internal(RegExp(prog, src))) => {
            pattern_is_regexp = true
            pattern_source = src
            pattern_flags = prog.flags.compile
          }
          _ => ()
        }
      _ => ()
    }
    let new_target = match this_val {
      Object(_) => true // Simplified new.target check
      _ => false
    }
    if pattern_is_regexp && flags_arg == Undefined && !new_target {
      return pattern_arg
    }
    if pattern_is_regexp {
      pattern_str = pattern_source
      if flags_arg != Undefined {
        flags_str = match flags_arg {
          Undefined => ""
          _ => js_to_string(ctx, flags_arg).to_string()
        }
      } else {
        flags_str = pattern_flags
      }
    } else {
      pattern_str = match pattern_arg {
        Undefined => ""
        _ => js_to_string(ctx, pattern_arg).to_string()
      }
      flags_str = match flags_arg {
        Undefined => ""
        _ => js_to_string(ctx, flags_arg).to_string()
      }
    }
    let flags = validate_regexp_flags(ctx, flags_str)
    let prog = @regexp.regexp_compile(pattern_str, flags) catch {
      _ => ctx.throw_syntax_error("Invalid regular expression: " + pattern_str)
    }
    let obj = JSObject::new(prototype=regexp_proto, properties={
      "lastIndex": JSValue::Number(0.0),
      "__internal_regexp__": JSValue::Internal(RegExp(prog, pattern_str)),
    })
    JSValue::Object(obj)
  })
  let regexp_ctor = JSObject::new_function(
    name="RegExp",
    params=["pattern", "flags"],
    body=regexp_ctor_fn,
    prototype=func_proto,
    is_constructor=true,
  )

  // Set RegExp.prototype property on constructor
  let proto_desc = JSObject::new(properties={
    "value": regexp_proto,
    "writable": JSValue::Boolean(false),
    "enumerable": JSValue::Boolean(false),
    "configurable": JSValue::Boolean(false),
  })
  let ctor_descriptors = match regexp_ctor.properties.get("__descriptors") {
    Some(Object(d)) => d
    _ => {
      let d = JSObject::new(properties={})
      regexp_ctor["__descriptors"] = JSValue::Object(d)
      d
    }
  }
  ctor_descriptors["prototype"] = JSValue::Object(proto_desc)
  regexp_ctor["prototype"] = regexp_proto
  JSValue::Object(regexp_ctor)
}

///|
pub fn init_regexp_prototype(
  regexp_proto_val : JSValue,
  func_proto : JSValue,
) -> Unit {
  match regexp_proto_val {
    Object(proto) => {
      // compile (Annex B)
      let compile_fn = Native(fn(ctx, this_val, args) raise EvalError {
        match this_val {
          Object(obj) => {
            if obj.properties.get("__internal_regexp__").is_empty() {
               ctx.throw_type_error("Method RegExp.prototype.compile called on incompatible receiver")
            }
            
            let pattern_arg = if args.length() > 0 { args[0] } else { Undefined }
            let flags_arg = if args.length() > 1 { args[1] } else { Undefined }
            
            let mut pattern_str = ""
            let mut flags_str = ""
            
            match pattern_arg {
               Object(p_obj) => {
                  match p_obj.properties.get("__internal_regexp__") {
                     Some(Internal(RegExp(prog, src))) => {
                        if flags_arg != Undefined {
                           ctx.throw_type_error("Cannot supply flags when pattern is a RegExp")
                        }
                        pattern_str = src
                        flags_str = prog.flags.compile
                     }
                     _ => {
                        pattern_str = js_to_string(ctx, pattern_arg).to_string()
                        flags_str = if flags_arg != Undefined { js_to_string(ctx, flags_arg).to_string() } else { "" }
                     }
                  }
               }
               _ => {
                  pattern_str = if pattern_arg == Undefined { "" } else { js_to_string(ctx, pattern_arg).to_string() }
                  flags_str = if flags_arg != Undefined { js_to_string(ctx, flags_arg).to_string() } else { "" }
               }
            }
            
            let flags_struct = validate_regexp_flags(ctx, flags_str)
            let prog = try {
               @regexp.regexp_compile(pattern_str, flags_struct)
            } catch {
               _ => ctx.throw_syntax_error("Invalid regular expression: " + pattern_str)
            }
            
            obj["__internal_regexp__"] = JSValue::Internal(RegExp(prog, pattern_str))
            obj["lastIndex"] = JSValue::Number(0.0)
            
            this_val
          }
          _ => ctx.throw_type_error("Method RegExp.prototype.compile called on incompatible receiver")
        }
      })
      let compile_obj = JSObject::new_function(
        name="compile",
        params=["pattern", "flags"],
        body=compile_fn,
        prototype=func_proto,
      )
      proto.properties.set("compile", JSValue::Object(compile_obj))

      // exec
      let exec_fn = Native(fn(ctx, this_val, args) raise EvalError {
        let str_arg = if args.length() > 0 { args[0] } else { Undefined }
        let str = js_to_string(ctx, str_arg).to_string()
        match this_val {
          Object(obj) =>
            match obj.properties.get("__internal_regexp__") {
              Some(Internal(RegExp(prog, _src))) => {
                let last_index = match obj.properties.get("lastIndex") {
                  Some(Number(n)) => n.to_int()
                  _ => 0
                }
                let global = prog.flags.global
                let sticky = prog.flags.sticky
                let start_index = if global || sticky { last_index } else { 0 }
                let match_res = @regexp.regexp_match_from_program(
                  prog,
                  str,
                  start_index,
                  sticky,
                )
                match match_res {
                  Some(m) => {
                    if global || sticky {
                      obj.properties.set(
                        "lastIndex",
                        JSValue::Number(m.end.to_double()),
                      )
                    }
                    let result_arr_props = {}
                    result_arr_props.set(
                      "index",
                      JSValue::Number(m.start.to_double()),
                    )
                    result_arr_props.set("input", JSValue::String(str))
                    result_arr_props.set(
                      "length",
                      JSValue::Number(m.groups.length().to_double()),
                    )
                    for i in 0..<m.groups.length() {
                      let val = match m.groups[i] {
                        Some(s) => JSValue::String(s)
                        None => Undefined
                      }
                      result_arr_props.set(i.to_string(), val)
                    }
                    let array_proto = match ctx.resolve("Array") {
                      Object(f) =>
                        f.properties.get("prototype").unwrap_or(JSValue::Null)
                      _ => JSValue::Null
                    }
                    let result_obj = JSObject::new(
                      prototype=array_proto,
                      properties=result_arr_props,
                    )
                    JSValue::Object(result_obj)
                  }
                  None => {
                    if global || sticky {
                      obj.properties.set("lastIndex", JSValue::Number(0.0))
                    }
                    JSValue::Null
                  }
                }
              }
              _ =>
                ctx.throw_type_error(
                  "Method RegExp.prototype.exec called on incompatible receiver",
                )
            }
          _ =>
            ctx.throw_type_error(
              "Method RegExp.prototype.exec called on incompatible receiver",
            )
        }
      })
      let exec_obj = JSObject::new_function(
        name="exec",
        params=["string"],
        body=exec_fn,
        prototype=func_proto,
      )
      proto.properties.set("exec", JSValue::Object(exec_obj))

      // test
      let test_fn = Native(fn(ctx, this_val, args) raise EvalError {
        let exec = this_val.get_property("exec")
        match exec {
          Object(f) =>
            if f.is_callable {
              let result = ctx.invoke(f, this_val, args)
              JSValue::Boolean(result != JSValue::Null)
            } else {
              JSValue::Boolean(false)
            }
          _ => JSValue::Boolean(false)
        }
      })
      let test_obj = JSObject::new_function(
        name="test",
        params=["string"],
        body=test_fn,
        prototype=func_proto,
      )
      proto.properties.set("test", JSValue::Object(test_obj))

      // toString
      let to_string_fn = Native(fn(ctx, this_val, _args) raise EvalError {
        match this_val {
          Object(obj) =>
            match obj.properties.get("__internal_regexp__") {
              Some(Internal(RegExp(prog, src))) =>
                JSValue::String("/" + src + "/" + prog.flags.compile)
              _ =>
                ctx.throw_type_error(
                  "Method RegExp.prototype.toString called on incompatible receiver",
                )
            }
          _ =>
            ctx.throw_type_error(
              "Method RegExp.prototype.toString called on incompatible receiver",
            )
        }
      })
      let to_string_obj = JSObject::new_function(
        name="toString",
        body=to_string_fn,
        prototype=func_proto,
      )
      proto.properties.set("toString", JSValue::Object(to_string_obj))

      // Accessor properties
      let accessors = [
        "global", "ignoreCase", "multiline", "dotAll", "unicode", "sticky", "source",
        "flags",
      ]
      for name in accessors {
        let getter_fn = Native(fn(ctx, this_val, _args) raise EvalError {
          match this_val {
            Object(obj) =>
              match obj.properties.get("__internal_regexp__") {
                Some(Internal(RegExp(prog, src))) =>
                  match name {
                    "global" => JSValue::Boolean(prog.flags.global)
                    "ignoreCase" => JSValue::Boolean(prog.flags.ignore_case)
                    "multiline" => JSValue::Boolean(prog.flags.multiline)
                    "dotAll" => JSValue::Boolean(prog.flags.dot_all)
                    "unicode" => JSValue::Boolean(prog.flags.unicode)
                    "sticky" => JSValue::Boolean(prog.flags.sticky)
                    "source" => JSValue::String(src)
                    "flags" => JSValue::String(prog.flags.compile)
                    _ => JSValue::Undefined
                  }
                _ =>
                  if this_val.strict_equal(regexp_proto_val) {
                    match name {
                      "source" => JSValue::String("(?:)")
                      "flags" => JSValue::String("")
                      _ => JSValue::Undefined
                    }
                  } else {
                    ctx.throw_type_error(
                      "RegExp.prototype." +
                      name +
                      " getter called on incompatible receiver",
                    )
                  }
              }
            _ =>
              ctx.throw_type_error(
                "RegExp.prototype." +
                name +
                " getter called on incompatible receiver",
              )
          }
        })
        let getter_obj = JSObject::new_function(
          name="get " + name,
          body=getter_fn,
          prototype=func_proto,
        )
        proto.properties.set(
          name,
          JSValue::Internal(Accessor(Some(getter_obj), None)),
        )
      }
    }
    _ => ()
  }
}

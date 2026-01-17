///|
pub fn create_date_object(
  object_proto : JSValue,
  func_proto : JSValue,
) -> JSValue {
  let date_ctor_fn = Native(fn(ctx, this_val, args) raise EvalError {
    let now_nanos = @env.now()
    let now_seconds = (now_nanos / 1_000_000_000).reinterpret_as_int64()
    let is_constructor_call = match this_val {
      Object(_) => true
      _ => false
    }
    if is_constructor_call {
      let mut ms_opt : Double? = None
      if args.length() == 0 {
        ms_opt = Some(
          @env.now().reinterpret_as_int64().to_double() / 1_000_000.0,
        )
      } else if args.length() == 1 {
        match args[0] {
          Number(n) =>
            if n.is_nan() || n.is_inf() || n.abs() > 8.64e15 {
              ms_opt = None
            } else {
              ms_opt = Some(if n == 0.0 { 0.0 } else { n })
            }
          String(s) => ms_opt = parse_date_string(ctx, s.to_string())
          Object(_) =>
            ms_opt = match args[0].get_property("__internal_date__") {
              Internal(Date(ms)) => Some(ms)
              _ => {
                let v = to_primitive(ctx, args[0])
                if v is String(s) {
                  parse_date_string(ctx, s.to_string())
                } else {
                  let n = js_to_number(ctx, v)
                  if n.is_nan() || n.is_inf() || n.abs() > 8.64e15 {
                    None
                  } else {
                    Some(n)
                  }
                }
              }
            }
          _ => {
            let n = js_to_number(ctx, args[0])
            if n.is_nan() || n.is_inf() || n.abs() > 8.64e15 {
              ms_opt = None
            } else {
              ms_opt = Some(n)
            }
          }
        }
      } else {
        let nums = []
        let mut has_nan = false
        for arg in args {
          let n = js_to_number(ctx, arg)
          if n.is_nan() {
            has_nan = true
          }
          nums.push(n)
        }
        if has_nan {
          ms_opt = None
        } else {
          let y_v = nums[0].to_int()
          let y = if y_v >= 0 && y_v <= 99 { 1900 + y_v } else { y_v }
          let m = nums[1].to_int() + 1
          let d = if nums.length() > 2 { nums[2].to_int() } else { 1 }
          let h = if nums.length() > 3 { nums[3].to_int() } else { 0 }
          let min = if nums.length() > 4 { nums[4].to_int() } else { 0 }
          let sec = if nums.length() > 5 { nums[5].to_int() } else { 0 }
          let ms = if nums.length() > 6 { nums[6].to_int() } else { 0 }
          ms_opt = make_date(y, m, d, h, min, sec, ms)
        }
      }
      match this_val {
        Object({ properties, .. }) => {
          match ms_opt {
            Some(ms) =>
              properties["__internal_date__"] = JSValue::Internal(
                JSInternal::Date(ms),
              )
            None => ()
          }
          this_val
        }
        _ => JSValue::Undefined
      }
    } else {
      let zdt = @time.unix(now_seconds, zone=@time.utc_zone) catch {
        _ => return JSValue::String("Invalid Date")
      }
      JSValue::String(format_to_string(zdt))
    }
  })
  let date_ctor = JSObject::new_function(
    name="Date",
    params=["year", "month", "date", "hours", "minutes", "seconds", "ms"],
    body=date_ctor_fn,
    prototype=func_proto,
    is_constructor=true,
  )
  let date_ctor_val = JSValue::Object(date_ctor)
  let date_proto_props = { "constructor": date_ctor_val }
  let date_proto = JSValue::Object(
    JSObject::new(properties=date_proto_props, prototype=object_proto),
  )
  // Set the prototype of the Date constructor
  date_ctor["prototype"] = date_proto
  let define_property = fn(
    obj : JSObject,
    name : String,
    value : JSValue,
    enumerable : Bool,
  ) {
    obj[name] = value
    if not(enumerable) {
      let desc_key = "__descriptors"
      let desc_map = match obj.properties.get(desc_key) {
        Some(Object(m)) => m
        _ => {
          let m = JSObject::new(properties={})
          obj[desc_key] = JSValue::Object(m)
          m
        }
      }
      let d_props = {
        "value": value,
        "writable": JSValue::Boolean(true),
        "enumerable": JSValue::Boolean(false),
        "configurable": JSValue::Boolean(true),
      }
      let d = JSObject::new(properties=d_props)
      desc_map[name] = JSValue::Object(d)
    }
  }
  let define_method = fn(
    name : String,
    body : (Context, JSValue, Array[JSValue]) -> JSValue raise EvalError,
  ) {
    let f = JSObject::new_function(
      name~,
      body=Native(body),
      prototype=func_proto,
    )
    match date_proto {
      Object(obj) => define_property(obj, name, JSValue::Object(f), false)
      _ => ()
    }
  }
  let define_static = fn(
    name : String,
    body : (Context, JSValue, Array[JSValue]) -> JSValue raise EvalError,
    len : Int,
  ) {
    let params = []
    for i = 0; i < len; i = i + 1 {
      params.push("arg" + i.to_string())
    }
    let f = JSObject::new_function(
      name~,
      body=Native(body),
      params~,
      prototype=func_proto,
    )
    define_property(date_ctor, name, JSValue::Object(f), false)
  }
  define_static(
    "now",
    fn(_ctx, _this, _args) {
      JSValue::Number(
        @env.now().reinterpret_as_int64().to_double() / 1_000_000.0,
      )
    },
    0,
  )
  define_static(
    "parse",
    fn(ctx, _this, args) {
      if args.length() == 0 {
        return JSValue::Number(@double.not_a_number)
      }
      let s = match args[0] {
        String(s) => s.to_string()
        _ =>
          (to_primitive(ctx, args[0], hint="String") catch { _ => Undefined }).to_string()
      }
      match parse_date_string(ctx, s) {
        Some(ms) => JSValue::Number(if ms == 0.0 { 0.0 } else { ms })
        None => JSValue::Number(@double.not_a_number)
      }
    },
    1,
  )
  define_static(
    "UTC",
    fn(ctx, _this, args) {
      if args.length() < 2 {
        return JSValue::Number(@double.not_a_number)
      }
      let nums = []
      let mut has_nan = false
      for arg in args {
        let n = js_to_number(ctx, arg)
        if n.is_nan() {
          has_nan = true
        }
        nums.push(n)
      }
      if has_nan {
        return JSValue::Number(@double.not_a_number)
      }
      let y_v = nums[0].to_int()
      let y = if y_v >= 0 && y_v <= 99 { 1900 + y_v } else { y_v }
      let m = nums[1].to_int() + 1
      let d = if nums.length() > 2 { nums[2].to_int() } else { 1 }
      let h = if nums.length() > 3 { nums[3].to_int() } else { 0 }
      let min = if nums.length() > 4 { nums[4].to_int() } else { 0 }
      let sec = if nums.length() > 5 { nums[5].to_int() } else { 0 }
      let ms = if nums.length() > 6 { nums[6].to_int() } else { 0 }
      match make_date(y, m, d, h, min, sec, ms) {
        Some(ms_val) =>
          if ms_val.abs() <= 8.64e15 {
            JSValue::Number(ms_val)
          } else {
            JSValue::Number(@double.not_a_number)
          }
        None => JSValue::Number(@double.not_a_number)
      }
    },
    7,
  )
  let get_zdt = fn(this_val : JSValue) -> @time.ZonedDateTime? {
    match this_val {
      Object({ properties, .. }) =>
        match properties.get("__internal_date__") {
          Some(Internal(Date(ms))) => ms_to_zdt(ms)
          _ => None
        }
      _ => None
    }
  }
  let define_getter = fn(name : String, f : (@time.ZonedDateTime) -> Int) {
    define_method(name, fn(_ctx, this_val, _args) {
      match get_zdt(this_val) {
        Some(zdt) => JSValue::Number(f(zdt).to_double())
        None => JSValue::Number(@double.not_a_number)
      }
    })
  }
  let define_setter = fn(
    name : String,
    f : (Context, @time.ZonedDateTime, Array[JSValue]) -> Double? raise EvalError,
  ) {
    define_method(name, fn(ctx, this_val, args) {
      match this_val {
        Object({ properties, .. }) =>
          match properties.get("__internal_date__") {
            Some(Internal(Date(ms))) =>
              match ms_to_zdt(ms) {
                Some(zdt) =>
                  match f(ctx, zdt, args) {
                    Some(new_ms) => {
                      properties["__internal_date__"] = Internal(Date(new_ms))
                      JSValue::Number(new_ms)
                    }
                    None => {
                      properties.remove("__internal_date__")
                      JSValue::Number(@double.not_a_number)
                    }
                  }
                None => JSValue::Number(@double.not_a_number)
              }
            _ => JSValue::Number(@double.not_a_number)
          }
        _ => ctx.throw_type_error("Method called on non-Date object")
      }
    })
  }
  define_setter("setFullYear", fn(ctx, zdt, args) raise EvalError {
    if args.length() == 0 {
      return None
    }
    let nums = []
    let mut has_nan = false
    for arg in args {
      let n = js_to_number(ctx, arg)
      if n.is_nan() {
        has_nan = true
      }
      nums.push(n)
    }
    if has_nan {
      return None
    }
    let y = nums[0].to_int()
    let m = if nums.length() > 1 { nums[1].to_int() + 1 } else { zdt.month() }
    let d = if nums.length() > 2 { nums[2].to_int() } else { zdt.day() }
    make_date(
      y,
      m,
      d,
      zdt.hour(),
      zdt.minute(),
      zdt.second(),
      zdt.nanosecond() / 1000000,
    )
  })
  define_setter("setUTCFullYear", fn(ctx, zdt, args) raise EvalError {
    if args.length() == 0 {
      return None
    }
    let nums = []
    let mut has_nan = false
    for arg in args {
      let n = js_to_number(ctx, arg)
      if n.is_nan() {
        has_nan = true
      }
      nums.push(n)
    }
    if has_nan {
      return None
    }
    let y = nums[0].to_int()
    let m = if nums.length() > 1 { nums[1].to_int() + 1 } else { zdt.month() }
    let d = if nums.length() > 2 { nums[2].to_int() } else { zdt.day() }
    make_date(
      y,
      m,
      d,
      zdt.hour(),
      zdt.minute(),
      zdt.second(),
      zdt.nanosecond() / 1000000,
    )
  })
  define_setter("setMonth", fn(ctx, zdt, args) raise EvalError {
    if args.length() == 0 {
      return None
    }
    let nums = []
    let mut has_nan = false
    for arg in args {
      let n = js_to_number(ctx, arg)
      if n.is_nan() {
        has_nan = true
      }
      nums.push(n)
    }
    if has_nan {
      return None
    }
    let m = nums[0].to_int() + 1
    let d = if nums.length() > 1 { nums[1].to_int() } else { zdt.day() }
    make_date(
      zdt.year(),
      m,
      d,
      zdt.hour(),
      zdt.minute(),
      zdt.second(),
      zdt.nanosecond() / 1000000,
    )
  })
  define_setter("setUTCMonth", fn(ctx, zdt, args) raise EvalError {
    if args.length() == 0 {
      return None
    }
    let nums = []
    let mut has_nan = false
    for arg in args {
      let n = js_to_number(ctx, arg)
      if n.is_nan() {
        has_nan = true
      }
      nums.push(n)
    }
    if has_nan {
      return None
    }
    let m = nums[0].to_int() + 1
    let d = if nums.length() > 1 { nums[1].to_int() } else { zdt.day() }
    make_date(
      zdt.year(),
      m,
      d,
      zdt.hour(),
      zdt.minute(),
      zdt.second(),
      zdt.nanosecond() / 1000000,
    )
  })
  define_setter("setDate", fn(ctx, _zdt, args) raise EvalError {
    if args.length() == 0 {
      return None
    }
    let n = js_to_number(ctx, args[0])
    if n.is_nan() {
      return None
    }
    let d = n.to_int()
    make_date(
      _zdt.year(),
      _zdt.month(),
      d,
      _zdt.hour(),
      _zdt.minute(),
      _zdt.second(),
      _zdt.nanosecond() / 1000000,
    )
  })
  define_setter("setUTCDate", fn(ctx, _zdt, args) raise EvalError {
    if args.length() == 0 {
      return None
    }
    let n = js_to_number(ctx, args[0])
    if n.is_nan() {
      return None
    }
    let d = n.to_int()
    make_date(
      _zdt.year(),
      _zdt.month(),
      d,
      _zdt.hour(),
      _zdt.minute(),
      _zdt.second(),
      _zdt.nanosecond() / 1000000,
    )
  })
  define_setter("setHours", fn(ctx, zdt, args) raise EvalError {
    if args.length() == 0 {
      return None
    }
    let nums = []
    let mut has_nan = false
    for arg in args {
      let n = js_to_number(ctx, arg)
      if n.is_nan() {
        has_nan = true
      }
      nums.push(n)
    }
    if has_nan {
      return None
    }
    let h = nums[0].to_int()
    let min = if nums.length() > 1 { nums[1].to_int() } else { zdt.minute() }
    let sec = if nums.length() > 2 { nums[2].to_int() } else { zdt.second() }
    let ms = if nums.length() > 3 {
      nums[3].to_int()
    } else {
      zdt.nanosecond() / 1000000
    }
    make_date(zdt.year(), zdt.month(), zdt.day(), h, min, sec, ms)
  })
  define_setter("setUTCHours", fn(ctx, zdt, args) raise EvalError {
    if args.length() == 0 {
      return None
    }
    let nums = []
    let mut has_nan = false
    for arg in args {
      let n = js_to_number(ctx, arg)
      if n.is_nan() {
        has_nan = true
      }
      nums.push(n)
    }
    if has_nan {
      return None
    }
    let h = nums[0].to_int()
    let min = if nums.length() > 1 { nums[1].to_int() } else { zdt.minute() }
    let sec = if nums.length() > 2 { nums[2].to_int() } else { zdt.second() }
    let ms = if nums.length() > 3 {
      nums[3].to_int()
    } else {
      zdt.nanosecond() / 1000000
    }
    make_date(zdt.year(), zdt.month(), zdt.day(), h, min, sec, ms)
  })
  define_setter("setMinutes", fn(ctx, zdt, args) raise EvalError {
    if args.length() == 0 {
      return None
    }
    let nums = []
    let mut has_nan = false
    for arg in args {
      let n = js_to_number(ctx, arg)
      if n.is_nan() {
        has_nan = true
      }
      nums.push(n)
    }
    if has_nan {
      return None
    }
    let min = nums[0].to_int()
    let sec = if nums.length() > 1 { nums[1].to_int() } else { zdt.second() }
    let ms = if nums.length() > 2 {
      nums[2].to_int()
    } else {
      zdt.nanosecond() / 1000000
    }
    make_date(zdt.year(), zdt.month(), zdt.day(), zdt.hour(), min, sec, ms)
  })
  define_setter("setUTCMinutes", fn(ctx, zdt, args) raise EvalError {
    if args.length() == 0 {
      return None
    }
    let nums = []
    let mut has_nan = false
    for arg in args {
      let n = js_to_number(ctx, arg)
      if n.is_nan() {
        has_nan = true
      }
      nums.push(n)
    }
    if has_nan {
      return None
    }
    let min = nums[0].to_int()
    let sec = if nums.length() > 1 { nums[1].to_int() } else { zdt.second() }
    let ms = if nums.length() > 2 {
      nums[2].to_int()
    } else {
      zdt.nanosecond() / 1000000
    }
    make_date(zdt.year(), zdt.month(), zdt.day(), zdt.hour(), min, sec, ms)
  })
  define_setter("setSeconds", fn(ctx, zdt, args) raise EvalError {
    if args.length() == 0 {
      return None
    }
    let nums = []
    let mut has_nan = false
    for arg in args {
      let n = js_to_number(ctx, arg)
      if n.is_nan() {
        has_nan = true
      }
      nums.push(n)
    }
    if has_nan {
      return None
    }
    let sec = nums[0].to_int()
    let ms = if nums.length() > 1 {
      nums[1].to_int()
    } else {
      zdt.nanosecond() / 1000000
    }
    make_date(
      zdt.year(),
      zdt.month(),
      zdt.day(),
      zdt.hour(),
      zdt.minute(),
      sec,
      ms,
    )
  })
  define_setter("setUTCSeconds", fn(ctx, zdt, args) raise EvalError {
    if args.length() == 0 {
      return None
    }
    let nums = []
    let mut has_nan = false
    for arg in args {
      let n = js_to_number(ctx, arg)
      if n.is_nan() {
        has_nan = true
      }
      nums.push(n)
    }
    if has_nan {
      return None
    }
    let sec = nums[0].to_int()
    let ms = if nums.length() > 1 {
      nums[1].to_int()
    } else {
      zdt.nanosecond() / 1000000
    }
    make_date(
      zdt.year(),
      zdt.month(),
      zdt.day(),
      zdt.hour(),
      zdt.minute(),
      sec,
      ms,
    )
  })
  define_setter("setMilliseconds", fn(ctx, zdt, args) raise EvalError {
    if args.length() == 0 {
      return None
    }
    let n = js_to_number(ctx, args[0])
    if n.is_nan() {
      return None
    }
    let ms = n.to_int()
    make_date(
      zdt.year(),
      zdt.month(),
      zdt.day(),
      zdt.hour(),
      zdt.minute(),
      zdt.second(),
      ms,
    )
  })
  define_setter("setUTCMilliseconds", fn(ctx, zdt, args) raise EvalError {
    if args.length() == 0 {
      return None
    }
    let n = js_to_number(ctx, args[0])
    if n.is_nan() {
      return None
    }
    let ms = n.to_int()
    make_date(
      zdt.year(),
      zdt.month(),
      zdt.day(),
      zdt.hour(),
      zdt.minute(),
      zdt.second(),
      ms,
    )
  })
  define_method("setTime", fn(ctx, this_val, args) {
    if args.length() == 0 {
      return JSValue::Number(@double.not_a_number)
    }
    let n = js_to_number(ctx, args[0])
    match this_val {
      Object({ properties, .. }) =>
        if n.is_nan() || n.is_inf() || n.abs() > 8.64e15 {
          properties.remove("__internal_date__")
          JSValue::Number(@double.not_a_number)
        } else {
          properties["__internal_date__"] = Internal(Date(n))
          JSValue::Number(n)
        }
      _ => JSValue::Number(@double.not_a_number)
    }
  })
  define_getter("getFullYear", fn(zdt) { zdt.year() })
  define_getter("getUTCFullYear", fn(zdt) { zdt.year() })
  define_getter("getMonth", fn(zdt) { zdt.month() - 1 })
  define_getter("getUTCMonth", fn(zdt) { zdt.month() - 1 })
  define_getter("getDate", fn(zdt) { zdt.day() })
  define_getter("getUTCDate", fn(zdt) { zdt.day() })
  define_getter("getHours", fn(zdt) { zdt.hour() })
  define_getter("getUTCHours", fn(zdt) { zdt.hour() })
  define_getter("getMinutes", fn(zdt) { zdt.minute() })
  define_getter("getUTCMinutes", fn(zdt) { zdt.minute() })
  define_getter("getSeconds", fn(zdt) { zdt.second() })
  define_getter("getUTCSeconds", fn(zdt) { zdt.second() })
  define_getter("getMilliseconds", fn(zdt) { zdt.nanosecond() / 1000000 })
  define_getter("getUTCMilliseconds", fn(zdt) { zdt.nanosecond() / 1000000 })
  define_getter("getDay", fn(zdt) {
    match zdt.weekday() {
      @time.Sunday => 0
      @time.Monday => 1
      @time.Tuesday => 2
      @time.Wednesday => 3
      @time.Thursday => 4
      @time.Friday => 5
      @time.Saturday => 6
    }
  })
  define_getter("getUTCDay", fn(zdt) {
    match zdt.weekday() {
      @time.Sunday => 0
      @time.Monday => 1
      @time.Tuesday => 2
      @time.Wednesday => 3
      @time.Thursday => 4
      @time.Friday => 5
      @time.Saturday => 6
    }
  })
  define_getter("getYear", fn(zdt) { zdt.year() - 1900 })
  define_method("getTime", fn(_ctx, this_val, _args) {
    match this_val {
      Object({ properties, .. }) =>
        match properties.get("__internal_date__") {
          Some(Internal(Date(ms))) => JSValue::Number(ms)
          _ => JSValue::Number(@double.not_a_number)
        }
      _ => JSValue::Number(@double.not_a_number)
    }
  })
  define_method("valueOf", fn(_ctx, this_val, _args) {
    match this_val {
      Object({ properties, .. }) =>
        match properties.get("__internal_date__") {
          Some(Internal(Date(ms))) => JSValue::Number(ms)
          _ => JSValue::Number(@double.not_a_number)
        }
      _ => JSValue::Number(@double.not_a_number)
    }
  })
  define_method("toString", fn(_ctx, this_val, _args) {
    match this_val {
      Object({ properties, .. }) =>
        match properties.get("__internal_date__") {
          Some(Internal(Date(ms))) =>
            match ms_to_zdt(ms) {
              Some(zdt) => JSValue::String(format_to_string(zdt))
              None => JSValue::String("Invalid Date")
            }
          _ => JSValue::String("Invalid Date")
        }
      _ => JSValue::String("Invalid Date")
    }
  })
  define_method("toDateString", fn(_ctx, this_val, _args) {
    match get_zdt(this_val) {
      Some(zdt) => {
        let wd = match zdt.weekday() {
          @time.Monday => "Mon"
          @time.Tuesday => "Tue"
          @time.Wednesday => "Wed"
          @time.Thursday => "Thu"
          @time.Friday => "Fri"
          @time.Saturday => "Sat"
          @time.Sunday => "Sun"
        }
        let m = match zdt.month() {
          1 => "Jan"
          2 => "Feb"
          3 => "Mar"
          4 => "Apr"
          5 => "May"
          6 => "Jun"
          7 => "Jul"
          8 => "Aug"
          9 => "Sep"
          10 => "Oct"
          11 => "Nov"
          12 => "Dec"
          _ => "Jan"
        }
        let ms = match this_val {
          Object({ properties, .. }) =>
            match properties.get("__internal_date__") {
              Some(Internal(Date(ms))) => ms
              _ => 0.0
            }
          _ => 0.0
        }
        let ms_per_400_years : Double = 146097.0 * 24.0 * 3600.0 * 1000.0
        let cycle = (ms / ms_per_400_years).floor().to_int()
        let y = zdt.year() + cycle * 400
        JSValue::String("\{wd} \{m} \{pad2(zdt.day())} \{y}")
      }
      _ => JSValue::String("Invalid Date")
    }
  })
  define_method("toTimeString", fn(_ctx, this_val, _args) {
    match get_zdt(this_val) {
      Some(zdt) =>
        JSValue::String(
          "\{pad2(zdt.hour())}:\{pad2(zdt.minute())}:\{pad2(zdt.second())} GMT+0000 (Coordinated Universal Time)",
        )
      _ => JSValue::String("Invalid Date")
    }
  })
  define_method("toISOString", fn(_ctx, this_val, _args) {
    match this_val {
      Object({ properties, .. }) =>
        match properties.get("__internal_date__") {
          Some(Internal(Date(ms))) => JSValue::String(format_iso(ms))
          _ => JSValue::String("Invalid Date")
        }
      _ => JSValue::String("Invalid Date")
    }
  })
  define_method("toJSON", fn(ctx, this_val, args) raise EvalError {
    match this_val.get_property("toISOString") {
      Object(f) =>
        if f.is_callable {
          ctx.invoke(f, this_val, args)
        } else {
          JSValue::String("Invalid Date")
        }
      _ => JSValue::String("Invalid Date")
    }
  })
  define_method("toLocaleString", fn(ctx, this_val, args) raise EvalError {
    match this_val.get_property("toString") {
      Object(f) =>
        if f.is_callable {
          ctx.invoke(f, this_val, args)
        } else {
          JSValue::String("Invalid Date")
        }
      _ => JSValue::String("Invalid Date")
    }
  })
  define_method("toLocaleDateString", fn(ctx, this_val, args) raise EvalError {
    match this_val.get_property("toDateString") {
      Object(f) =>
        if f.is_callable {
          ctx.invoke(f, this_val, args)
        } else {
          JSValue::String("Invalid Date")
        }
      _ => JSValue::String("Invalid Date")
    }
  })
  define_method("toLocaleTimeString", fn(ctx, this_val, args) raise EvalError {
    match this_val.get_property("toTimeString") {
      Object(f) =>
        if f.is_callable {
          ctx.invoke(f, this_val, args)
        } else {
          JSValue::String("Invalid Date")
        }
      _ => JSValue::String("Invalid Date")
    }
  })
  define_method("getTimezoneOffset", fn(_ctx, _this_val, _args) {
    JSValue::Number(0.0)
  })
  define_method("toUTCString", fn(_ctx, this_val, _args) {
    match get_zdt(this_val) {
      Some(zdt) => JSValue::String(format_to_string(zdt))
      _ => JSValue::String("Invalid Date")
    }
  })
  let toPrimitive = JSValue::Symbol(1010, "Symbol.toPrimitive").to_property_key()
  define_method(toPrimitive, fn(ctx, this_val, args) raise EvalError {
    let hint = match args {
      [String(s)] => s.to_string()
      _ => "default"
    }
    let method_names = if hint == "string" || hint == "default" {
      ["toString", "valueOf"]
    } else {
      ["valueOf", "toString"]
    }
    for name in method_names {
      match this_val.get_property(name) {
        Object(f) =>
          if f.is_callable {
            let res = ctx.invoke(f, this_val, [])
            match res {
              Object(_) => ()
              _ => return res
            }
          }
        _ => ()
      }
    }
    ctx.throw_type_error("Cannot convert Date to primitive")
  })
  let toStringTag = JSValue::Symbol(1011, "Symbol.toStringTag").to_property_key()
  date_proto_props.set(toStringTag, JSValue::String("Date"))
  JSValue::Object(date_ctor)
}

///|
fn ms_to_zdt(ms : Double) -> @time.ZonedDateTime? {
  if ms.is_nan() || ms.is_inf() || ms.abs() > 8.64e15 {
    return None
  }
  try {
    let ms_per_400_years : Double = 146097.0 * 24.0 * 3600.0 * 1000.0
    let cycle = (ms / ms_per_400_years).floor().to_int()
    let shifted_ms = ms - cycle.to_double() * ms_per_400_years
    let s = (shifted_ms / 1000.0).floor().to_int64()
    let ns = ((shifted_ms - s.to_double() * 1000.0) * 1000000.0)
      .round()
      .to_int()
    Some(@time.unix(s, nanosecond=ns, zone=@time.utc_zone))
  } catch {
    _ => None
  }
}

///|
fn pad2(n : Int) -> String {
  if n < 10 {
    "0" + n.to_string()
  } else {
    n.to_string()
  }
}

///|
fn pad3(n : Int) -> String {
  if n < 10 {
    "00" + n.to_string()
  } else if n < 100 {
    "0" + n.to_string()
  } else {
    n.to_string()
  }
}

///|
fn pad4(n : Int) -> String {
  let mut s = n.to_string()
  while s.length() < 4 {
    s = "0" + s
  }
  s
}

///|
fn pad6(n : Int) -> String {
  let mut s = n.to_string()
  while s.length() < 6 {
    s = "0" + s
  }
  s
}

///|
fn format_iso(ms : Double) -> String {
  let ms_per_400_years : Double = 146097.0 * 24.0 * 3600.0 * 1000.0
  let cycle = (ms / ms_per_400_years).floor().to_int()
  let shifted_ms = ms - cycle.to_double() * ms_per_400_years
  match ms_to_zdt(shifted_ms) {
    Some(zdt) => {
      let y = zdt.year() + cycle * 400
      let m = pad2(zdt.month())
      let d = pad2(zdt.day())
      let h = pad2(zdt.hour())
      let min = pad2(zdt.minute())
      let sec = pad2(zdt.second())
      let ms_rem = pad3(zdt.nanosecond() / 1000000)
      if y >= 0 && y <= 9999 {
        "\{pad4(y)}-\{m}-\{d}T\{h}:\{min}:\{sec}.\{ms_rem}Z"
      } else {
        let sign = if y >= 0 { "+" } else { "-" }
        let abs_y = if y >= 0 { y } else { -y }
        let y_str = pad6(abs_y)
        "\{sign}\{y_str}-\{m}-\{d}T\{h}:\{min}:\{sec}.\{ms_rem}Z"
      }
    }
    None => "Invalid Date"
  }
}

///|
fn format_to_string(zdt : @time.ZonedDateTime) -> String {
  let wd = match zdt.weekday() {
    @time.Monday => "Mon"
    @time.Tuesday => "Tue"
    @time.Wednesday => "Wed"
    @time.Thursday => "Thu"
    @time.Friday => "Fri"
    @time.Saturday => "Sat"
    @time.Sunday => "Sun"
  }
  let m = match zdt.month() {
    1 => "Jan"
    2 => "Feb"
    3 => "Mar"
    4 => "Apr"
    5 => "May"
    6 => "Jun"
    7 => "Jul"
    8 => "Aug"
    9 => "Sep"
    10 => "Oct"
    11 => "Nov"
    12 => "Dec"
    _ => "Jan"
  }
  let y = zdt.year()
  let y_str = if y >= 0 && y <= 9999 {
    y.to_string()
  } else {
    let sign = if y >= 0 { "+" } else { "-" }
    let mut ys = (if y >= 0 { y } else { -y }).to_string()
    while ys.length() < 6 {
      ys = "0" + ys
    }
    sign + ys
  }
  "\{wd}, \{pad2(zdt.day())} \{m} \{y_str} \{pad2(zdt.hour())}:\{pad2(zdt.minute())}:\{pad2(zdt.second())} GMT"
}

///|
fn make_date(
  y : Int,
  m : Int,
  d : Int,
  hour : Int,
  min : Int,
  sec : Int,
  ms : Int,
) -> Double? {
  try {
    let mut year = y
    let mut month = m
    if month > 12 || month < 1 {
      year = year + (month - 1) / 12
      month = (month - 1) % 12 + 1
      if month < 1 {
        year = year - 1
        month = month + 12
      }
    }
    let mut total_ms = ms.to_int64()
    let mut total_sec = sec.to_int64() + total_ms / 1000
    total_ms = total_ms % 1000
    if total_ms < 0 {
      total_sec = total_sec - 1
      total_ms = total_ms + 1000
    }
    let mut total_min = min.to_int64() + total_sec / 60
    total_sec = total_sec % 60
    if total_sec < 0 {
      total_min = total_min - 1
      total_sec = total_sec + 60
    }
    let mut total_hour = hour.to_int64() + total_min / 60
    total_min = total_min % 60
    if total_min < 0 {
      total_hour = total_hour - 1
      total_min = total_min + 60
    }
    let mut day_offset = (total_hour / 24).to_int()
    total_hour = total_hour % 24
    if total_hour < 0 {
      day_offset = day_offset - 1
      total_hour = total_hour + 24
    }

    // Handle large years by shifting
    let cycle = (year - 2000) / 400
    let shifted_year = year - cycle * 400
    let zdt = @time.date_time(
      shifted_year,
      month,
      1,
      hour=total_hour.to_int(),
      minute=total_min.to_int(),
      second=total_sec.to_int(),
      nanosecond=total_ms.to_int() * 1000000,
      zone=@time.utc_zone,
    )
    let final_shifted_zdt = zdt.add_days((d + day_offset - 1).to_int64())
    let ms_per_400_years : Double = 146097.0 * 24.0 * 3600.0 * 1000.0
    let ms_val = final_shifted_zdt.to_unix_second().to_double() * 1000.0 +
      (final_shifted_zdt.nanosecond() / 1000000).to_double() +
      cycle.to_double() * ms_per_400_years
    if ms_val.abs() <= 8.64e15 {
      if ms_val == 0.0 {
        Some(0.0)
      } else {
        Some(ms_val)
      }
    } else {
      None
    }
  } catch {
    _ => None
  }
}

///|
fn parse_date_string(_ctx : Context, s : String) -> Double? {
  let s = s.trim()
  if s == "" {
    return None
  }
  try {
    if s.has_prefix("+") {
      return parse_date_string(_ctx, s[1:].to_string())
    }
    lexmatch s with longest {
      // YYYY-MM-DDTHH:mm:ss.sssZ
      (
        ("-?[0-9]+" as y_s)
        "-"
        ("[0-9]{2}" as m_s)
        "-"
        ("[0-9]{2}" as d_s)
        "T"
        ("[0-9]{2}" as h_s)
        ":"
        ("[0-9]{2}" as min_s)
        ":"
        ("[0-9]{2}" as sec_s)
        "."
        ("[0-9]{3}" as ms_s)
        "Z"
      ) => {
        let y = @strconv.parse_int(y_s)
        let m = @strconv.parse_int(m_s)
        let d = @strconv.parse_int(d_s)
        let h = @strconv.parse_int(h_s)
        let min = @strconv.parse_int(min_s)
        let sec = @strconv.parse_int(sec_s)
        let ms = @strconv.parse_int(ms_s)
        make_date(y, m, d, h, min, sec, ms)
      }
      // YYYY-MM-DDTHH:mm:ss.sss
      (
        ("-?[0-9]+" as y_s)
        "-"
        ("[0-9]{2}" as m_s)
        "-"
        ("[0-9]{2}" as d_s)
        "T"
        ("[0-9]{2}" as h_s)
        ":"
        ("[0-9]{2}" as min_s)
        ":"
        ("[0-9]{2}" as sec_s)
        "."
        ("[0-9]{3}" as ms_s)
      ) => {
        let y = @strconv.parse_int(y_s)
        let m = @strconv.parse_int(m_s)
        let d = @strconv.parse_int(d_s)
        let h = @strconv.parse_int(h_s)
        let min = @strconv.parse_int(min_s)
        let sec = @strconv.parse_int(sec_s)
        let ms = @strconv.parse_int(ms_s)
        make_date(y, m, d, h, min, sec, ms)
      }
      // YYYY-MM-DDTHH:mm:ssZ
      (
        ("-?[0-9]+" as y_s)
        "-"
        ("[0-9]{2}" as m_s)
        "-"
        ("[0-9]{2}" as d_s)
        "T"
        ("[0-9]{2}" as h_s)
        ":"
        ("[0-9]{2}" as min_s)
        ":"
        ("[0-9]{2}" as sec_s)
        "Z"
      ) => {
        let y = @strconv.parse_int(y_s)
        let m = @strconv.parse_int(m_s)
        let d = @strconv.parse_int(d_s)
        let h = @strconv.parse_int(h_s)
        let min = @strconv.parse_int(min_s)
        let sec = @strconv.parse_int(sec_s)
        make_date(y, m, d, h, min, sec, 0)
      }
      // YYYY-MM-DDTHH:mm:ss
      (
        ("-?[0-9]+" as y_s)
        "-"
        ("[0-9]{2}" as m_s)
        "-"
        ("[0-9]{2}" as d_s)
        "T"
        ("[0-9]{2}" as h_s)
        ":"
        ("[0-9]{2}" as min_s)
        ":"
        ("[0-9]{2}" as sec_s)
      ) => {
        let y = @strconv.parse_int(y_s)
        let m = @strconv.parse_int(m_s)
        let d = @strconv.parse_int(d_s)
        let h = @strconv.parse_int(h_s)
        let min = @strconv.parse_int(min_s)
        let sec = @strconv.parse_int(sec_s)
        make_date(y, m, d, h, min, sec, 0)
      }
      // YYYY-MM-DD
      (("-?[0-9]+" as y_s) "-" ("[0-9]{2}" as m_s) "-" ("[0-9]{2}" as d_s)) => {
        let y = @strconv.parse_int(y_s)
        let m = @strconv.parse_int(m_s)
        let d = @strconv.parse_int(d_s)
        make_date(y, m, d, 0, 0, 0, 0)
      }
      // YYYY-MM
      (("-?[0-9]+" as y_s) "-" ("[0-9]{2}" as m_s)) => {
        let y = @strconv.parse_int(y_s)
        let m = @strconv.parse_int(m_s)
        make_date(y, m, 1, 0, 0, 0, 0)
      }
      // YYYY
      ("-?[0-9]+" as y_s) => {
        let y = @strconv.parse_int(y_s)
        make_date(y, 1, 1, 0, 0, 0, 0)
      }
      // Thu, 01 Jan 1970 00:00:00 GMT
      (
        "[A-Za-z]{3}"
        ", "
        ("[0-9]{1,2}" as d_s)
        " "
        ("[A-Za-z]{3}" as m_s)
        " "
        ("[0-9]+" as y_s)
        " "
        ("[0-9]{1,2}" as h_s)
        ":"
        ("[0-9]{2}" as min_s)
        ":"
        ("[0-9]{2}" as sec_s)
        " GMT"
      ) => {
        let y = @strconv.parse_int(y_s)
        let d = @strconv.parse_int(d_s)
        let h = @strconv.parse_int(h_s)
        let min = @strconv.parse_int(min_s)
        let sec = @strconv.parse_int(sec_s)
        let m = match m_s {
          "Jan" => 1
          "Feb" => 2
          "Mar" => 3
          "Apr" => 4
          "May" => 5
          "Jun" => 6
          "Jul" => 7
          "Aug" => 8
          "Sep" => 9
          "Oct" => 10
          "Nov" => 11
          "Dec" => 12
          _ => 1
        }
        make_date(y, m, d, h, min, sec, 0)
      }
      _ => None
    }
  } catch {
    _ => None
  }
}

///|
fn add_suffix_zero(s : String, len : Int) -> String {
  let mut res = s
  while res.length() < len {
    res += "0"
  }
  res
}

///|
fn parse_gmt_string(s_str : String) -> (Int, Int, Int)? {
  let find_m = fn(name : String) -> Int {
    match name {
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
      _ => 0
    }
  }
  // Simplified GMT/UTC pattern matching
  let parts = s_str.split(" ").to_array()
  if parts.length() >= 4 {
    let mut m_idx = find_m(parts[2].to_string())
    if m_idx > 0 {
      let d = @strconv.parse_int(parts[1].to_string()) catch { _ => 0 }
      let y = @strconv.parse_int(parts[3].to_string()) catch { _ => 0 }
      if d > 0 && y != 0 {
        return Some((y, m_idx, d))
      }
    }
    m_idx = find_m(parts[1].to_string())
    if m_idx > 0 {
      let d = @strconv.parse_int(parts[2].to_string()) catch { _ => 0 }
      let y = @strconv.parse_int(parts[3].to_string()) catch { _ => 0 }
      if d > 0 && y != 0 {
        return Some((y, m_idx, d))
      }
    }
  }
  None
}

///|
fn parse_date_string(_ctx : Context, s_str : String) -> Double? {
  let mut y = 0
  let mut m = 1
  let mut d = 1
  let mut h = 0
  let mut min = 0
  let mut sec = 0
  let mut ms = 0
  let mut matched = false
  try {
    lexmatch s_str with longest {
      // YYYY-MM-DDTHH:mm:ss.sssZ
      (
        ("[0-9]{4}" as y_s)
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
        ("[0-9]{1,3}" as ms_s)
        "Z"
      ) => {
        y = @strconv.parse_int(y_s)
        m = @strconv.parse_int(m_s)
        d = @strconv.parse_int(d_s)
        h = @strconv.parse_int(h_s)
        min = @strconv.parse_int(min_s)
        sec = @strconv.parse_int(sec_s)
        ms = @strconv.parse_int(add_suffix_zero(ms_s.to_string(), 3))
        matched = true
      }
      // YYYY-MM-DDTHH:mm:ssZ
      (
        ("[0-9]{4}" as y_s)
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
        y = @strconv.parse_int(y_s)
        m = @strconv.parse_int(m_s)
        d = @strconv.parse_int(d_s)
        h = @strconv.parse_int(h_s)
        min = @strconv.parse_int(min_s)
        sec = @strconv.parse_int(sec_s)
        matched = true
      }
      // YYYY-MM-DD
      (("[0-9]{4}" as y_s) "-" ("[0-9]{2}" as m_s) "-" ("[0-9]{2}" as d_s)) => {
        y = @strconv.parse_int(y_s)
        m = @strconv.parse_int(m_s)
        d = @strconv.parse_int(d_s)
        matched = true
      }
      // YYYY-MM
      (("[0-9]{4}" as y_s) "-" ("[0-9]{2}" as m_s)) => {
        y = @strconv.parse_int(y_s)
        m = @strconv.parse_int(m_s)
        matched = true
      }
      // YYYY
      ("[0-9]{4}" as y_s) => {
        y = @strconv.parse_int(y_s)
        matched = true
      }
      _ => ()
    }
  } catch {
    _ => ()
  }
  if not(matched) {
    if (s_str.has_prefix("+") || s_str.has_prefix("-")) && s_str.length() >= 7 {
      try {
        let sign = if s_str.has_prefix("+") { 1 } else { -1 }
        y = @strconv.parse_int(s_str[1:7]) * sign
        matched = true
      } catch {
        _ => ()
      }
    } else if s_str.contains("GMT") || s_str.contains("UTC") {
      match parse_gmt_string(s_str) {
        Some((y_v, m_v, d_v)) => {
          y = y_v
          m = m_v
          d = d_v
          matched = true
        }
        None => ()
      }
    } else if s_str == "0" {
      return Some(0.0)
    }
  }
  if matched {
    try {
      let zdt = @time.date_time(
        y,
        m,
        d,
        hour=h,
        minute=min,
        second=sec,
        nanosecond=ms * 1000000,
        zone=@time.utc_zone,
      )
      let ms_val = zdt.to_unix_second().to_double() * 1000.0 +
        (zdt.nanosecond() / 1000000).to_double()
      if ms_val.abs() <= 8.64e15 {
        Some(ms_val)
      } else {
        None
      }
    } catch {
      _ => None
    }
  } else {
    None
  }
}

///|
pub fn create_date_object(
  object_proto : JSValue,
  func_proto : JSValue,
) -> JSValue {
  let date_proto_props = @hashmap.new()
  let date_proto = JSValue::Object(
    JSObject::new(properties=date_proto_props, prototype=object_proto),
  )
  let date_ctor_fn = Native(fn(ctx, this_val, args) raise EvalError {
    let now_nanos = @env.now()
    let now_seconds = (now_nanos / 1_000_000_000).reinterpret_as_int64()
    let is_constructor_call = match this_val {
      Object(_) => true
      _ => false
    }
    if is_constructor_call {
      let zdt_opt = if args.length() == 0 {
        Some(@time.unix(now_seconds, zone=@time.utc_zone)) catch {
          _ => None
        }
      } else if args.length() == 1 {
        match args[0] {
          Number(n) =>
            if n.is_nan() || n.is_inf() || n.abs() > 8.64e15 {
              None
            } else {
              try {
                let s = (n / 1000.0).floor().to_int64()
                let ms_rem = n - s.to_double() * 1000.0
                let zdt = @time.unix(
                  s,
                  nanosecond=(ms_rem * 1000000.0).round().to_int(),
                  zone=@time.utc_zone,
                )
                if (zdt.to_unix_second().to_double() * 1000.0).abs() <= 8.64e15 {
                  Some(zdt)
                } else {
                  None
                }
              } catch {
                _ => None
              }
            }
          String(s) =>
            match parse_date_string(ctx, s.to_string()) {
              Some(ms) => {
                let s = (ms / 1000.0).floor().to_int64()
                let ms_rem = ((ms - s.to_double() * 1000.0) * 1000000.0)
                  .round()
                  .to_int()
                Some(@time.unix(s, nanosecond=ms_rem, zone=@time.utc_zone)) catch {
                  _ => None
                }
              }
              None => None
            }
          Object(_) | Function(_) =>
            match args[0].get_property("__internal_date__") {
              Internal(Date(zdt)) => Some(zdt)
              _ => {
                let v = to_primitive(ctx, args[0])
                if v is String(s) {
                  match parse_date_string(ctx, s.to_string()) {
                    Some(ms) => {
                      let s = (ms / 1000.0).floor().to_int64()
                      let ms_rem = ((ms - s.to_double() * 1000.0) * 1000000.0)
                        .round()
                        .to_int()
                      Some(
                        @time.unix(s, nanosecond=ms_rem, zone=@time.utc_zone),
                      ) catch {
                        _ => None
                      }
                    }
                    None => None
                  }
                } else {
                  let n = js_to_number(ctx, v)
                  if n.is_nan() || n.is_inf() || n.abs() > 8.64e15 {
                    None
                  } else {
                    try {
                      let s = (n / 1000.0).floor().to_int64()
                      let ms_rem = n - s.to_double() * 1000.0
                      Some(
                        @time.unix(
                          s,
                          nanosecond=(ms_rem * 1000000.0).round().to_int(),
                          zone=@time.utc_zone,
                        ),
                      )
                    } catch {
                      _ => None
                    }
                  }
                }
              }
            }
          _ => {
            let n = js_to_number(ctx, args[0])
            if n.is_nan() || n.is_inf() || n.abs() > 8.64e15 {
              None
            } else {
              try {
                let s = (n / 1000.0).floor().to_int64()
                let ms_rem = n - s.to_double() * 1000.0
                Some(
                  @time.unix(
                    s,
                    nanosecond=(ms_rem * 1000000.0).round().to_int(),
                    zone=@time.utc_zone,
                  ),
                )
              } catch {
                _ => None
              }
            }
          }
        }
      } else {
        let nums = []
        for arg in args {
          nums.push(js_to_number(ctx, arg))
        }
        let y_val = nums[0].to_int()
        let y = if y_val >= 0 && y_val <= 99 { 1900 + y_val } else { y_val }
        let m = nums[1].to_int()
        let d = if nums.length() > 2 { nums[2].to_int() } else { 1 }
        let h = if nums.length() > 3 { nums[3].to_int() } else { 0 }
        let min = if nums.length() > 4 { nums[4].to_int() } else { 0 }
        let sec = if nums.length() > 5 { nums[5].to_int() } else { 0 }
        let ms = if nums.length() > 6 { nums[6].to_int() } else { 0 }
        let zdt_raw_opt = Some(
          @time.date_time(
            y,
            m + 1,
            d,
            hour=h,
            minute=min,
            second=sec,
            nanosecond=ms * 1000000,
            zone=@time.utc_zone,
          ),
        ) catch {
          _ => None
        }
        match zdt_raw_opt {
          Some(zdt) => {
            let ms_val = zdt.to_unix_second().to_double() * 1000.0 +
              (zdt.nanosecond() / 1000000).to_double()
            if ms_val.abs() <= 8.64e15 {
              Some(zdt)
            } else {
              None
            }
          }
          None => None
        }
      }
      match this_val {
        Object({ properties, .. }) => {
          match zdt_opt {
            Some(zdt) =>
              properties["__internal_date__"] = JSValue::Internal(
                JSInternal::Date(zdt),
              )
            None => ()
          }
          this_val
        }
        _ => JSValue::Undefined
      }
    } else {
      try {
        let zdt = @time.unix(now_seconds, zone=@time.utc_zone)
        JSValue::String(format_to_string(zdt))
      } catch {
        _ => JSValue::String("Invalid Date")
      }
    }
  })
  let date_ctor_props = @hashmap.new()
  let date_ctor = JSFunction::new(
    name="Date",
    params=["year", "month", "date", "hours", "minutes", "seconds", "ms"],
    body=date_ctor_fn,
    properties=date_ctor_props,
    prototype=func_proto,
    is_constructor=true,
  )
  let date_ctor_val = JSValue::Function(date_ctor)
  date_ctor_props.set("prototype", date_proto)
  date_proto_props.set("constructor", date_ctor_val)
  let define_property = fn(
    obj : JSObject,
    name : String,
    value : JSValue,
    _enumerable : Bool,
  ) {
    obj.properties.set(name, value)
  }
  let define_method = fn(
    name : String,
    body : (Context, JSValue, Array[JSValue]) -> JSValue raise EvalError,
  ) {
    let f = JSFunction::new(name~, body=Native(body))
    match date_proto {
      Object(obj) => define_property(obj, name, JSValue::Function(f), false)
      _ => ()
    }
  }
  let define_static = fn(
    name : String,
    body : (Context, JSValue, Array[JSValue]) -> JSValue raise EvalError,
    len : Int,
  ) {
    let f = JSFunction::new(name~, body=Native(body))
    f.base.properties.set("length", JSValue::Number(len.to_double()))
    date_ctor_props.set(name, JSValue::Function(f))
  }
  define_static(
    "now",
    fn(_ctx, _this, _args) {
      JSValue::Number((@env.now() / 1_000_000).to_double())
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
        Some(ms) => JSValue::Number(ms)
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
      for arg in args {
        nums.push(js_to_number(ctx, arg))
      }
      let y_v = nums[0].to_int()
      let y = if y_v >= 0 && y_v <= 99 { 1900 + y_v } else { y_v }
      let m = nums[1].to_int() + 1
      let d = if nums.length() > 2 { nums[2].to_int() } else { 1 }
      let h = if nums.length() > 3 { nums[3].to_int() } else { 0 }
      let min = if nums.length() > 4 { nums[4].to_int() } else { 0 }
      let sec = if nums.length() > 5 { nums[5].to_int() } else { 0 }
      let ms = if nums.length() > 6 { nums[6].to_int() } else { 0 }
      try {
        let zdt = @time.date_time(
          y,
          m,
          d,
          hour=h,
          minute=min,
          second=sec,
          nanosecond=ms * 1000000,
          zone=@time.utc_zone,
        )
        let ms_val = zdt.to_unix_second().to_double() * 1000.0 +
          (zdt.nanosecond() / 1000000).to_double()
        if ms_val.abs() <= 8.64e15 {
          JSValue::Number(ms_val)
        } else {
          JSValue::Number(@double.not_a_number)
        }
      } catch {
        _ => JSValue::Number(@double.not_a_number)
      }
    },
    7,
  )
  let set_zdt = fn(
    ctx : Context,
    this_val : JSValue,
    f : (@time.ZonedDateTime) -> @time.ZonedDateTime? raise EvalError,
  ) -> JSValue raise EvalError {
    match this_val {
      Object({ properties, .. }) =>
        match properties.get("__internal_date__") {
          Some(Internal(Date(zdt))) =>
            match f(zdt) {
              Some(new_zdt) => {
                let ms_val = new_zdt.to_unix_second().to_double() * 1000.0 +
                  (new_zdt.nanosecond() / 1000000).to_double()
                if ms_val.abs() <= 8.64e15 {
                  properties["__internal_date__"] = Internal(Date(new_zdt))
                  JSValue::Number(ms_val)
                } else {
                  properties.remove("__internal_date__")
                  JSValue::Number(@double.not_a_number)
                }
              }
              None => {
                properties.remove("__internal_date__")
                JSValue::Number(@double.not_a_number)
              }
            }
          _ => JSValue::Number(@double.not_a_number)
        }
      _ => ctx.throw_type_error("Method called on non-Date object")
    }
  }
  let define_setter = fn(
    name : String,
    body : (Context, @time.ZonedDateTime, Array[JSValue]) -> @time.ZonedDateTime? raise EvalError,
  ) {
    define_method(name, fn(ctx, this_val, args) raise EvalError {
      set_zdt(ctx, this_val, fn(zdt) raise EvalError { body(ctx, zdt, args) })
    })
  }
  define_setter("setFullYear", fn(ctx, zdt, args) raise EvalError {
    if args.length() == 0 {
      return None
    }
    let y = js_to_number(ctx, args[0]).to_int()
    let m = if args.length() > 1 {
      js_to_number(ctx, args[1]).to_int() + 1
    } else {
      zdt.month()
    }
    let d = if args.length() > 2 {
      js_to_number(ctx, args[2]).to_int()
    } else {
      zdt.day()
    }
    Some(
      @time.date_time(
        y,
        m,
        d,
        hour=zdt.hour(),
        minute=zdt.minute(),
        second=zdt.second(),
        nanosecond=zdt.nanosecond(),
        zone=zdt.zone(),
      ),
    ) catch {
      _ => None
    }
  })
  define_setter("setUTCFullYear", fn(ctx, zdt, args) raise EvalError {
    if args.length() == 0 {
      return None
    }
    let y = js_to_number(ctx, args[0]).to_int()
    let m = if args.length() > 1 {
      js_to_number(ctx, args[1]).to_int() + 1
    } else {
      zdt.month()
    }
    let d = if args.length() > 2 {
      js_to_number(ctx, args[2]).to_int()
    } else {
      zdt.day()
    }
    Some(
      @time.date_time(
        y,
        m,
        d,
        hour=zdt.hour(),
        minute=zdt.minute(),
        second=zdt.second(),
        nanosecond=zdt.nanosecond(),
        zone=@time.utc_zone,
      ),
    ) catch {
      _ => None
    }
  })
  define_setter("setMonth", fn(ctx, zdt, args) raise EvalError {
    if args.length() == 0 {
      return None
    }
    let m = js_to_number(ctx, args[0]).to_int() + 1
    let d = if args.length() > 1 {
      js_to_number(ctx, args[1]).to_int()
    } else {
      zdt.day()
    }
    Some(
      @time.date_time(
        zdt.year(),
        m,
        d,
        hour=zdt.hour(),
        minute=zdt.minute(),
        second=zdt.second(),
        nanosecond=zdt.nanosecond(),
        zone=zdt.zone(),
      ),
    ) catch {
      _ => None
    }
  })
  define_setter("setUTCMonth", fn(ctx, zdt, args) raise EvalError {
    if args.length() == 0 {
      return None
    }
    let m = js_to_number(ctx, args[0]).to_int() + 1
    let d = if args.length() > 1 {
      js_to_number(ctx, args[1]).to_int()
    } else {
      zdt.day()
    }
    Some(
      @time.date_time(
        zdt.year(),
        m,
        d,
        hour=zdt.hour(),
        minute=zdt.minute(),
        second=zdt.second(),
        nanosecond=zdt.nanosecond(),
        zone=@time.utc_zone,
      ),
    ) catch {
      _ => None
    }
  })
  define_setter("setDate", fn(ctx, zdt, args) raise EvalError {
    if args.length() == 0 {
      return None
    }
    let d = js_to_number(ctx, args[0]).to_int()
    Some(
      @time.date_time(
        zdt.year(),
        zdt.month(),
        d,
        hour=zdt.hour(),
        minute=zdt.minute(),
        second=zdt.second(),
        nanosecond=zdt.nanosecond(),
        zone=zdt.zone(),
      ),
    ) catch {
      _ => None
    }
  })
  define_setter("setUTCDate", fn(ctx, zdt, args) raise EvalError {
    if args.length() == 0 {
      return None
    }
    let d = js_to_number(ctx, args[0]).to_int()
    Some(
      @time.date_time(
        zdt.year(),
        zdt.month(),
        d,
        hour=zdt.hour(),
        minute=zdt.minute(),
        second=zdt.second(),
        nanosecond=zdt.nanosecond(),
        zone=@time.utc_zone,
      ),
    ) catch {
      _ => None
    }
  })
  define_setter("setHours", fn(ctx, zdt, args) raise EvalError {
    if args.length() == 0 {
      return None
    }
    let h = js_to_number(ctx, args[0]).to_int()
    let min = if args.length() > 1 {
      js_to_number(ctx, args[1]).to_int()
    } else {
      zdt.minute()
    }
    let sec = if args.length() > 2 {
      js_to_number(ctx, args[2]).to_int()
    } else {
      zdt.second()
    }
    let ms = if args.length() > 3 {
      js_to_number(ctx, args[3]).to_int()
    } else {
      zdt.nanosecond() / 1000000
    }
    Some(
      @time.date_time(
        zdt.year(),
        zdt.month(),
        zdt.day(),
        hour=h,
        minute=min,
        second=sec,
        nanosecond=ms * 1000000,
        zone=zdt.zone(),
      ),
    ) catch {
      _ => None
    }
  })
  define_setter("setUTCHours", fn(ctx, zdt, args) raise EvalError {
    if args.length() == 0 {
      return None
    }
    let h = js_to_number(ctx, args[0]).to_int()
    let min = if args.length() > 1 {
      js_to_number(ctx, args[1]).to_int()
    } else {
      zdt.minute()
    }
    let sec = if args.length() > 2 {
      js_to_number(ctx, args[2]).to_int()
    } else {
      zdt.second()
    }
    let ms = if args.length() > 3 {
      js_to_number(ctx, args[3]).to_int()
    } else {
      zdt.nanosecond() / 1000000
    }
    Some(
      @time.date_time(
        zdt.year(),
        zdt.month(),
        zdt.day(),
        hour=h,
        minute=min,
        second=sec,
        nanosecond=ms * 1000000,
        zone=@time.utc_zone,
      ),
    ) catch {
      _ => None
    }
  })
  define_setter("setMinutes", fn(ctx, zdt, args) raise EvalError {
    if args.length() == 0 {
      return None
    }
    let min = js_to_number(ctx, args[0]).to_int()
    let sec = if args.length() > 1 {
      js_to_number(ctx, args[1]).to_int()
    } else {
      zdt.second()
    }
    let ms = if args.length() > 2 {
      js_to_number(ctx, args[2]).to_int()
    } else {
      zdt.nanosecond() / 1000000
    }
    Some(
      @time.date_time(
        zdt.year(),
        zdt.month(),
        zdt.day(),
        hour=zdt.hour(),
        minute=min,
        second=sec,
        nanosecond=ms * 1000000,
        zone=zdt.zone(),
      ),
    ) catch {
      _ => None
    }
  })
  define_setter("setUTCMinutes", fn(ctx, zdt, args) raise EvalError {
    if args.length() == 0 {
      return None
    }
    let min = js_to_number(ctx, args[0]).to_int()
    let sec = if args.length() > 1 {
      js_to_number(ctx, args[1]).to_int()
    } else {
      zdt.second()
    }
    let ms = if args.length() > 2 {
      js_to_number(ctx, args[2]).to_int()
    } else {
      zdt.nanosecond() / 1000000
    }
    Some(
      @time.date_time(
        zdt.year(),
        zdt.month(),
        zdt.day(),
        hour=zdt.hour(),
        minute=min,
        second=sec,
        nanosecond=ms * 1000000,
        zone=@time.utc_zone,
      ),
    ) catch {
      _ => None
    }
  })
  define_setter("setSeconds", fn(ctx, zdt, args) raise EvalError {
    if args.length() == 0 {
      return None
    }
    let sec = js_to_number(ctx, args[0]).to_int()
    let ms = if args.length() > 1 {
      js_to_number(ctx, args[1]).to_int()
    } else {
      zdt.nanosecond() / 1000000
    }
    Some(
      @time.date_time(
        zdt.year(),
        zdt.month(),
        zdt.day(),
        hour=zdt.hour(),
        minute=zdt.minute(),
        second=sec,
        nanosecond=ms * 1000000,
        zone=zdt.zone(),
      ),
    ) catch {
      _ => None
    }
  })
  define_setter("setUTCSeconds", fn(ctx, zdt, args) raise EvalError {
    if args.length() == 0 {
      return None
    }
    let sec = js_to_number(ctx, args[0]).to_int()
    let ms = if args.length() > 1 {
      js_to_number(ctx, args[1]).to_int()
    } else {
      zdt.nanosecond() / 1000000
    }
    Some(
      @time.date_time(
        zdt.year(),
        zdt.month(),
        zdt.day(),
        hour=zdt.hour(),
        minute=zdt.minute(),
        second=sec,
        nanosecond=ms * 1000000,
        zone=@time.utc_zone,
      ),
    ) catch {
      _ => None
    }
  })
  define_setter("setMilliseconds", fn(ctx, zdt, args) raise EvalError {
    if args.length() == 0 {
      return None
    }
    let ms = js_to_number(ctx, args[0]).to_int()
    Some(
      @time.date_time(
        zdt.year(),
        zdt.month(),
        zdt.day(),
        hour=zdt.hour(),
        minute=zdt.minute(),
        second=zdt.second(),
        nanosecond=ms * 1000000,
        zone=zdt.zone(),
      ),
    ) catch {
      _ => None
    }
  })
  define_setter("setUTCMilliseconds", fn(ctx, zdt, args) raise EvalError {
    if args.length() == 0 {
      return None
    }
    let ms = js_to_number(ctx, args[0]).to_int()
    Some(
      @time.date_time(
        zdt.year(),
        zdt.month(),
        zdt.day(),
        hour=zdt.hour(),
        minute=zdt.minute(),
        second=zdt.second(),
        nanosecond=ms * 1000000,
        zone=@time.utc_zone,
      ),
    ) catch {
      _ => None
    }
  })
  define_setter("setTime", fn(ctx, _zdt, args) raise EvalError {
    if args.length() == 0 {
      return None
    }
    let n = js_to_number(ctx, args[0])
    if n.is_nan() || n.is_inf() || n.abs() > 8.64e15 {
      return None
    }
    try {
      let s = (n / 1000.0).floor().to_int64()
      let ms_rem = n - s.to_double() * 1000.0
      Some(
        @time.unix(
          s,
          nanosecond=(ms_rem * 1000000.0).round().to_int(),
          zone=@time.utc_zone,
        ),
      )
    } catch {
      _ => None
    }
  })
  define_setter("setYear", fn(ctx, zdt, args) raise EvalError {
    if args.length() == 0 {
      return None
    }
    let y_v = js_to_number(ctx, args[0]).to_int()
    let y = if y_v >= 0 && y_v <= 99 { 1900 + y_v } else { y_v }
    Some(
      @time.date_time(
        y,
        zdt.month(),
        zdt.day(),
        hour=zdt.hour(),
        minute=zdt.minute(),
        second=zdt.second(),
        nanosecond=zdt.nanosecond(),
        zone=zdt.zone(),
      ),
    ) catch {
      _ => None
    }
  })
  define_method("getUTCFullYear", fn(_ctx, this_val, _args) {
    match this_val {
      Object({ properties, .. }) =>
        match properties.get("__internal_date__") {
          Some(Internal(Date(zdt))) => JSValue::Number(zdt.year().to_double())
          _ => JSValue::Number(@double.not_a_number)
        }
      _ => JSValue::Number(@double.not_a_number)
    }
  })
  define_method("getUTCMonth", fn(_ctx, this_val, _args) {
    match this_val {
      Object({ properties, .. }) =>
        match properties.get("__internal_date__") {
          Some(Internal(Date(zdt))) =>
            JSValue::Number((zdt.month() - 1).to_double())
          _ => JSValue::Number(@double.not_a_number)
        }
      _ => JSValue::Number(@double.not_a_number)
    }
  })
  define_method("getUTCDate", fn(_ctx, this_val, _args) {
    match this_val {
      Object({ properties, .. }) =>
        match properties.get("__internal_date__") {
          Some(Internal(Date(zdt))) => JSValue::Number(zdt.day().to_double())
          _ => JSValue::Number(@double.not_a_number)
        }
      _ => JSValue::Number(@double.not_a_number)
    }
  })
  define_method("getUTCHours", fn(_ctx, this_val, _args) {
    match this_val {
      Object({ properties, .. }) =>
        match properties.get("__internal_date__") {
          Some(Internal(Date(zdt))) => JSValue::Number(zdt.hour().to_double())
          _ => JSValue::Number(@double.not_a_number)
        }
      _ => JSValue::Number(@double.not_a_number)
    }
  })
  define_method("getUTCMinutes", fn(_ctx, this_val, _args) {
    match this_val {
      Object({ properties, .. }) =>
        match properties.get("__internal_date__") {
          Some(Internal(Date(zdt))) => JSValue::Number(zdt.minute().to_double())
          _ => JSValue::Number(@double.not_a_number)
        }
      _ => JSValue::Number(@double.not_a_number)
    }
  })
  define_method("getUTCSeconds", fn(_ctx, this_val, _args) {
    match this_val {
      Object({ properties, .. }) =>
        match properties.get("__internal_date__") {
          Some(Internal(Date(zdt))) => JSValue::Number(zdt.second().to_double())
          _ => JSValue::Number(@double.not_a_number)
        }
      _ => JSValue::Number(@double.not_a_number)
    }
  })
  define_method("getUTCMilliseconds", fn(_ctx, this_val, _args) {
    match this_val {
      Object({ properties, .. }) =>
        match properties.get("__internal_date__") {
          Some(Internal(Date(zdt))) =>
            JSValue::Number((zdt.nanosecond() / 1000000).to_double())
          _ => JSValue::Number(@double.not_a_number)
        }
      _ => JSValue::Number(@double.not_a_number)
    }
  })
  define_method("getUTCDay", fn(_ctx, this_val, _args) {
    match this_val {
      Object({ properties, .. }) =>
        match properties.get("__internal_date__") {
          Some(Internal(Date(zdt))) => {
            let wd = match zdt.weekday() {
              @time.Monday => 1
              @time.Tuesday => 2
              @time.Wednesday => 3
              @time.Thursday => 4
              @time.Friday => 5
              @time.Saturday => 6
              @time.Sunday => 0
            }
            JSValue::Number(wd.to_double())
          }
          _ => JSValue::Number(@double.not_a_number)
        }
      _ => JSValue::Number(@double.not_a_number)
    }
  })
  define_method("getFullYear", fn(_ctx, this_val, _args) {
    match this_val {
      Object({ properties, .. }) =>
        match properties.get("__internal_date__") {
          Some(Internal(Date(zdt))) => JSValue::Number(zdt.year().to_double())
          _ => JSValue::Number(@double.not_a_number)
        }
      _ => JSValue::Number(@double.not_a_number)
    }
  })
  define_method("getMonth", fn(_ctx, this_val, _args) {
    match this_val {
      Object({ properties, .. }) =>
        match properties.get("__internal_date__") {
          Some(Internal(Date(zdt))) =>
            JSValue::Number((zdt.month() - 1).to_double())
          _ => JSValue::Number(@double.not_a_number)
        }
      _ => JSValue::Number(@double.not_a_number)
    }
  })
  define_method("getDate", fn(_ctx, this_val, _args) {
    match this_val {
      Object({ properties, .. }) =>
        match properties.get("__internal_date__") {
          Some(Internal(Date(zdt))) => JSValue::Number(zdt.day().to_double())
          _ => JSValue::Number(@double.not_a_number)
        }
      _ => JSValue::Number(@double.not_a_number)
    }
  })
  define_method("getHours", fn(_ctx, this_val, _args) {
    match this_val {
      Object({ properties, .. }) =>
        match properties.get("__internal_date__") {
          Some(Internal(Date(zdt))) => JSValue::Number(zdt.hour().to_double())
          _ => JSValue::Number(@double.not_a_number)
        }
      _ => JSValue::Number(@double.not_a_number)
    }
  })
  define_method("getMinutes", fn(_ctx, this_val, _args) {
    match this_val {
      Object({ properties, .. }) =>
        match properties.get("__internal_date__") {
          Some(Internal(Date(zdt))) => JSValue::Number(zdt.minute().to_double())
          _ => JSValue::Number(@double.not_a_number)
        }
      _ => JSValue::Number(@double.not_a_number)
    }
  })
  define_method("getSeconds", fn(_ctx, this_val, _args) {
    match this_val {
      Object({ properties, .. }) =>
        match properties.get("__internal_date__") {
          Some(Internal(Date(zdt))) => JSValue::Number(zdt.second().to_double())
          _ => JSValue::Number(@double.not_a_number)
        }
      _ => JSValue::Number(@double.not_a_number)
    }
  })
  define_method("getMilliseconds", fn(_ctx, this_val, _args) {
    match this_val {
      Object({ properties, .. }) =>
        match properties.get("__internal_date__") {
          Some(Internal(Date(zdt))) =>
            JSValue::Number((zdt.nanosecond() / 1000000).to_double())
          _ => JSValue::Number(@double.not_a_number)
        }
      _ => JSValue::Number(@double.not_a_number)
    }
  })
  define_method("getDay", fn(_ctx, this_val, _args) {
    match this_val {
      Object({ properties, .. }) =>
        match properties.get("__internal_date__") {
          Some(Internal(Date(zdt))) => {
            let wd = match zdt.weekday() {
              @time.Monday => 1
              @time.Tuesday => 2
              @time.Wednesday => 3
              @time.Thursday => 4
              @time.Friday => 5
              @time.Saturday => 6
              @time.Sunday => 0
            }
            JSValue::Number(wd.to_double())
          }
          _ => JSValue::Number(@double.not_a_number)
        }
      _ => JSValue::Number(@double.not_a_number)
    }
  })
  define_method("getYear", fn(_ctx, this_val, _args) {
    match this_val {
      Object({ properties, .. }) =>
        match properties.get("__internal_date__") {
          Some(Internal(Date(zdt))) =>
            JSValue::Number((zdt.year() - 1900).to_double())
          _ => JSValue::Number(@double.not_a_number)
        }
      _ => JSValue::Number(@double.not_a_number)
    }
  })
  define_method("getTime", fn(_ctx, this_val, _args) {
    match this_val {
      Object({ properties, .. }) =>
        match properties.get("__internal_date__") {
          Some(Internal(Date(zdt))) =>
            JSValue::Number(
              zdt.to_unix_second().to_double() * 1000.0 +
              (zdt.nanosecond() / 1000000).to_double(),
            )
          _ => JSValue::Number(@double.not_a_number)
        }
      _ => JSValue::Number(@double.not_a_number)
    }
  })
  define_method("valueOf", fn(_ctx, this_val, _args) {
    match this_val {
      Object({ properties, .. }) =>
        match properties.get("__internal_date__") {
          Some(Internal(Date(zdt))) =>
            JSValue::Number(
              zdt.to_unix_second().to_double() * 1000.0 +
              (zdt.nanosecond() / 1000000).to_double(),
            )
          _ => JSValue::Number(@double.not_a_number)
        }
      _ => JSValue::Number(@double.not_a_number)
    }
  })
  define_method("toString", fn(_ctx, this_val, _args) {
    match this_val {
      Object({ properties, .. }) =>
        match properties.get("__internal_date__") {
          Some(Internal(Date(zdt))) => JSValue::String(format_to_string(zdt))
          _ => JSValue::String("Invalid Date")
        }
      _ => JSValue::String("Invalid Date")
    }
  })
  define_method("toDateString", fn(_ctx, this_val, _args) {
    match this_val {
      Object({ properties, .. }) =>
        match properties.get("__internal_date__") {
          Some(Internal(Date(zdt))) => {
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
            JSValue::String("\{wd} \{m} \{pad2(zdt.day())} \{zdt.year()}")
          }
          _ => JSValue::String("Invalid Date")
        }
      _ => JSValue::String("Invalid Date")
    }
  })
  define_method("toTimeString", fn(_ctx, this_val, _args) {
    match this_val {
      Object({ properties, .. }) =>
        match properties.get("__internal_date__") {
          Some(Internal(Date(zdt))) =>
            JSValue::String(
              "\{pad2(zdt.hour())}:\{pad2(zdt.minute())}:\{pad2(zdt.second())} GMT+0000 (Coordinated Universal Time)",
            )
          _ => JSValue::String("Invalid Date")
        }
      _ => JSValue::String("Invalid Date")
    }
  })
  define_method("toISOString", fn(_ctx, this_val, _args) {
    match this_val {
      Object({ properties, .. }) =>
        match properties.get("__internal_date__") {
          Some(Internal(Date(zdt))) => {
            let y = zdt.year()
            let m = pad2(zdt.month())
            let d = pad2(zdt.day())
            let h = pad2(zdt.hour())
            let min = pad2(zdt.minute())
            let sec_v = pad2(zdt.second())
            let ms_v = pad3(zdt.nanosecond() / 1000000)
            if y >= 0 && y <= 9999 {
              JSValue::String(
                "\{pad2(y / 100)}\{pad2(y % 100)}-\{m}-\{d}T\{h}:\{min}:\{sec_v}.\{ms_v}Z",
              )
            } else {
              let sign = if y >= 0 { "+" } else { "-" }
              let mut ys = (if y >= 0 { y } else { -y }).to_string()
              while ys.length() < 6 {
                ys = "0" + ys
              }
              JSValue::String(
                "\{sign}\{ys}-\{m}-\{d}T\{h}:\{min}:\{sec_v}.\{ms_v}Z",
              )
            }
          }
          _ => JSValue::String("Invalid Date")
        }
      _ => JSValue::String("Invalid Date")
    }
  })
  define_method("toJSON", fn(ctx, this_val, args) raise EvalError {
    match this_val.get_property("toISOString") {
      Function(f) => ctx.invoke(f, this_val, args)
      _ => JSValue::String("Invalid Date")
    }
  })
  define_method("toLocaleString", fn(ctx, this_val, args) raise EvalError {
    match this_val.get_property("toString") {
      Function(f) => ctx.invoke(f, this_val, args)
      _ => JSValue::String("Invalid Date")
    }
  })
  define_method("toLocaleDateString", fn(ctx, this_val, args) raise EvalError {
    match this_val.get_property("toDateString") {
      Function(f) => ctx.invoke(f, this_val, args)
      _ => JSValue::String("Invalid Date")
    }
  })
  define_method("toLocaleTimeString", fn(ctx, this_val, args) raise EvalError {
    match this_val.get_property("toTimeString") {
      Function(f) => ctx.invoke(f, this_val, args)
      _ => JSValue::String("Invalid Date")
    }
  })
  date_ctor_val
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
  "\{wd} \{m} \{pad2(zdt.day())} \{zdt.year()} \{pad2(zdt.hour())}:\{pad2(zdt.minute())}:\{pad2(zdt.second())} GMT+0000 (Coordinated Universal Time)"
}

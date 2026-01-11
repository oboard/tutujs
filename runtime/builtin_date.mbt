///|
pub fn create_date_object(object_proto : JSValue) -> JSValue {
  let date_proto_props = @hashmap.new()
  let date_proto = JSValue::Object(
    JSObject::new(properties=date_proto_props, prototype=object_proto),
  )

  // Helpers for formatting
  let week_days = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]
  let months = [
    "Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov",
    "Dec",
  ]
  let pad2 = fn(n : Int) -> String { if n < 10 { "0\{n}" } else { "\{n}" } }
  let pad3 = fn(n : Int) -> String {
    if n < 10 {
      "00\{n}"
    } else if n < 100 {
      "0\{n}"
    } else {
      "\{n}"
    }
  }
  let format_to_string = fn(zdt : @time.ZonedDateTime) -> String {
    let wd_val = zdt.weekday().value()
    let wd = if wd_val == 7 { 0 } else { wd_val }
    let wd_str = week_days[wd]
    let m_str = months[zdt.month() - 1]
    let d = pad2(zdt.day())
    let y = zdt.year()
    let h = pad2(zdt.hour())
    let min = pad2(zdt.minute())
    let s = pad2(zdt.second())
    // Standard JS toString format: "Mon Jan 01 2000 00:00:00 GMT+0000 (UTC)"
    "\{wd_str} \{m_str} \{d} \{y} \{h}:\{min}:\{s} GMT+0000 (UTC)"
  }

  // Date Constructor
  let date_ctor_fn = Native(fn(_ctx, this_val, args) {
    let now_seconds = @env.now().to_int().to_int64()
    let zone = @time.utc_zone
    let is_constructor_call = match this_val {
      Object(_) => true
      _ => false
    }
    if is_constructor_call {
      let zdt_opt = if args is [arg0, ..] {
        match arg0 {
          Number(n) =>
            Some(
              @time.ZonedDateTime::from_unix_second(
                (n / 1000.0).to_int64(),
                zone~,
              ),
            ) catch {
              _ => None
            }
          String(s) =>
            Some(
              @time.ZonedDateTime::from_plain_datetime(
                @time.PlainDateTime::from_string(s.to_string()),
                zone~,
              ),
            ) catch {
              _ => None
            }
          _ =>
            Some(@time.ZonedDateTime::from_unix_second(now_seconds, zone~)) catch {
              _ => None
            }
        }
      } else {
        Some(@time.ZonedDateTime::from_unix_second(now_seconds, zone~)) catch {
          _ => None
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
      // Function call
      let zdt = @time.ZonedDateTime::from_unix_second(now_seconds, zone~) catch {
        _ => return JSValue::String("Invalid Date")
      }
      JSValue::String(format_to_string(zdt))
    }
  })
  // Date.now()
  let now_fn = Native(fn(_ctx, _this, _args) {
    JSValue::Number(@env.now().to_double() * 1000.0)
  })
  let date_ctor_props = @hashmap.new()
  date_ctor_props.set("prototype", date_proto)
  date_ctor_props.set(
    "now",
    JSValue::Function(JSFunction::new(name="now", body=now_fn)),
  )
  let date_ctor = JSFunction::new(
    name="Date",
    body=date_ctor_fn,
    properties=date_ctor_props,
    prototype=object_proto,
    is_constructor=true,
  )
  let date_ctor_val = JSValue::Function(date_ctor)
  date_proto_props.set("constructor", date_ctor_val)

  // Date.prototype.toString()
  let to_string_fn = Native(fn(_ctx, this_val, _args) {
    JSValue::String(
      match this_val {
        Object(
          {
            properties: {
              "__internal_date__": JSValue::Internal(JSInternal::Date(zdt)),
              ..
            },
            ..,
          }
        ) => format_to_string(zdt)
        _ => "Invalid Date"
      },
    )
  })
  date_proto_props.set(
    "toString",
    JSValue::Function(JSFunction::new(name="toString", body=to_string_fn)),
  )

  // Date.prototype.toLocaleString()
  date_proto_props.set(
    "toLocaleString",
    JSValue::Function(JSFunction::new(name="toLocaleString", body=to_string_fn)),
  )

  // Date.prototype.getTime()
  let get_time_fn = Native(fn(_ctx, this_val, _args) {
    JSValue::Number(
      match this_val {
        Object(
          {
            properties: {
              "__internal_date__": JSValue::Internal(JSInternal::Date(zdt)),
              ..
            },
            ..,
          }
        ) => zdt.to_unix_second().to_double() * 1000.0
        _ => @double.not_a_number
      },
    )
  })
  date_proto_props.set(
    "getTime",
    JSValue::Function(JSFunction::new(name="getTime", body=get_time_fn)),
  )

  // Date.prototype.valueOf()
  let value_of_fn = Native(fn(_ctx, this_val, _args) {
    match this_val {
      Object(
        {
          properties: {
            "__internal_date__": JSValue::Internal(JSInternal::Date(zdt)),
            ..
          },
          ..,
        }
      ) => JSValue::Number(zdt.to_unix_second().to_double() * 1000.0)
      _ => JSValue::Number(@double.not_a_number)
    }
  })
  date_proto_props.set(
    "valueOf",
    JSValue::Function(JSFunction::new(name="valueOf", body=value_of_fn)),
  )

  // Date.prototype.setTime(time)
  let set_time_fn = Native(fn(_ctx, this_val, args) {
    JSValue::Number(
      if args is [Number(n), ..] {
        let time = n
        match this_val {
          Object({ properties, .. }) => {
            let zdt_opt = Some(
              @time.ZonedDateTime::from_unix_second(
                (time / 1000.0).to_int64(),
                zone=@time.utc_zone,
              ),
            ) catch {
              _ => None
            }
            match zdt_opt {
              Some(zdt) => {
                properties["__internal_date__"] = JSValue::Internal(
                  JSInternal::Date(zdt),
                )
                time
              }
              None => @double.not_a_number
            }
          }
          _ => @double.not_a_number
        }
      } else {
        @double.not_a_number
      },
    )
  })
  date_proto_props.set(
    "setTime",
    JSValue::Function(JSFunction::new(name="setTime", body=set_time_fn)),
  )

  // Date.UTC
  let utc_fn = Native(fn(_ctx, _this, args) {
    match args {
      [y_arg, m_arg, .. rest] => {
        let y = match y_arg {
          Number(n) => n.to_int()
          _ => 0
        }
        let m = match m_arg {
          Number(n) => n.to_int()
          _ => 0
        }
        let d = match rest {
          [d_arg, ..] =>
            match d_arg {
              Number(n) => n.to_int()
              _ => 1
            }
          _ => 1
        }
        let h = match rest {
          [_, h_arg, ..] =>
            match h_arg {
              Number(n) => n.to_int()
              _ => 0
            }
          _ => 0
        }
        let min = match rest {
          [_, _, min_arg, ..] =>
            match min_arg {
              Number(n) => n.to_int()
              _ => 0
            }
          _ => 0
        }
        let s = match rest {
          [_, _, _, s_arg, ..] =>
            match s_arg {
              Number(n) => n.to_int()
              _ => 0
            }
          _ => 0
        }
        let ms = match rest {
          [_, _, _, _, ms_arg, ..] =>
            match ms_arg {
              Number(n) => n.to_int()
              _ => 0
            }
          _ => 0
        }

        // MoonBit time uses 1-based month
        let zdt = @time.date_time(
          y,
          m + 1,
          d,
          hour=h,
          minute=min,
          second=s,
          nanosecond=ms * 1000000,
          zone=@time.utc_zone,
        ) catch {
          _ => return JSValue::Number(@double.not_a_number)
        }
        JSValue::Number(zdt.to_unix_second().to_double() * 1000.0)
      }
      _ => JSValue::Number(@double.not_a_number)
    }
  })
  date_ctor["UTC"] = JSValue::Function(JSFunction::new(name="UTC", body=utc_fn))

  // Date.parse (minimal implementation)
  let parse_fn = Native(fn(_ctx, _this, args) {
    if args is [JSValue::String(s), ..] {
      try {
        let pdt = @time.PlainDateTime::from_string(s.to_string())
        let zdt = @time.ZonedDateTime::from_plain_datetime(
          pdt,
          zone=@time.utc_zone,
        )
        let unix_seconds = zdt.to_unix_second()
        JSValue::Number(unix_seconds.to_double() * 1000.0)
      } catch {
        _ => JSValue::Number(@double.not_a_number)
      }
    } else {
      JSValue::Number(@double.not_a_number)
    }
  })
  date_ctor["parse"] = JSValue::Function(
    JSFunction::new(name="parse", body=parse_fn),
  )

  // Getters
  let make_getter = fn(
    name : String,
    extractor : (@time.ZonedDateTime) -> Double,
  ) {
    let func = Native(fn(_ctx, this_val, _args) {
      JSValue::Number(
        match this_val {
          Object(
            {
              properties: {
                "__internal_date__": JSValue::Internal(JSInternal::Date(zdt)),
                ..
              },
              ..,
            }
          ) => extractor(zdt)
          _ => @double.not_a_number
        },
      )
    })
    date_proto_props.set(
      name,
      JSValue::Function(JSFunction::new(name~, body=func)),
    )
  }
  make_getter("getUTCFullYear", zdt => zdt.year().to_double())
  make_getter("getUTCMonth", zdt => (zdt.month() - 1).to_double())
  make_getter("getUTCDate", zdt => zdt.day().to_double())
  make_getter("getUTCHours", zdt => zdt.hour().to_double())
  make_getter("getUTCMinutes", zdt => zdt.minute().to_double())
  make_getter("getUTCSeconds", zdt => zdt.second().to_double())
  make_getter("getUTCMilliseconds", zdt => (zdt.nanosecond() / 1000000).to_double())
  make_getter("getUTCDay", fn(zdt) {
    let wd = zdt.weekday().value()
    if wd == 7 {
      0.0
    } else {
      wd.to_double()
    }
  })

  // Local Getters (Assume Local = UTC)
  make_getter("getFullYear", zdt => zdt.year().to_double())
  make_getter("getMonth", zdt => (zdt.month() - 1).to_double())
  make_getter("getDate", zdt => zdt.day().to_double())
  make_getter("getHours", zdt => zdt.hour().to_double())
  make_getter("getMinutes", zdt => zdt.minute().to_double())
  make_getter("getSeconds", zdt => zdt.second().to_double())
  make_getter("getMilliseconds", zdt => (zdt.nanosecond() / 1000000).to_double())
  make_getter("getDay", fn(zdt) {
    let wd = zdt.weekday().value()
    if wd == 7 {
      0.0
    } else {
      wd.to_double()
    }
  })
  make_getter("getYear", zdt => (zdt.year() - 1900).to_double())

  // Date.prototype.getTimezoneOffset()
  let get_timezone_offset_fn = Native(fn(_ctx, _this, _args) {
    JSValue::Number(0.0)
  })
  date_proto_props.set(
    "getTimezoneOffset",
    JSValue::Function(
      JSFunction::new(name="getTimezoneOffset", body=get_timezone_offset_fn),
    ),
  )

  // String Helper Functions (Moved to top)

  // Date.prototype.toISOString()
  let to_iso_string_fn = Native(fn(_ctx, this_val, _args) {
    JSValue::String(
      match this_val {
        Object(
          {
            properties: {
              "__internal_date__": JSValue::Internal(JSInternal::Date(zdt)),
              ..
            },
            ..,
          }
        ) => {
          let y = zdt.year()
          let m = pad2(zdt.month())
          let d = pad2(zdt.day())
          let h = pad2(zdt.hour())
          let min = pad2(zdt.minute())
          let s = pad2(zdt.second())
          let ms = pad3(zdt.nanosecond() / 1000000)
          "\{y}-\{m}-\{d}T\{h}:\{min}:\{s}.\{ms}Z"
        }
        _ => "Invalid Date"
      },
    )
  })
  date_proto_props.set(
    "toISOString",
    JSValue::Function(
      JSFunction::new(name="toISOString", body=to_iso_string_fn),
    ),
  )

  // Date.prototype.toJSON()
  date_proto_props.set(
    "toJSON",
    JSValue::Function(JSFunction::new(name="toJSON", body=to_iso_string_fn)),
  )

  // Date.prototype.toUTCString()
  // week_days and months moved to top
  let to_utc_string_fn = Native(fn(_ctx, this_val, _args) {
    match this_val {
      Object(
        {
          properties: {
            "__internal_date__": JSValue::Internal(JSInternal::Date(zdt)),
            ..
          },
          ..,
        }
      ) => {
        let wd_val = zdt.weekday().value()
        let wd = if wd_val == 7 { 0 } else { wd_val }
        let wd_str = week_days[wd]
        let d = pad2(zdt.day())
        let m_str = months[zdt.month() - 1]
        let y = zdt.year()
        let h = pad2(zdt.hour())
        let min = pad2(zdt.minute())
        let s = pad2(zdt.second())
        // RFC 1123: "Tue, 02 Jan 2018 00:00:00 GMT"
        JSValue::String("\{wd_str}, \{d} \{m_str} \{y} \{h}:\{min}:\{s} GMT")
      }
      _ => JSValue::String("Invalid Date")
    }
  })
  date_proto_props.set(
    "toUTCString",
    JSValue::Function(
      JSFunction::new(name="toUTCString", body=to_utc_string_fn),
    ),
  )

  // Date.prototype.toDateString()
  let to_date_string_fn = Native(fn(_ctx, this_val, _args) {
    match this_val {
      Object(
        {
          properties: {
            "__internal_date__": JSValue::Internal(JSInternal::Date(zdt)),
            ..
          },
          ..,
        }
      ) => {
        let wd_val = zdt.weekday().value()
        let wd = if wd_val == 7 { 0 } else { wd_val }
        let wd_str = week_days[wd]
        let m_str = months[zdt.month() - 1]
        let d = pad2(zdt.day())
        let y = zdt.year()
        // "Mon Jan 01 2000"
        JSValue::String("\{wd_str} \{m_str} \{d} \{y}")
      }
      _ => JSValue::String("Invalid Date")
    }
  })
  date_proto_props.set(
    "toDateString",
    JSValue::Function(
      JSFunction::new(name="toDateString", body=to_date_string_fn),
    ),
  )
  date_proto_props.set(
    "toLocaleDateString",
    JSValue::Function(
      JSFunction::new(name="toLocaleDateString", body=to_date_string_fn),
    ),
  )

  // Date.prototype.toTimeString()
  let to_time_string_fn = Native(fn(_ctx, this_val, _args) {
    match this_val {
      Object(
        {
          properties: {
            "__internal_date__": JSValue::Internal(JSInternal::Date(zdt)),
            ..
          },
          ..,
        }
      ) => {
        let h = pad2(zdt.hour())
        let min = pad2(zdt.minute())
        let s = pad2(zdt.second())
        // "00:00:00 GMT+0000 (UTC)"
        JSValue::String("\{h}:\{min}:\{s} GMT+0000 (UTC)")
      }
      _ => JSValue::String("Invalid Date")
    }
  })
  date_proto_props.set(
    "toTimeString",
    JSValue::Function(
      JSFunction::new(name="toTimeString", body=to_time_string_fn),
    ),
  )
  date_proto_props.set(
    "toLocaleTimeString",
    JSValue::Function(
      JSFunction::new(name="toLocaleTimeString", body=to_time_string_fn),
    ),
  )

  // Setters Helper: Update and Return Time
  let update_date = fn(
    this_val : JSValue,
    update_fn : (@time.ZonedDateTime) -> @time.ZonedDateTime? raise Error,
  ) -> JSValue {
    match this_val {
      Object(obj) =>
        match obj["__internal_date__"] {
          JSValue::Internal(JSInternal::Date(zdt)) => {
            let new_zdt = update_fn(zdt) catch { _ => None }
            match new_zdt {
              Some(nz) => {
                obj["__internal_date__"] = JSValue::Internal(
                  JSInternal::Date(nz),
                )
                JSValue::Number(nz.to_unix_second().to_double() * 1000.0)
              }
              None => JSValue::Number(@double.not_a_number)
            }
          }
          _ => JSValue::Number(@double.not_a_number)
        }
      _ => JSValue::Number(@double.not_a_number)
    }
  }

  // Date.prototype.setFullYear(year, [month, [date]])
  // Date.prototype.setUTCFullYear(year, [month, [date]])
  let set_full_year_fn = Native(fn(_ctx, this_val, args) {
    if args is [y_arg, .. rest] {
      let y = match y_arg {
        Number(n) => n.to_int()
        _ => return JSValue::Number(@double.not_a_number)
      }
      update_date(this_val, fn(zdt) raise {
        let mut z = zdt.with_year(y)
        match rest {
          [m_arg, .. rest2] => {
            match m_arg {
              Number(m) => z = z.with_month(m.to_int() + 1)
              _ => ()
            }
            match rest2 {
              [d_arg, ..] =>
                match d_arg {
                  Number(d) => z = z.with_day(d.to_int())
                  _ => ()
                }
              _ => ()
            }
          }
          _ => ()
        }
        Some(z)
      })
    } else {
      JSValue::Number(@double.not_a_number)
    }
  })
  date_proto_props.set(
    "setFullYear",
    JSValue::Function(
      JSFunction::new(name="setFullYear", body=set_full_year_fn),
    ),
  )
  date_proto_props.set(
    "setUTCFullYear",
    JSValue::Function(
      JSFunction::new(name="setUTCFullYear", body=set_full_year_fn),
    ),
  )

  // Date.prototype.setMonth(month, [date])
  // Date.prototype.setUTCMonth(month, [date])
  let set_month_fn = Native(fn(_ctx, this_val, args) {
    if args is [m_arg, .. rest] {
      let m = match m_arg {
        Number(n) => n.to_int()
        _ => return JSValue::Number(@double.not_a_number)
      }
      update_date(this_val, fn(zdt) raise {
        let mut z = zdt.with_month(m + 1)
        match rest {
          [d_arg, ..] =>
            match d_arg {
              Number(d) => z = z.with_day(d.to_int())
              _ => ()
            }
          _ => ()
        }
        Some(z)
      })
    } else {
      JSValue::Number(@double.not_a_number)
    }
  })
  date_proto_props.set(
    "setMonth",
    JSValue::Function(JSFunction::new(name="setMonth", body=set_month_fn)),
  )
  date_proto_props.set(
    "setUTCMonth",
    JSValue::Function(JSFunction::new(name="setUTCMonth", body=set_month_fn)),
  )

  // Date.prototype.setDate(date)
  // Date.prototype.setUTCDate(date)
  let set_date_fn = Native(fn(_ctx, this_val, args) {
    if args is [d_arg, ..] {
      let d = match d_arg {
        Number(n) => n.to_int()
        _ => return JSValue::Number(@double.not_a_number)
      }
      update_date(this_val, fn(zdt) raise { Some(zdt.with_day(d)) })
    } else {
      JSValue::Number(@double.not_a_number)
    }
  })
  date_proto_props.set(
    "setDate",
    JSValue::Function(JSFunction::new(name="setDate", body=set_date_fn)),
  )
  date_proto_props.set(
    "setUTCDate",
    JSValue::Function(JSFunction::new(name="setUTCDate", body=set_date_fn)),
  )

  // Date.prototype.setHours(hour, [min, [sec, [ms]]])
  // Date.prototype.setUTCHours(hour, [min, [sec, [ms]]])
  let set_hours_fn = Native(fn(_ctx, this_val, args) {
    if args is [h_arg, .. rest] {
      let h = match h_arg {
        Number(n) => n.to_int()
        _ => return JSValue::Number(@double.not_a_number)
      }
      update_date(this_val, fn(zdt) raise {
        let mut z = zdt.with_hour(h)
        match rest {
          [m_arg, .. rest2] => {
            match m_arg {
              Number(m) => z = z.with_minute(m.to_int())
              _ => ()
            }
            match rest2 {
              [s_arg, .. rest3] => {
                match s_arg {
                  Number(s) => z = z.with_second(s.to_int())
                  _ => ()
                }
                match rest3 {
                  [ms_arg, ..] =>
                    match ms_arg {
                      Number(ms) => z = z.with_nanosecond(ms.to_int() * 1000000)
                      _ => ()
                    }
                  _ => ()
                }
              }
              _ => ()
            }
          }
          _ => ()
        }
        Some(z)
      })
    } else {
      JSValue::Number(@double.not_a_number)
    }
  })
  date_proto_props.set(
    "setHours",
    JSValue::Function(JSFunction::new(name="setHours", body=set_hours_fn)),
  )
  date_proto_props.set(
    "setUTCHours",
    JSValue::Function(JSFunction::new(name="setUTCHours", body=set_hours_fn)),
  )

  // Date.prototype.setMinutes(min, [sec, [ms]])
  // Date.prototype.setUTCMinutes(min, [sec, [ms]])
  let set_minutes_fn = Native(fn(_ctx, this_val, args) {
    if args.length() == 0 {
      return JSValue::Number(@double.not_a_number)
    }
    let min = match args[0] {
      Number(n) => n.to_int()
      _ => return JSValue::Number(@double.not_a_number)
    }
    update_date(this_val, fn(zdt) raise {
      let mut z = zdt.with_minute(min)
      if args.length() > 1 {
        match args[1] {
          Number(s) => z = z.with_second(s.to_int())
          _ => ()
        }
      }
      if args.length() > 2 {
        match args[2] {
          Number(ms) => z = z.with_nanosecond(ms.to_int() * 1000000)
          _ => ()
        }
      }
      Some(z)
    })
  })
  date_proto_props.set(
    "setMinutes",
    JSValue::Function(JSFunction::new(name="setMinutes", body=set_minutes_fn)),
  )
  date_proto_props.set(
    "setUTCMinutes",
    JSValue::Function(
      JSFunction::new(name="setUTCMinutes", body=set_minutes_fn),
    ),
  )

  // Date.prototype.setSeconds(sec, [ms])
  // Date.prototype.setUTCSeconds(sec, [ms])
  let set_seconds_fn = Native(fn(_ctx, this_val, args) {
    if args is [s_arg, .. rest] {
      let s = match s_arg {
        Number(n) => n.to_int()
        _ => return JSValue::Number(@double.not_a_number)
      }
      update_date(this_val, fn(zdt) raise {
        let mut z = zdt.with_second(s)
        match rest {
          [ms_arg, ..] =>
            match ms_arg {
              Number(ms) => z = z.with_nanosecond(ms.to_int() * 1000000)
              _ => ()
            }
          _ => ()
        }
        Some(z)
      })
    } else {
      JSValue::Number(@double.not_a_number)
    }
  })
  date_proto_props.set(
    "setSeconds",
    JSValue::Function(JSFunction::new(name="setSeconds", body=set_seconds_fn)),
  )
  date_proto_props.set(
    "setUTCSeconds",
    JSValue::Function(
      JSFunction::new(name="setUTCSeconds", body=set_seconds_fn),
    ),
  )

  // Date.prototype.setMilliseconds(ms)
  // Date.prototype.setUTCMilliseconds(ms)
  let set_milliseconds_fn = Native(fn(_ctx, this_val, args) {
    if args.length() == 0 {
      return JSValue::Number(@double.not_a_number)
    }
    let ms = match args[0] {
      Number(n) => n.to_int()
      _ => return JSValue::Number(@double.not_a_number)
    }
    update_date(this_val, fn(zdt) raise {
      Some(zdt.with_nanosecond(ms * 1000000))
    })
  })
  date_proto_props.set(
    "setMilliseconds",
    JSValue::Function(
      JSFunction::new(name="setMilliseconds", body=set_milliseconds_fn),
    ),
  )
  date_proto_props.set(
    "setUTCMilliseconds",
    JSValue::Function(
      JSFunction::new(name="setUTCMilliseconds", body=set_milliseconds_fn),
    ),
  )

  // Date.prototype.setYear(year) (Deprecated)
  let set_year_fn = Native(fn(_ctx, this_val, args) {
    if args.length() == 0 {
      return JSValue::Number(@double.not_a_number)
    }
    let y = match args[0] {
      Number(n) => n.to_int()
      _ => return JSValue::Number(@double.not_a_number)
    }
    let full_year = if y >= 0 && y <= 99 { 1900 + y } else { y }
    update_date(this_val, fn(zdt) raise { Some(zdt.with_year(full_year)) })
  })
  date_proto_props.set(
    "setYear",
    JSValue::Function(JSFunction::new(name="setYear", body=set_year_fn)),
  )
  date_ctor_val
}

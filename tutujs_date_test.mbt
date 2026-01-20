///|
test "date constructor" {
  let ctx = @tutujs.Context::new()

  // Test Date() - returns string
  let date_str = ctx.eval("Date()")
  @json.inspect(date_str.to_string().length() > 0, content=true)
  @json.inspect(ctx.eval("typeof Date()"), content=["String", "string"])

  // Test new Date()
  @json.inspect(ctx.eval("typeof new Date()"), content=["String", "object"])
  @json.inspect(ctx.eval("new Date() instanceof Date"), content=[
    "Bool",true,
  ])

  // Test new Date(number)
  // 1600000000000 is 2020-09-13T12:26:40.000Z
  @json.inspect(ctx.eval("new Date(1600000000000).getTime()"), content=[
    "Number", 1600000000000,
  ])

  // Verify UTC components
  // Note: getMonth() is 0-indexed (0-11), so September is 8
  @json.inspect(ctx.eval("new Date(1600000000000).getUTCFullYear()"), content=[
    "Number", 2020,
  ])
  @json.inspect(ctx.eval("new Date(1600000000000).getUTCMonth()"), content=[
    "Number", 8,
  ])
  @json.inspect(ctx.eval("new Date(1600000000000).getUTCDate()"), content=[
    "Number", 13,
  ])
  @json.inspect(ctx.eval("new Date(1600000000000).getUTCHours()"), content=[
    "Number", 12,
  ])
  @json.inspect(ctx.eval("new Date(1600000000000).getUTCMinutes()"), content=[
    "Number", 26,
  ])
  @json.inspect(ctx.eval("new Date(1600000000000).getUTCSeconds()"), content=[
    "Number", 40,
  ])
}

///|
test "date methods" {
  let ctx = @tutujs.Context::new()

  // getTime()
  @json.inspect(ctx.eval("new Date(1000).getTime()"), content=["Number", 1000])

  // setTime()
  let d = ctx.eval("var d = new Date(); d.setTime(1600000000000); d.getTime()")
  @json.inspect(d, content=["Number", 1600000000000])

  // Date.parse() - simple test, format support may vary
  // Should accept ISO string
  // let ts = ctx.eval("Date.parse('2020-01-01T00:00:00.000Z')")
  // @json.inspect(ts.to_number() > 0, content=true)

  // Date.UTC()
  // Date.UTC(2020, 0, 1) -> 2020-01-01 00:00:00 UTC
  let utc_ts = ctx.eval("Date.UTC(2020, 0, 1)")
  @json.inspect(utc_ts, content=["Number", 1577836800000])

  // Test Local Getters (Assuming Local = UTC for now)
  // 2020-09-13 is Sunday (0)
  @json.inspect(ctx.eval("new Date(1600000000000).getFullYear()"), content=[
    "Number", 2020,
  ])
  @json.inspect(ctx.eval("new Date(1600000000000).getDay()"), content=[
    "Number", 0,
  ])

  // Test Setters
  // d is currently 1600000000000 (2020-09-13T12:26:40.000Z)
  // setFullYear(2021) -> 2021-09-13...
  let d2 = ctx.eval(
    "var d = new Date(1600000000000); d.setFullYear(2021); d.getFullYear()",
  )
  @json.inspect(d2, content=["Number", 2021])

  // Test setMonth
  let d3 = ctx.eval(
    "var d = new Date(1600000000000); d.setMonth(0); d.getMonth()",
  )
  @json.inspect(d3, content=["Number", 0])

  // Test toISOString
  @json.inspect(ctx.eval("new Date(1600000000000).toISOString()"), content=[
    "String", "2020-09-13T12:26:40.000Z",
  ])

  // Test toUTCString
  // "Sun, 13 Sep 2020 12:26:40 GMT"
  @json.inspect(ctx.eval("new Date(1600000000000).toUTCString()"), content=[
    "String", "Sun, 13 Sep 2020 12:26:40 GMT",
  ])

  // Test getYear (Deprecated)
  // 2020 - 1900 = 120
  @json.inspect(ctx.eval("new Date(1600000000000).getYear()"), content=[
    "Number", 120,
  ])

  // Test Remaining Getters
  @json.inspect(ctx.eval("new Date(1600000000000).getDate()"), content=[
    "Number", 13,
  ])
  @json.inspect(ctx.eval("new Date(1600000000000).getHours()"), content=[
    "Number", 12,
  ])
  @json.inspect(ctx.eval("new Date(1600000000000).getMinutes()"), content=[
    "Number", 26,
  ])
  @json.inspect(ctx.eval("new Date(1600000000000).getSeconds()"), content=[
    "Number", 40,
  ])
  @json.inspect(ctx.eval("new Date(1600000000000).getMilliseconds()"), content=[
    "Number", 0,
  ])
  @json.inspect(ctx.eval("new Date(1600000000000).getTimezoneOffset()"), content=[
    "Number", 0,
  ])
  @json.inspect(ctx.eval("new Date(1600000000000).getUTCDay()"), content=[
    "Number", 0,
  ])
  @json.inspect(ctx.eval("new Date(1600000000000).getUTCMilliseconds()"), content=[
    "Number", 0,
  ])

  // Test Remaining Setters
  // setDate
  @json.inspect(
    ctx.eval("var d = new Date(1600000000000); d.setDate(15); d.getDate()"),
    content=["Number", 15],
  )
  // setHours
  @json.inspect(
    ctx.eval("var d = new Date(1600000000000); d.setHours(10); d.getHours()"),
    content=["Number", 10],
  )
  // setMinutes
  @json.inspect(
    ctx.eval(
      "var d = new Date(1600000000000); d.setMinutes(30); d.getMinutes()",
    ),
    content=["Number", 30],
  )
  // setSeconds
  @json.inspect(
    ctx.eval(
      "var d = new Date(1600000000000); d.setSeconds(50); d.getSeconds()",
    ),
    content=["Number", 50],
  )
  // setMilliseconds
  @json.inspect(
    ctx.eval(
      "var d = new Date(1600000000000); d.setMilliseconds(123); d.getMilliseconds()",
    ),
    content=["Number", 123],
  )
  // setYear (deprecated)
  @json.inspect(
    ctx.eval("var d = new Date(1600000000000); d.setYear(99); d.getFullYear()"),
    content=["Number", 1999],
  )

  // Test UTC Setters
  @json.inspect(
    ctx.eval(
      "var d = new Date(1600000000000); d.setUTCFullYear(2022); d.getUTCFullYear()",
    ),
    content=["Number", 2022],
  )
  @json.inspect(
    ctx.eval(
      "var d = new Date(1600000000000); d.setUTCMonth(5); d.getUTCMonth()",
    ),
    content=["Number", 5],
  )
  @json.inspect(
    ctx.eval(
      "var d = new Date(1600000000000); d.setUTCDate(20); d.getUTCDate()",
    ),
    content=["Number", 20],
  )
  @json.inspect(
    ctx.eval(
      "var d = new Date(1600000000000); d.setUTCHours(15); d.getUTCHours()",
    ),
    content=["Number", 15],
  )
  @json.inspect(
    ctx.eval(
      "var d = new Date(1600000000000); d.setUTCMinutes(45); d.getUTCMinutes()",
    ),
    content=["Number", 45],
  )
  @json.inspect(
    ctx.eval(
      "var d = new Date(1600000000000); d.setUTCSeconds(10); d.getUTCSeconds()",
    ),
    content=["Number", 10],
  )
  @json.inspect(
    ctx.eval(
      "var d = new Date(1600000000000); d.setUTCMilliseconds(999); d.getUTCMilliseconds()",
    ),
    content=["Number", 999],
  )

  // Test String Methods
  @json.inspect(ctx.eval("new Date(1600000000000).toDateString()"), content=[
    "String", "Sun Sep 13 2020",
  ])
  @json.inspect(ctx.eval("new Date(1600000000000).toTimeString()"), content=[
    "String", "12:26:40 GMT+0000",
  ])
  @json.inspect(ctx.eval("new Date(1600000000000).toJSON()"), content=[
    "String", "2020-09-13T12:26:40.000Z",
  ])
  @json.inspect(ctx.eval("new Date(1600000000000).toString()"), content=[
    "String", "Sun Sep 13 2020 12:26:40 GMT+0000",
  ])
  @json.inspect(ctx.eval("new Date(1600000000000).toLocaleString()"), content=[
    "String", "Sun Sep 13 2020 12:26:40 GMT+0000",
  ])
  @json.inspect(ctx.eval("new Date(1600000000000).toLocaleDateString()"), content=[
    "String", "Sun Sep 13 2020 12:26:40 GMT+0000",
  ])
  @json.inspect(ctx.eval("new Date(1600000000000).toLocaleTimeString()"), content=[
    "String", "Sun Sep 13 2020 12:26:40 GMT+0000",
  ])
  // valueOf
  @json.inspect(ctx.eval("new Date(1600000000000).valueOf()"), content=[
    "Number", 1600000000000,
  ])
}

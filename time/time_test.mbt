///|
test "from header parts (known epoch)" {
  let t = Time::from_header(0, 1970, 1, 0, 0, 0).unwrap()
  assert_eq(t.to_epoch_ns(), 0L)
  assert_eq(t.to_iso8601(), "1970-01-01T00:00:00.000000Z")
}

///|
test "leap second tolerated" {
  let t = Time::from_header(0, 2026, 229, 8, 0, 60).unwrap()
  let t59 = Time::from_header(0, 2026, 229, 8, 0, 59).unwrap()
  assert_eq(t.to_epoch_ns(), t59.to_epoch_ns())
}

///|
test "invalid inputs return None" {
  assert_true(Time::from_header(1_000_000_000, 2023, 1, 0, 0, 0) is None)
  assert_true(Time::from_header(0, 65535, 1, 0, 0, 0) is None)
  assert_true(Time::from_header(0, 2023, 0, 0, 0, 0) is None)
  assert_true(Time::from_header(0, 2023, 367, 0, 0, 0) is None)
  assert_true(Time::from_header(0, 2023, 1, 24, 0, 0) is None)
  assert_true(Time::from_header(0, 2023, 1, 0, 60, 0) is None)
  assert_true(Time::from_header(0, 2023, 1, 0, 0, 61) is None)
  assert_true(Time::from_header(0, 2023, 366, 0, 0, 0) is None)
}

///|
test "negative epoch values use floor division" {
  assert_eq(
    Time::from_epoch_ns(-1L).to_iso8601(),
    "1969-12-31T23:59:59.999999Z",
  )
  assert_eq(
    Time::from_epoch_ns(-1_000_000_001L).to_iso8601(),
    "1969-12-31T23:59:58.999999Z",
  )
}

///|
test "leap year day boundaries" {
  let feb29 = Time::from_header(0, 2024, 60, 0, 0, 0).unwrap()
  assert_eq(
    feb29.to_epoch_ns(),
    Time::from_header(0, 2024, 60, 0, 0, 0).unwrap().to_epoch_ns(),
  )
  assert_eq(feb29.to_iso8601(), "2024-02-29T00:00:00.000000Z")
  let dec31 = Time::from_header(0, 2024, 366, 0, 0, 0).unwrap()
  assert_eq(dec31.to_iso8601(), "2024-12-31T00:00:00.000000Z")
}

///|
test "iso8601 2026-08-17" {
  let t = Time::from_header(123000000, 2026, 229, 8, 30, 15).unwrap()
  assert_eq(t.to_iso8601(), "2026-08-17T08:30:15.123000Z")
}

///|
test "arithmetic and diff" {
  let a = Time::from_header(0, 2026, 229, 8, 0, 0).unwrap()
  let b = a.add_ns(2_000_000_000L)
  assert_eq(b.to_iso8601(), "2026-08-17T08:00:02.000000Z")
  assert_true((b.diff_secs(a) - 2.0).abs() < 1.0e-9)
}

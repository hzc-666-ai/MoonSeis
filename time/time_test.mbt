///|
test "from header parts (known epoch)" {
  let t = Time::from_header(0, 1970, 1, 0, 0, 0).unwrap()
  assert_eq(t.to_epoch_ns(), 0L)
  assert_eq(t.to_iso8601(), "1970-01-01T00:00:00.000000Z")
}

///|
test "leap second tolerated" {
  let t = Time::from_header(0, 2026, 229, 8, 0, 60).unwrap()
  assert_true(t.to_epoch_ns() > 0L)
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

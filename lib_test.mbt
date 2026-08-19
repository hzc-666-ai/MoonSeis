///|
test "facade" {
  assert_eq(version(), "0.1.0")
  assert_eq(parse_records(b"").length(), 0)
  assert_eq(traces_from_bytes(b"").length(), 0)
}

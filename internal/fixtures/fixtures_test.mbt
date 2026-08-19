///|
test "generated stream parses cleanly" {
  let items = @record.iterate_records(valid_stream())
  assert_eq(items.length(), 3)
  for item in items {
    assert_true(item is Ok(_))
  }
}

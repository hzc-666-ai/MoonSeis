///|
fn header_bytes() -> Bytes {
  @binary.concat([
    Bytes::from_array([77, 83]),
    @binary.write_byte(3),
    @binary.write_byte(0),
    @binary.write_uint(0),
    @binary.write_u16(2026),
    @binary.write_u16(229),
    @binary.write_byte(8),
    @binary.write_byte(0),
    @binary.write_byte(0),
    @binary.write_byte(1),
    @binary.write_f64(20.0),
    @binary.write_uint(120),
    @binary.write_uint(0),
    @binary.write_byte(1),
    @binary.write_byte(20),
    @binary.write_u16(0),
    @binary.write_uint(240),
  ])
}

///|
test "parse fixed header" {
  let h = parse_header(header_bytes(), 0).unwrap()
  assert_eq(h.version(), 3)
  assert_eq(h.encoding(), 1)
  assert_true((h.rate_hz() - 20.0).abs() < 1.0e-9)
  assert_eq(h.sample_count(), 120)
  assert_eq(h.identifier_length(), 20)
  assert_eq(h.payload_length(), 240)
}

///|
test "header validation" {
  let b = header_bytes()
  let bad_magic = @binary.concat([
    @binary.write_byte(90),
    @binary.slice(b, 1, b.length() - 1),
  ])
  assert_true(parse_header(bad_magic, 0) is Err(_))
  let bad_version = @binary.concat([
    @binary.slice(b, 0, 2),
    @binary.write_byte(2),
    @binary.slice(b, 3, b.length() - 3),
  ])
  assert_true(parse_header(bad_version, 0) is Err(_))
  assert_true(parse_header(@binary.slice(b, 0, 30), 0) is Err(_))
  assert_true(parse_header(b, -1) is Err(_))
}

///|
test "crc32c known vectors" {
  assert_eq(crc32c(Bytes::new(0)), 0)
  let s = Bytes::from_array([49, 50, 51, 52, 53, 54, 55, 56, 57])
  assert_eq(crc32c(s), 0xE3069283)
}

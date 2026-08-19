///|
test "read little endian primitives" {
  let b = Bytes::from_array([
    120, 0, 0, 0, 254, 255, 255, 255, 0, 0, 0, 0, 0, 0, 240, 63,
  ])
  assert_eq(read_byte(b, 0), 120)
  assert_eq(read_u16(b, 0), 120)
  assert_eq(read_uint(b, 0), 120)
  assert_eq(read_i32(b, 4), -2)
  assert_true((read_f64(b, 8) - 1.0).abs() < 1.0e-9)
}

///|
test "signed 16-bit reads" {
  let b = Bytes::from_array([254, 255, 0, 128])
  assert_eq(read_i16(b, 0), -2)
  assert_eq(read_i16(b, 2), -32768)
}

///|
test "write roundtrip" {
  let bytes = concat([
    write_uint(0xDEADBEEF),
    write_u16(0x1234),
    write_f64(20.0),
  ])
  assert_eq(read_uint(bytes, 0), 0xDEADBEEF)
  assert_eq(read_u16(bytes, 4), 0x1234)
  assert_true((read_f64(bytes, 6) - 20.0).abs() < 1.0e-9)
}

///|
test "slice helper" {
  let b = Bytes::from_array([9, 8, 7, 6, 5])
  let mid = slice(b, 1, 3)
  assert_eq(mid.length(), 3)
  assert_eq(mid[0].to_int(), 8)
  assert_eq(mid[2].to_int(), 6)
}

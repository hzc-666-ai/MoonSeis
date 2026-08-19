///|
test "decode fixed-width samples" {
  let i16 = @binary.concat([
    @binary.write_u16(1000),
    @binary.write_u16(0x8000),
    @binary.write_u16(0xFFFF),
  ])
  match decode_samples(1, 3, i16).unwrap() {
    FloatArray(a) => {
      assert_eq(a.length(), 3)
      assert_true((a[0] - 1000.0).abs() < 1.0e-9)
      assert_true((a[1] + 32768.0).abs() < 1.0e-9)
      assert_true((a[2] + 1.0).abs() < 1.0e-9)
    }
    Raw(_) => fail("expected numeric samples")
  }
  let i32 = @binary.concat([
    @binary.write_uint(0xFFFFFFFE),
    @binary.write_uint(42),
  ])
  match decode_samples(3, 2, i32).unwrap() {
    FloatArray(a) => {
      assert_true((a[0] + 2.0).abs() < 1.0e-9)
      assert_true((a[1] - 42.0).abs() < 1.0e-9)
    }
    Raw(_) => fail("expected numeric samples")
  }
}

///|
test "decode floating point samples" {
  let f32 = @binary.concat([
    @binary.write_uint(0),
    @binary.write_uint(0x3F800000),
  ])
  match decode_samples(4, 2, f32).unwrap() {
    FloatArray(a) => assert_true((a[1] - 1.0).abs() < 1.0e-6)
    Raw(_) => fail("expected numeric samples")
  }
  let f64 = @binary.concat([@binary.write_f64(20.0), @binary.write_f64(-0.5)])
  match decode_samples(5, 2, f64).unwrap() {
    FloatArray(a) =>
      assert_true((a[0] - 20.0).abs() < 1.0e-9 && (a[1] + 0.5).abs() < 1.0e-9)
    Raw(_) => fail("expected numeric samples")
  }
}

///|
test "raw and unsupported encodings" {
  match decode_samples(0, 0, Bytes::from_array([65, 66, 67])).unwrap() {
    Raw(r) => assert_eq(r.length(), 3)
    FloatArray(_) => fail("text should remain raw")
  }
  assert_true(decode_samples(10, 1, Bytes::from_array([0, 0])) is Err(_))
  assert_true(decode_samples(11, 1, Bytes::from_array([0, 0])) is Err(_))
  assert_true(decode_samples(19, 1, Bytes::from_array([0, 0])) is Err(_))
}

///|
test "fixed-width payload length is checked" {
  assert_true(decode_samples(1, 2, Bytes::from_array([0, 0])) is Err(_))
}

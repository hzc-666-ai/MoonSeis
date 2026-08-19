///|
fn one_record_bytes() -> Bytes {
  let header = @binary.concat([
    b"MS",
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
    @binary.write_uint(4),
    @binary.write_uint(0),
    @binary.write_byte(1),
    @binary.write_byte(21),
    @binary.write_u16(0),
    @binary.write_uint(8),
  ])
  let sid = b"FDSN:IU_ANMO_00_B_H_Z"
  let payload = @binary.concat([
    @binary.write_u16(1),
    @binary.write_u16(2),
    @binary.write_u16(3),
    @binary.write_u16(4),
  ])
  let body = @binary.concat([header, sid, payload])
  let crc = @miniseed3.crc32c_region(body, 0, body.length(), 28)
  @binary.concat([
    @binary.slice(body, 0, 28),
    @binary.write_uint(crc),
    @binary.slice(body, 32, body.length() - 32),
  ])
}

///|
test "parse full record" {
  let r = parse_record(one_record_bytes()).unwrap()
  assert_eq(r.sid(), "FDSN:IU_ANMO_00_B_H_Z")
  assert_eq(r.header().sample_count(), 4)
  assert_eq(r.samples().length(), 4)
  assert_true((r.samples()[0] - 1.0).abs() < 1.0e-9)
  assert_eq(r.start_time().to_iso8601(), "2026-08-17T08:00:00.000000Z")
  assert_eq(r.end_time().unwrap().to_iso8601(), "2026-08-17T08:00:00.200000Z")
}

///|
test "record iterator continues after recoverable record error" {
  let good = one_record_bytes()
  let corrupted = @binary.concat([
    @binary.slice(good, 0, good.length() - 1),
    @binary.write_byte(99),
  ])
  let stream = @binary.concat([good, corrupted, good])
  let items = iterate_records(stream)
  assert_eq(items.length(), 3)
  let mut ok_count = 0
  let mut err_count = 0
  for item in items {
    match item {
      Ok(_) => ok_count = ok_count + 1
      Err(_) => err_count = err_count + 1
    }
  }
  assert_eq(ok_count, 2)
  assert_eq(err_count, 1)
}

///|
test "record rejects invalid SID and invalid time" {
  let good = one_record_bytes()
  let bad_sid = @binary.concat([
    @binary.slice(good, 0, 40),
    b"fdsn:IU_ANMO_00_B_H_Z",
    @binary.slice(good, 61, good.length() - 61),
  ])
  assert_true(parse_record(bad_sid) is Err(_))
}

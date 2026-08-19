///|
fn make_record(
  sid : String,
  second : Int,
  samples : Array[Double],
  rate : Double,
) -> @record.Record {
  let header = @miniseed3.FixedHeader::{
    version: 3,
    flags: 0,
    time_ns: 0,
    time_year: 2026,
    time_doy: 229,
    time_hour: 8,
    time_min: 0,
    time_sec: second,
    encoding: 5,
    sample_rate: rate,
    sample_count: samples.length().reinterpret_as_uint(),
    crc: 0,
    publication_version: 1,
    identifier_length: 0,
    extra_headers_length: 0,
    payload_length: 0,
  }
  let start = @time.Time::from_header(0, 2026, 229, 8, 0, second).unwrap()
  {
    header,
    sid,
    extra_headers: "",
    samples: FloatArray(samples),
    start,
    raw: Bytes::new(0),
  }
}

///|
test "group records by SID and retain chronological order" {
  let sid = "FDSN:IU_ANMO_00_B_H_Z"
  let traces = build_traces([
    make_record(sid, 2, [3.0, 4.0], 2.0),
    make_record(sid, 0, [1.0, 2.0], 2.0),
    make_record("FDSN:IU_NNA_00_B_H_Z", 0, [9.0], 1.0),
  ])
  assert_eq(traces.length(), 2)
  assert_eq(traces[0].sid(), sid)
  assert_eq(traces[0].samples(), [1.0, 2.0, 3.0, 4.0])
  assert_true((traces[0].duration_secs() - 3.0).abs() < 1.0e-9)
}

///|
test "detect gaps overlaps duplicates and rate changes" {
  let sid = "FDSN:IU_ANMO_00_B_H_Z"
  let report = inspect_segments([
    make_record(sid, 0, [1.0, 2.0], 1.0),
    make_record(sid, 0, [1.0], 1.0),
    make_record(sid, 1, [2.0, 3.0, 4.0, 5.0], 2.0),
    make_record(sid, 2, [6.0], 2.0),
    make_record(sid, 5, [7.0], 2.0),
  ])
  assert_true(report.duplicate_count() > 0)
  assert_true(report.overlap_count() > 0)
  assert_true(report.gap_count() > 0)
  assert_true(report.rate_change_count() > 0)
}

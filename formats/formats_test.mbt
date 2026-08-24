///|
fn sample_record_at(
  second : Int,
  rate : Double,
  samples : Array[Double],
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
    encoding: 1,
    sample_rate: rate,
    sample_count: samples.length().reinterpret_as_uint(),
    crc: 0,
    publication_version: 1,
    identifier_length: 0,
    extra_headers_length: 0,
    payload_length: (samples.length() * 2).reinterpret_as_uint(),
  }
  let start = @time.Time::from_header(0, 2026, 229, 8, 0, second).unwrap()
  {
    header,
    sid: "FDSN:IU_ANMO_00_B_H_Z",
    extra_headers: "",
    samples: FloatArray(samples),
    start,
    raw: Bytes::new(0),
  }
}

///|
fn sample_record() -> @record.Record {
  sample_record_at(0, 20.0, [1.0, 2.0])
}

///|
test "JSON CSV GeoCSV and Markdown output" {
  let record = sample_record()
  let json = record_json(record)
  assert_true(json.contains("\"sid\""))
  assert_true(inspect_json([record]).contains("\"record_count\":1"))
  let trace = @trace.Trace::{
    sid: record.sid(),
    start: record.start_time(),
    end: record.end_time().unwrap(),
    sample_rate: 20.0,
    samples: record.samples(),
    records: [record],
  }
  assert_true(trace_csv(trace).contains(record.sid()))
  assert_true(trace_geocsv(trace).contains("GeoCSV"))
  let event = @trigger.Event::{
    start_index: 10,
    end_index: 20,
    peak_ratio: 5.0,
    trigger_type: Classic,
    confidence: 0.8,
  }
  assert_true(events_markdown([event]).contains("5"))
}

///|
test "CSV preserves gaps in the record time axis" {
  let first = sample_record_at(0, 2.0, [1.0, 2.0])
  let second = sample_record_at(2, 2.0, [3.0])
  let trace = @trace.Trace::{
    sid: first.sid(),
    start: first.start_time(),
    end: second.end_time().unwrap(),
    sample_rate: 2.0,
    samples: [1.0, 2.0, 3.0],
    records: [first, second],
  }
  let csv = trace_csv(trace)
  assert_true(csv.contains(",0.5,2"))
  assert_true(csv.contains(",2,3"))
}

///|
test "analysis html report renders" {
  let record = sample_record()
  let trace = @trace.Trace::{
    sid: record.sid(),
    start: record.start_time(),
    end: record.end_time().unwrap(),
    sample_rate: 20.0,
    samples: record.samples(),
    records: [record],
  }
  let html = analysis_html([trace])
  assert_true(html.contains("MoonSeis 分析报告"))
  assert_true(html.contains("Max amplitude"))
  assert_true(html.contains("Score:"))
  assert_true(html.contains("Waveform preview"))
  assert_true(html.contains("<polyline"))
}

///|
test "analysis json report renders" {
  let record = sample_record()
  let items = [Ok(record)]
  let json = analysis_json(items)
  assert_true(json.contains("moonseis.analysis.v1"))
  assert_true(json.contains("\"trace_count\":1"))
  assert_true(json.contains("\"segments\""))
  assert_true(json.contains("\"traces\""))
}

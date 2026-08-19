///|
pub fn record_json(record : @record.Record) -> String {
  "{" +
  "\"sid\":\"\{json_escape(record.sid())}\"," +
  "\"encoding\":\{record.header().encoding()}," +
  "\"sample_rate\":\{record.header().rate_hz()}," +
  "\"sample_count\":\{record.header().sample_count()}," +
  "\"start_time\":\"\{record.start_time().to_iso8601()}\"," +
  "\"crc\":\{record.header().crc()}" +
  "}"
}

///|
pub fn inspect_json(records : Array[@record.Record]) -> String {
  let sids : Array[String] = []
  for record in records {
    if !sids.contains(record.sid()) {
      sids.push(record.sid())
    }
  }
  "{\"record_count\":\{records.length()},\"sources\":\{sids.length()}}"
}

///|
pub fn trace_csv(trace : @trace.Trace) -> String {
  let mut output = "sid,time_seconds,sample\n"
  if trace.records().is_empty() {
    let mut i = 0
    while i < trace.samples().length() {
      let seconds = if trace.sample_rate() > 0.0 {
        i.to_double() / trace.sample_rate()
      } else {
        0.0
      }
      output = output + "\{trace.sid()},\{seconds},\{trace.samples()[i]}\n"
      i = i + 1
    }
    return output
  }
  for record in trace.records() {
    let rate = record.header().rate_hz()
    let offset = record.start_time().diff_secs(trace.start_time())
    let samples = record.samples()
    let mut i = 0
    while i < samples.length() {
      let seconds = if rate > 0.0 {
        offset + i.to_double() / rate
      } else {
        offset
      }
      output = output + "\{trace.sid()},\{seconds},\{samples[i]}\n"
      i = i + 1
    }
  }
  output
}

///|
pub fn trace_geocsv(trace : @trace.Trace) -> String {
  "# dataset: GeoCSV 2.0\n# field_unit: second,count\n" + trace_csv(trace)
}

///|
pub fn events_markdown(events : Array[@trigger.Event]) -> String {
  let mut output = "# Events\n\n| Event | Start | End | Peak ratio | Confidence |\n|---:|---:|---:|---:|---:|\n"
  let mut index = 1
  for event in events {
    output = output +
      "| \{index} | \{event.start_index()} | \{event.end_index()} | \{fmt3(event.peak_ratio())} | \{fmt3(event.confidence())} |\n"
    index = index + 1
  }
  output
}

///|
fn fmt3(value : Double) -> String {
  ((value * 1000.0).round() / 1000.0).to_string()
}

///|
fn json_escape(value : String) -> String {
  let mut output = ""
  let mut i = 0
  while i < value.length() {
    let char = value[i]
    let escaped = match char {
      '"' => "\\\""
      '\\' => "\\\\"
      '\n' => "\\n"
      '\r' => "\\r"
      '\t' => "\\t"
      _ => char.to_string()
    }
    output = output + escaped
    i = i + 1
  }
  output
}

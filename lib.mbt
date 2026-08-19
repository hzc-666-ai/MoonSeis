///|
/// MoonSeis package version.
pub fn version() -> String {
  "0.1.0"
}

///|
/// Parse every recoverable miniSEED 3 record in a byte stream.
///
/// A malformed record body is returned as an error while parsing continues
/// when its declared length is trustworthy. Header errors that prevent finding
/// the next record stop iteration.
pub fn parse_records(
  raw : Bytes,
) -> Array[Result[@record.Record, @miniseed3.ParseError]] {
  @record.iterate_records(raw)
}

///|
/// Parse all valid records and group their numeric samples into traces.
/// Invalid records are skipped; use `parse_records` when errors are needed.
pub fn traces_from_bytes(raw : Bytes) -> Array[@trace.Trace] {
  let records : Array[@record.Record] = []
  for item in parse_records(raw) {
    match item {
      Ok(record) => records.push(record)
      Err(_) => ()
    }
  }
  @trace.build_traces(records)
}

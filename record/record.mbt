///|
/// A fully parsed miniSEED 3 record.
pub(all) struct Record {
  header : @miniseed3.FixedHeader
  sid : String
  extra_headers : String
  samples : @encoding.Samples
  start : @time.Time
  raw : Bytes
} derive(Eq, Debug)

///|
pub fn Record::header(self : Record) -> @miniseed3.FixedHeader {
  self.header
}

///|
pub fn Record::sid(self : Record) -> String {
  self.sid
}

///|
pub fn Record::extra_headers(self : Record) -> String {
  self.extra_headers
}

///|
pub fn Record::raw(self : Record) -> Bytes {
  self.raw
}

///|
pub fn Record::start_time(self : Record) -> @time.Time {
  self.start
}

///|
pub fn Record::sample_data(self : Record) -> @encoding.Samples {
  self.samples
}

///|
/// Numeric samples; text and opaque records return an empty array.
pub fn Record::samples(self : Record) -> Array[Double] {
  match self.samples {
    FloatArray(a) => a
    Raw(_) => []
  }
}

///|
/// Exclusive end time, i.e. the expected start of the next contiguous record.
pub fn Record::end_time(self : Record) -> @time.Time? {
  let rate = self.header.rate_hz()
  if rate <= 0.0 || self.header.sample_count() == 0 {
    return None
  }
  let duration_ns = (self.header.sample_count().to_double() * 1.0e9 / rate)
    .round()
    .to_int64()
  Some(self.start.add_ns(duration_ns))
}

///|
/// Parse one complete record. Trailing bytes are ignored.
pub fn parse_record(raw : Bytes) -> Result[Record, @miniseed3.ParseError] {
  let h = match @miniseed3.parse_header(raw, 0) {
    Ok(h) => h
    Err(e) => return Err(e)
  }
  let total = match checked_total_length(h) {
    Ok(n) => n
    Err(e) => return Err(e)
  }
  if total > raw.length() {
    return Err(Truncated(total - raw.length()))
  }
  let sid_start = @miniseed3.fixed_header_size()
  let sid_end = sid_start + h.identifier_length()
  let sid_str = match
    decode_utf8(
      @binary.slice(raw, sid_start, h.identifier_length()),
      "source identifier",
    ) {
    Ok(s) => s
    Err(e) => return Err(e)
  }
  match @sid.parse(sid_str) {
    Ok(_) => ()
    Err(e) => return Err(BadSid(e.to_string()))
  }
  let extra_start = sid_end
  let extra_str = match
    decode_utf8(
      @binary.slice(raw, extra_start, h.extra_headers_length()),
      "extra headers",
    ) {
    Ok(s) => s
    Err(e) => return Err(e)
  }
  if extra_str.trim().length() > 0 && !@json.valid(extra_str) {
    return Err(MalformedExtraHeaders("invalid JSON"))
  }
  let payload_start = extra_start + h.extra_headers_length()
  let payload_len = h.payload_length().reinterpret_as_int()
  let payload = @binary.slice(raw, payload_start, payload_len)
  let computed = @miniseed3.crc32c_region(raw, 0, total, 28)
  if computed != h.crc() {
    return Err(BadCrc(computed, h.crc()))
  }
  let start = match
    @time.Time::from_header(
      h.time_ns(),
      h.time_year(),
      h.time_doy(),
      h.time_hour(),
      h.time_min(),
      h.time_sec(),
    ) {
    Some(t) => t
    None => return Err(BadTime("year/day-of-year/time is out of range"))
  }
  let samples = match
    @encoding.decode_samples(h.encoding(), h.sample_count(), payload) {
    Ok(s) => s
    Err(e) => return Err(e)
  }
  Ok({
    header: h,
    sid: sid_str,
    extra_headers: extra_str,
    samples,
    start,
    raw: @binary.slice(raw, 0, total),
  })
}

///|
/// Return a record's byte length, rejecting UInt-to-Int overflow.
fn checked_total_length(
  h : @miniseed3.FixedHeader,
) -> Result[Int, @miniseed3.ParseError] {
  let base = @miniseed3.fixed_header_size() +
    h.identifier_length() +
    h.extra_headers_length()
  if h.payload_length() > (0x7FFFFFFF - base).reinterpret_as_uint() {
    return Err(LengthMismatch("record length overflows Int"))
  }
  Ok(base + h.payload_length().reinterpret_as_int())
}

///|
pub fn total_length(h : @miniseed3.FixedHeader) -> Int {
  match checked_total_length(h) {
    Ok(n) => n
    Err(_) => -1
  }
}

///|
/// Parse all recoverable records. A bad record body does not stop later records.
pub fn iterate_records(
  raw : Bytes,
) -> Array[Result[Record, @miniseed3.ParseError]] {
  let out : Array[Result[Record, @miniseed3.ParseError]] = []
  let mut off = 0
  while off < raw.length() {
    if raw.length() - off < @miniseed3.fixed_header_size() {
      out.push(
        Err(Truncated(@miniseed3.fixed_header_size() - (raw.length() - off))),
      )
      break
    }
    match @miniseed3.parse_header(raw, off) {
      Err(e) => {
        out.push(Err(e))
        break
      }
      Ok(h) => {
        let total = match checked_total_length(h) {
          Err(e) => {
            out.push(Err(e))
            break
          }
          Ok(n) => n
        }
        if total <= 0 || total > raw.length() - off {
          out.push(Err(Truncated(total - (raw.length() - off))))
          break
        }
        let record_bytes = @binary.slice(raw, off, total)
        out.push(parse_record(record_bytes))
        off = off + total
      }
    }
  }
  out
}

///|
fn decode_utf8(
  raw : Bytes,
  field : String,
) -> Result[String, @miniseed3.ParseError] {
  let chars : Array[Char] = []
  let mut i = 0
  while i < raw.length() {
    let b0 = raw[i].to_int()
    let mut code = 0
    let mut width = 0
    if b0 < 0x80 {
      code = b0
      width = 1
    } else if b0 >= 0xC2 && b0 <= 0xDF && has_cont(raw, i, 1) {
      code = ((b0 & 0x1F) << 6) | (raw[i + 1].to_int() & 0x3F)
      width = 2
    } else if b0 >= 0xE0 && b0 <= 0xEF && has_cont(raw, i, 2) {
      let b1 = raw[i + 1].to_int()
      if (b0 == 0xE0 && b1 < 0xA0) || (b0 == 0xED && b1 >= 0xA0) {
        return utf8_error(field)
      }
      code = ((b0 & 0x0F) << 12) |
        ((b1 & 0x3F) << 6) |
        (raw[i + 2].to_int() & 0x3F)
      width = 3
    } else if b0 >= 0xF0 && b0 <= 0xF4 && has_cont(raw, i, 3) {
      let b1 = raw[i + 1].to_int()
      if (b0 == 0xF0 && b1 < 0x90) || (b0 == 0xF4 && b1 >= 0x90) {
        return utf8_error(field)
      }
      code = ((b0 & 0x07) << 18) |
        ((b1 & 0x3F) << 12) |
        ((raw[i + 2].to_int() & 0x3F) << 6) |
        (raw[i + 3].to_int() & 0x3F)
      width = 4
    } else {
      return utf8_error(field)
    }
    chars.push(code.unsafe_to_char())
    i = i + width
  }
  Ok(String::from_array(chars))
}

///|
fn has_cont(raw : Bytes, off : Int, count : Int) -> Bool {
  if off + count >= raw.length() {
    return false
  }
  let mut i = 1
  while i <= count {
    let b = raw[off + i].to_int()
    if b < 0x80 || b > 0xBF {
      return false
    }
    i = i + 1
  }
  true
}

///|
fn utf8_error(field : String) -> Result[String, @miniseed3.ParseError] {
  if field == "source identifier" {
    Err(BadSid("invalid UTF-8"))
  } else {
    Err(MalformedExtraHeaders("invalid UTF-8"))
  }
}

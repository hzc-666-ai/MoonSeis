///|
/// miniSEED 3 fixed record header (40 bytes, little-endian).
pub(all) struct FixedHeader {
  version : Int
  flags : Int
  time_ns : UInt
  time_year : Int
  time_doy : Int
  time_hour : Int
  time_min : Int
  time_sec : Int
  encoding : Int
  sample_rate : Double
  sample_count : UInt
  crc : UInt
  publication_version : Int
  identifier_length : Int
  extra_headers_length : Int
  payload_length : UInt
} derive(Eq, Debug)

///|
pub fn FixedHeader::version(self : FixedHeader) -> Int {
  self.version
}

///|
pub fn FixedHeader::flags(self : FixedHeader) -> Int {
  self.flags
}

///|
pub fn FixedHeader::encoding(self : FixedHeader) -> Int {
  self.encoding
}

///|
pub fn FixedHeader::sample_rate(self : FixedHeader) -> Double {
  self.sample_rate
}

///|
pub fn FixedHeader::sample_count(self : FixedHeader) -> UInt {
  self.sample_count
}

///|
pub fn FixedHeader::crc(self : FixedHeader) -> UInt {
  self.crc
}

///|
pub fn FixedHeader::publication_version(self : FixedHeader) -> Int {
  self.publication_version
}

///|
pub fn FixedHeader::identifier_length(self : FixedHeader) -> Int {
  self.identifier_length
}

///|
pub fn FixedHeader::extra_headers_length(self : FixedHeader) -> Int {
  self.extra_headers_length
}

///|
pub fn FixedHeader::payload_length(self : FixedHeader) -> UInt {
  self.payload_length
}

///|
pub fn FixedHeader::time_ns(self : FixedHeader) -> UInt {
  self.time_ns
}

///|
pub fn FixedHeader::time_year(self : FixedHeader) -> Int {
  self.time_year
}

///|
pub fn FixedHeader::time_doy(self : FixedHeader) -> Int {
  self.time_doy
}

///|
pub fn FixedHeader::time_hour(self : FixedHeader) -> Int {
  self.time_hour
}

///|
pub fn FixedHeader::time_min(self : FixedHeader) -> Int {
  self.time_min
}

///|
pub fn FixedHeader::time_sec(self : FixedHeader) -> Int {
  self.time_sec
}

///|
/// Effective sample rate in hertz, or zero when unspecified.
pub fn FixedHeader::rate_hz(self : FixedHeader) -> Double {
  if self.sample_rate > 0.0 {
    self.sample_rate
  } else if self.sample_rate < 0.0 {
    -1.0 / self.sample_rate
  } else {
    0.0
  }
}

///|
pub fn fixed_header_size() -> Int {
  40
}

///|
/// Errors produced while parsing a miniSEED 3 record.
pub(all) suberror ParseError {
  BadMagic
  BadVersion(Int)
  Truncated(Int)
  LengthMismatch(String)
  BadCrc(UInt, UInt)
  BadSampleRate(Double)
  BadSampleCount(String)
  BadSid(String)
  BadTime(String)
  UnsupportedEncoding(Int)
  MalformedExtraHeaders(String)
}

///|
impl Show for ParseError with fn output(self, logger) {
  logger.write_string(self.to_string())
}

///|
pub fn ParseError::to_string(self : ParseError) -> String {
  match self {
    BadMagic => "record does not start with 'MS' magic"
    BadVersion(v) => "unsupported format version \{v}"
    Truncated(n) => "truncated record: need \{n} more bytes"
    LengthMismatch(msg) => "length mismatch: \{msg}"
    BadCrc(got, want) => "CRC mismatch: got \{got}, want \{want}"
    BadSampleRate(r) => "invalid sample rate \{r}"
    BadSampleCount(msg) => "invalid sample count: \{msg}"
    BadSid(msg) => "invalid source identifier: \{msg}"
    BadTime(msg) => "invalid start time: \{msg}"
    UnsupportedEncoding(code) => "unsupported data encoding \{code}"
    MalformedExtraHeaders(msg) => "malformed extra headers: \{msg}"
  }
}

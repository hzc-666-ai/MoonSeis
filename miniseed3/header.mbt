///|
/// Parse a fixed miniSEED 3 header at `off`.
pub fn parse_header(raw : Bytes, off : Int) -> Result[FixedHeader, ParseError] {
  if off < 0 || off > raw.length() {
    return Err(Truncated(fixed_header_size()))
  }
  let available = raw.length() - off
  if available < fixed_header_size() {
    return Err(Truncated(fixed_header_size() - available))
  }
  if raw[off] != 77 || raw[off + 1] != 83 {
    return Err(BadMagic)
  }
  let version = @binary.read_byte(raw, off + 2)
  if version != 3 {
    return Err(BadVersion(version))
  }
  let flags = @binary.read_byte(raw, off + 3)
  let time_ns = @binary.read_uint(raw, off + 4)
  let time_year = @binary.read_u16(raw, off + 8)
  let time_doy = @binary.read_u16(raw, off + 10)
  let time_hour = @binary.read_byte(raw, off + 12)
  let time_min = @binary.read_byte(raw, off + 13)
  let time_sec = @binary.read_byte(raw, off + 14)
  let encoding = @binary.read_byte(raw, off + 15)
  let sample_rate = @binary.read_f64(raw, off + 16)
  let sample_count = @binary.read_uint(raw, off + 24)
  let crc = @binary.read_uint(raw, off + 28)
  let publication_version = @binary.read_byte(raw, off + 32)
  let identifier_length = @binary.read_byte(raw, off + 33)
  let extra_headers_length = @binary.read_u16(raw, off + 34)
  let payload_length = @binary.read_uint(raw, off + 36)
  if sample_rate.is_nan() || sample_rate.is_inf() {
    return Err(BadSampleRate(sample_rate))
  }
  if time_ns >= 1_000_000_000 {
    return Err(BadTime("nanoseconds must be less than one second"))
  }
  Ok({
    version,
    flags,
    time_ns,
    time_year,
    time_doy,
    time_hour,
    time_min,
    time_sec,
    encoding,
    sample_rate,
    sample_count,
    crc,
    publication_version,
    identifier_length,
    extra_headers_length,
    payload_length,
  })
}

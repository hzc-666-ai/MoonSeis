///|
/// Build a valid CRC-protected Int16 miniSEED 3 record.
pub fn int16_record(
  sid : String,
  year : Int,
  doy : Int,
  hour : Int,
  minute : Int,
  second : Int,
  rate : Double,
  samples : Array[Int],
) -> Bytes {
  let sid_bytes = ascii_bytes(sid)
  let payload_parts : Array[Bytes] = []
  for sample in samples {
    payload_parts.push(@binary.write_u16(sample))
  }
  let payload = @binary.concat(payload_parts)
  let header = @binary.concat([
    b"MS",
    @binary.write_byte(3),
    @binary.write_byte(0),
    @binary.write_uint(0),
    @binary.write_u16(year),
    @binary.write_u16(doy),
    @binary.write_byte(hour),
    @binary.write_byte(minute),
    @binary.write_byte(second),
    @binary.write_byte(1),
    @binary.write_f64(rate),
    @binary.write_uint(samples.length().reinterpret_as_uint()),
    @binary.write_uint(0),
    @binary.write_byte(1),
    @binary.write_byte(sid_bytes.length()),
    @binary.write_u16(0),
    @binary.write_uint(payload.length().reinterpret_as_uint()),
  ])
  let body = @binary.concat([header, sid_bytes, payload])
  let crc = @miniseed3.crc32c_region(body, 0, body.length(), 28)
  @binary.concat([
    @binary.slice(body, 0, 28),
    @binary.write_uint(crc),
    @binary.slice(body, 32, body.length() - 32),
  ])
}

///|
pub fn valid_stream() -> Bytes {
  @binary.concat([
    int16_record("FDSN:IU_ANMO_00_B_H_Z", 2026, 229, 8, 0, 0, 20.0, [
      0, 1, 2, 3, 10, 100, 10, 3, 2, 1,
    ]),
    int16_record("FDSN:IU_ANMO_00_B_H_Z", 2026, 229, 8, 0, 1, 20.0, [
      1, 2, 3, 4, 5,
    ]),
    int16_record("FDSN:IU_NNA_00_B_H_Z", 2026, 229, 8, 0, 0, 10.0, [9, 10, 11]),
  ])
}

///|
fn ascii_bytes(value : String) -> Bytes {
  let data : FixedArray[Byte] = FixedArray::make(value.length(), 0)
  let mut i = 0
  while i < value.length() {
    data[i] = value[i].to_int().to_byte()
    i = i + 1
  }
  Bytes::from_array(data)
}

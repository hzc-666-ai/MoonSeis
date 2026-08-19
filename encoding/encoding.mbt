///|
/// Decoded numeric samples or an uninterpreted payload.
pub(all) enum Samples {
  FloatArray(Array[Double])
  Raw(Bytes)
} derive(Eq, Debug)

///|
pub fn text_code() -> Int {
  0
}

///|
pub fn int16_code() -> Int {
  1
}

///|
pub fn int32_code() -> Int {
  3
}

///|
pub fn float32_code() -> Int {
  4
}

///|
pub fn float64_code() -> Int {
  5
}

///|
pub fn steim1_code() -> Int {
  10
}

///|
pub fn steim2_code() -> Int {
  11
}

///|
pub fn steim3_code() -> Int {
  19
}

///|
pub fn opaque_code() -> Int {
  100
}

///|
pub fn decode_samples(
  encoding : Int,
  count : UInt,
  payload : Bytes,
) -> Result[Samples, @miniseed3.ParseError] {
  match encoding {
    0 | 100 => Ok(Raw(payload))
    1 => decode_fixed(payload, count, 2, decode_int16)
    3 => decode_fixed(payload, count, 4, decode_int32)
    4 => decode_fixed(payload, count, 4, decode_float32)
    5 => decode_fixed(payload, count, 8, decode_float64)
    _ => Err(UnsupportedEncoding(encoding))
  }
}

///|
fn decode_int16(payload : Bytes, off : Int) -> Double {
  @binary.read_i16(payload, off).to_double()
}

///|
fn decode_int32(payload : Bytes, off : Int) -> Double {
  @binary.read_i32(payload, off).to_double()
}

///|
fn decode_float32(payload : Bytes, off : Int) -> Double {
  @binary.read_f32(payload, off).to_double()
}

///|
fn decode_float64(payload : Bytes, off : Int) -> Double {
  @binary.read_f64(payload, off)
}

///|
fn decode_fixed(
  payload : Bytes,
  count : UInt,
  width : Int,
  read : (Bytes, Int) -> Double,
) -> Result[Samples, @miniseed3.ParseError] {
  if count > (0x7FFFFFFF / width).reinterpret_as_uint() {
    return Err(BadSampleCount("sample byte length overflows Int"))
  }
  let n = count.reinterpret_as_int()
  let expected = n * width
  if payload.length() != expected {
    return Err(
      BadSampleCount(
        "expected \{expected} bytes for \{count} samples, got \{payload.length()}",
      ),
    )
  }
  let out : Array[Double] = Array::make(n, 0.0)
  let mut i = 0
  while i < n {
    out[i] = read(payload, i * width)
    i = i + 1
  }
  Ok(FloatArray(out))
}

///|
pub fn read_byte(b : Bytes, off : Int) -> Int {
  b[off].to_int()
}

///|
pub fn read_u16(b : Bytes, off : Int) -> Int {
  b[off].to_int() | (b[off + 1].to_int() << 8)
}

///|
pub fn read_i16(b : Bytes, off : Int) -> Int {
  let raw = read_u16(b, off)
  if raw >= 0x8000 {
    raw - 0x10000
  } else {
    raw
  }
}

///|
pub fn read_uint(b : Bytes, off : Int) -> UInt {
  b[off].to_uint() |
  (b[off + 1].to_uint() << 8) |
  (b[off + 2].to_uint() << 16) |
  (b[off + 3].to_uint() << 24)
}

///|
pub fn read_i32(b : Bytes, off : Int) -> Int {
  read_uint(b, off).reinterpret_as_int()
}

///|
pub fn read_f32(b : Bytes, off : Int) -> Float {
  Float::reinterpret_from_uint(read_uint(b, off))
}

///|
pub fn read_f64(b : Bytes, off : Int) -> Double {
  let lo : UInt64 = b[off].to_uint64() |
    (b[off + 1].to_uint64() << 8) |
    (b[off + 2].to_uint64() << 16) |
    (b[off + 3].to_uint64() << 24)
  let hi : UInt64 = b[off + 4].to_uint64() |
    (b[off + 5].to_uint64() << 8) |
    (b[off + 6].to_uint64() << 16) |
    (b[off + 7].to_uint64() << 24)
  let bits : UInt64 = (hi << 32) | lo
  bits.reinterpret_as_double()
}

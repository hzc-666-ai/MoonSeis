///|
/// CRC-32C (Castagnoli), reversed polynomial 0x82F63B78.
let crc_table : FixedArray[UInt] = build_crc_table()

///|
fn build_crc_table() -> FixedArray[UInt] {
  let table : FixedArray[UInt] = FixedArray::make(256, 0)
  let mut i = 0
  while i < 256 {
    let mut crc = i.reinterpret_as_uint()
    let mut bit = 0
    while bit < 8 {
      if (crc & 1) == 1 {
        crc = (crc >> 1) ^ 0x82F63B78
      } else {
        crc = crc >> 1
      }
      bit = bit + 1
    }
    table[i] = crc
    i = i + 1
  }
  table
}

///|
pub fn crc32c(data : Bytes) -> UInt {
  let mut crc : UInt = 0xFFFFFFFF
  let mut i = 0
  while i < data.length() {
    let idx = ((crc ^ data[i].to_uint()) & 0xFF).reinterpret_as_int()
    crc = crc_table[idx] ^ (crc >> 8)
    i = i + 1
  }
  crc ^ 0xFFFFFFFF
}

///|
/// CRC over `data[start:end]`, treating the four CRC bytes as zero.
pub fn crc32c_region(
  data : Bytes,
  start : Int,
  end : Int,
  crc_offset : Int,
) -> UInt {
  let mut crc : UInt = 0xFFFFFFFF
  let mut i = start
  while i < end {
    let byte : UInt = if i >= crc_offset && i < crc_offset + 4 {
      0
    } else {
      data[i].to_uint()
    }
    let idx = ((crc ^ byte) & 0xFF).reinterpret_as_int()
    crc = crc_table[idx] ^ (crc >> 8)
    i = i + 1
  }
  crc ^ 0xFFFFFFFF
}

///|
pub fn verify_crc(
  raw : Bytes,
  start : Int,
  end : Int,
  crc_offset : Int,
) -> Bool {
  if start < 0 ||
    end > raw.length() ||
    start > end ||
    crc_offset < start ||
    crc_offset + 4 > end {
    return false
  }
  @binary.read_uint(raw, crc_offset) ==
  crc32c_region(raw, start, end, crc_offset)
}

///|
pub fn write_byte(v : Int) -> Bytes {
  let arr : FixedArray[Byte] = FixedArray::make(1, 0)
  arr[0] = v.to_byte()
  Bytes::from_array(arr)
}

///|
pub fn write_u16(v : Int) -> Bytes {
  let arr : FixedArray[Byte] = FixedArray::make(2, 0)
  arr[0] = (v & 0xFF).to_byte()
  arr[1] = ((v >> 8) & 0xFF).to_byte()
  Bytes::from_array(arr)
}

///|
pub fn write_uint(v : UInt) -> Bytes {
  let arr : FixedArray[Byte] = FixedArray::make(4, 0)
  arr[0] = (v & 0xFF).to_byte()
  arr[1] = ((v >> 8) & 0xFF).to_byte()
  arr[2] = ((v >> 16) & 0xFF).to_byte()
  arr[3] = ((v >> 24) & 0xFF).to_byte()
  Bytes::from_array(arr)
}

///|
pub fn write_f64(v : Double) -> Bytes {
  let bits : UInt64 = v.reinterpret_as_uint64()
  let bytes : FixedArray[Byte] = FixedArray::make(8, 0)
  let mut i = 0
  while i < 8 {
    bytes[i] = (bits >> (i * 8)).to_byte()
    i = i + 1
  }
  Bytes::from_array(bytes)
}

///|
pub fn concat(parts : Array[Bytes]) -> Bytes {
  let mut total = 0
  for p in parts {
    total = total + p.length()
  }
  let arr : FixedArray[Byte] = FixedArray::make(total, 0)
  let mut off = 0
  for p in parts {
    let mut j = 0
    while j < p.length() {
      arr[off + j] = p[j]
      j = j + 1
    }
    off = off + p.length()
  }
  Bytes::from_array(arr)
}

///|
/// Copy bytes `[start, start+len)` into a fresh Bytes.
pub fn slice(raw : Bytes, start : Int, len : Int) -> Bytes {
  let view = raw[start:start + len]
  let arr : FixedArray[Byte] = FixedArray::make(len, 0)
  let mut i = 0
  while i < len {
    arr[i] = view.at(i)
    i = i + 1
  }
  Bytes::from_array(arr)
}

///|
/// A parsed FDSN Source Identifier: `FDSN:NET_STA_LOC_BAND_SOURCE_SUBSOURCE`.
pub(all) struct SourceIdentifier {
  network : String
  station : String
  location : String
  band : String
  source : String
  subsource : String
} derive(Eq, Debug)

///|
pub fn SourceIdentifier::network(self : SourceIdentifier) -> String {
  self.network
}

///|
pub fn SourceIdentifier::station(self : SourceIdentifier) -> String {
  self.station
}

///|
pub fn SourceIdentifier::location(self : SourceIdentifier) -> String {
  self.location
}

///|
pub fn SourceIdentifier::band(self : SourceIdentifier) -> String {
  self.band
}

///|
pub fn SourceIdentifier::source(self : SourceIdentifier) -> String {
  self.source
}

///|
pub fn SourceIdentifier::subsource(self : SourceIdentifier) -> String {
  self.subsource
}

///|
pub fn SourceIdentifier::to_string(self : SourceIdentifier) -> String {
  "FDSN:\{self.network}_\{self.station}_\{self.location}_\{self.band}_\{self.source}_\{self.subsource}"
}

///|
pub fn parse(input : String) -> Result[SourceIdentifier, SidError] {
  if !input.has_prefix("FDSN:") {
    return Err(SidError::new("missing FDSN: prefix", input))
  }
  let body = input[5:]
  let parts = body.split("_").to_array()
  if parts.length() > 6 {
    return Err(SidError::new("too many underscore segments", input))
  }
  let fields = fill_parts(parts)
  let network = fields[0]
  let station = fields[1]
  let location = fields[2]
  let band = fields[3]
  let source = fields[4]
  let subsource = fields[5]
  if network.length() == 0 || network.length() > 8 {
    return Err(SidError::new("network must be 1-8 chars", network))
  }
  // Required fields are only enforced when their segment was actually present,
  // so abbreviated forms like `FDSN:NET` or `FDSN:NET_STA_LOC` are allowed.
  if parts.length() > 1 && (station.length() == 0 || station.length() > 8) {
    return Err(SidError::new("station must be 1-8 chars", station))
  }
  if location.length() > 8 {
    return Err(SidError::new("location too long", location))
  }
  if location == "--" {
    return Err(SidError::new("location '--' is forbidden", location))
  }
  if parts.length() > 4 && (source.length() == 0 || source.length() > 3) {
    return Err(SidError::new("source must be 1-3 chars", source))
  }
  if !valid_chars(network, false) {
    return Err(SidError::new("invalid network chars", network))
  }
  if !valid_chars(station, true) {
    return Err(SidError::new("invalid station chars", station))
  }
  if !valid_chars(location, true) {
    return Err(SidError::new("invalid location chars", location))
  }
  if !valid_chars(band, false) {
    return Err(SidError::new("invalid band chars", band))
  }
  if !valid_chars(source, false) {
    return Err(SidError::new("invalid source chars", source))
  }
  if !valid_chars(subsource, false) {
    return Err(SidError::new("invalid subsource chars", subsource))
  }
  Ok({ network, station, location, band, source, subsource })
}

///|
/// Pad parts (StringView array) to exactly 6 Strings (empty appended).
fn fill_parts(parts : Array[StringView]) -> Array[String] {
  let out : Array[String] = []
  let mut i = 0
  while i < 6 {
    if i < parts.length() {
      out.push(parts[i].to_owned())
    } else {
      out.push("")
    }
    i = i + 1
  }
  out
}

///|
/// Allowed charset: [A-Z0-9]; station/location additionally allow '-'.
fn valid_chars(s : String, allow_dash : Bool) -> Bool {
  let mut i = 0
  while i < s.length() {
    let c = s[i]
    if !((c >= 'A' && c <= 'Z') || (c >= '0' && c <= '9')) {
      if !(allow_dash && c == '-') {
        return false
      }
    }
    i = i + 1
  }
  true
}

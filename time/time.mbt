///|
/// Absolute time stored as nanoseconds since the Unix epoch (1970-01-01 UTC).
pub(all) struct Time {
  ns : Int64
} derive(Eq, Debug)

///|
let ns_per_second : Int64 = 1_000_000_000L

///|
let seconds_per_day : Int64 = 86_400L

///|
/// Construct from miniSEED header parts (nanos, year, day-of-year, h:m:s).
/// `sec == 60` is a positive leap second, clamped to 59.
pub fn Time::from_header(
  nanos : UInt,
  year : Int,
  doy : Int,
  hour : Int,
  min : Int,
  sec : Int,
) -> Time? {
  if nanos >= 1_000_000_000 ||
    year < 1677 ||
    year > 2262 ||
    doy < 1 ||
    doy > 366 ||
    hour < 0 ||
    hour > 23 ||
    min < 0 ||
    min > 59 {
    return None
  }
  let s = if sec == 60 { 59 } else { sec }
  if s < 0 || s > 59 {
    return None
  }
  let md = match day_of_year_to_month_day(year, doy) {
    Some(md) => md
    None => return None
  }
  let (month, day) = md
  let days = days_from_civil(year, month, day)
  let seconds_of_day = (hour * 3600 + min * 60 + s).to_int64()
  let total_sec = days.to_int64() * seconds_per_day + seconds_of_day
  let ns = total_sec * ns_per_second + nanos.to_int64()
  Some({ ns, })
}

///|
pub fn Time::from_epoch_ns(ns : Int64) -> Time {
  { ns, }
}

///|
pub fn Time::to_epoch_ns(self : Time) -> Int64 {
  self.ns
}

///|
pub fn Time::add_ns(self : Time, delta : Int64) -> Time {
  { ns: self.ns + delta }
}

///|
pub fn Time::diff_secs(self : Time, other : Time) -> Double {
  (self.ns - other.ns).to_double() / ns_per_second.to_double()
}

///|
/// ISO8601 with microsecond precision, UTC: `2026-08-17T08:30:15.123000Z`.
pub fn Time::to_iso8601(self : Time) -> String {
  let (days, secs_of_day, micros) = self.to_days_secs()
  let (year, month, day) = civil_from_days(days)
  let hour = secs_of_day / 3600
  let min = secs_of_day % 3600 / 60
  let sec = secs_of_day % 60
  let micro_str = if micros == 0 {
    "000000"
  } else {
    pad_left(micros.to_string(), 6)
  }
  "\{pad_left(year.to_string(), 4)}-\{pad_left(month.to_string(), 2)}-\{pad_left(day.to_string(), 2)}T\{pad_left(hour.to_string(), 2)}:\{pad_left(min.to_string(), 2)}:\{pad_left(sec.to_string(), 2)}.\{micro_str}Z"
}

///|
fn Time::to_days_secs(self : Time) -> (Int, Int, Int) {
  let mut whole_secs = self.ns / ns_per_second
  let mut rem_ns = self.ns % ns_per_second
  if rem_ns < 0L {
    whole_secs = whole_secs - 1L
    rem_ns = rem_ns + ns_per_second
  }
  let mut days = whole_secs / seconds_per_day
  let mut secs_of_day = whole_secs % seconds_per_day
  if secs_of_day < 0L {
    days = days - 1L
    secs_of_day = secs_of_day + seconds_per_day
  }
  let micros = (rem_ns / 1_000L).to_int()
  (days.to_int(), secs_of_day.to_int(), micros)
}

///|
/// Howard Hinnant civil_from_days: days since 1970-01-01 -> (y, m, d).
fn civil_from_days(z : Int) -> (Int, Int, Int) {
  let z = z + 719468
  let era = (if z >= 0 { z } else { z - 146096 }) / 146097
  let doe = z - era * 146097
  let yoe = (doe - doe / 1460 + doe / 36524 - doe / 146096) / 365
  let y = yoe + era * 400
  let doy = doe - (365 * yoe + yoe / 4 - yoe / 100)
  let mp = (5 * doy + 2) / 153
  let d = doy - (153 * mp + 2) / 5 + 1
  let m = if mp < 10 { mp + 3 } else { mp - 9 }
  (if m <= 2 { y + 1 } else { y }, m, d)
}

///|
/// Howard Hinnant days_from_civil: (y, m, d) -> days since 1970-01-01.
fn days_from_civil(y : Int, m : Int, d : Int) -> Int {
  let y = if m <= 2 { y - 1 } else { y }
  let era = (if y >= 0 { y } else { y - 399 }) / 400
  let yoe = y - era * 400
  let mp = if m > 2 { m - 3 } else { m + 9 }
  let doy = (153 * mp + 2) / 5 + d - 1
  let doe = yoe * 365 + yoe / 4 - yoe / 100 + doy
  era * 146097 + doe - 719468
}

///|
/// day-of-year (1-based) -> (month, day). None when out of range.
fn day_of_year_to_month_day(year : Int, doy : Int) -> (Int, Int)? {
  if doy < 1 || doy > 366 {
    return None
  }
  let leap = (year % 4 == 0 && year % 100 != 0) || year % 400 == 0
  if doy == 366 && !leap {
    return None
  }
  let cum : Array[Int] = if leap {
    [0, 31, 60, 91, 121, 152, 182, 213, 244, 274, 305, 335, 366]
  } else {
    [0, 31, 59, 90, 120, 151, 181, 212, 243, 273, 304, 334, 365]
  }
  let mut month = 1
  while month < 12 && doy > cum[month] {
    month = month + 1
  }
  let day = doy - cum[month - 1]
  Some((month, day))
}

///|
/// Left-pad a string to a target length with '0'.
fn pad_left(s : String, len : Int) -> String {
  if s.length() >= len {
    return s
  }
  let mut out = ""
  let mut i = s.length()
  while i < len {
    out = out + "0"
    i = i + 1
  }
  out + s
}

///|
/// A channel waveform assembled from time-ordered records.
pub(all) struct Trace {
  sid : String
  start : @time.Time
  end : @time.Time
  sample_rate : Double
  samples : Array[Double]
  records : Array[@record.Record]
} derive(Eq, Debug)

///|
pub fn Trace::sid(self : Trace) -> String {
  self.sid
}

///|
pub fn Trace::start_time(self : Trace) -> @time.Time {
  self.start
}

///|
pub fn Trace::end_time(self : Trace) -> @time.Time {
  self.end
}

///|
pub fn Trace::sample_rate(self : Trace) -> Double {
  self.sample_rate
}

///|
pub fn Trace::samples(self : Trace) -> Array[Double] {
  self.samples
}

///|
pub fn Trace::records(self : Trace) -> Array[@record.Record] {
  self.records
}

///|
pub fn Trace::sample_count(self : Trace) -> Int {
  self.samples.length()
}

///|
pub fn Trace::duration_secs(self : Trace) -> Double {
  self.end.diff_secs(self.start)
}

///|
/// Group numeric records by SID and order each group chronologically.
pub fn build_traces(records : Array[@record.Record]) -> Array[Trace] {
  let sids : Array[String] = []
  for record in records {
    if !sids.contains(record.sid()) {
      sids.push(record.sid())
    }
  }
  sort_strings(sids)
  let out : Array[Trace] = []
  for sid in sids {
    let group : Array[@record.Record] = []
    for record in records {
      if record.sid() == sid {
        group.push(record)
      }
    }
    sort_records(group)
    match build_trace(sid, group) {
      Some(trace) => out.push(trace)
      None => ()
    }
  }
  out
}

///|
fn build_trace(sid : String, group : Array[@record.Record]) -> Trace? {
  if group.is_empty() {
    return None
  }
  let samples : Array[Double] = []
  let start = group[0].start_time()
  let mut end = start
  let mut rate = 0.0
  for record in group {
    if rate == 0.0 && record.header().rate_hz() > 0.0 {
      rate = record.header().rate_hz()
    }
    for value in record.samples() {
      samples.push(value)
    }
    match record.end_time() {
      Some(record_end) =>
        if record_end.to_epoch_ns() > end.to_epoch_ns() {
          end = record_end
        }
      None => ()
    }
  }
  Some({ sid, start, end, sample_rate: rate, samples, records: group })
}

///|
fn sort_records(records : Array[@record.Record]) -> Unit {
  let mut i = 1
  while i < records.length() {
    let current = records[i]
    let mut j = i
    while j > 0 &&
          records[j - 1].start_time().to_epoch_ns() >
          current.start_time().to_epoch_ns() {
      records[j] = records[j - 1]
      j = j - 1
    }
    records[j] = current
    i = i + 1
  }
}

///|
fn sort_strings(values : Array[String]) -> Unit {
  let mut i = 1
  while i < values.length() {
    let current = values[i]
    let mut j = i
    while j > 0 && values[j - 1].lexical_compare(current) > 0 {
      values[j] = values[j - 1]
      j = j - 1
    }
    values[j] = current
    i = i + 1
  }
}

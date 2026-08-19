///|
pub(all) enum TriggerType {
  Classic
  Recursive
} derive(Eq, Debug)

///|
pub(all) struct Event {
  start_index : Int
  end_index : Int
  peak_ratio : Double
  trigger_type : TriggerType
  confidence : Double
} derive(Eq, Debug)

///|
pub fn Event::start_index(self : Event) -> Int {
  self.start_index
}

///|
pub fn Event::end_index(self : Event) -> Int {
  self.end_index
}

///|
pub fn Event::peak_ratio(self : Event) -> Double {
  self.peak_ratio
}

///|
pub fn Event::trigger_type(self : Event) -> TriggerType {
  self.trigger_type
}

///|
pub fn Event::confidence(self : Event) -> Double {
  self.confidence
}

///|
pub fn classic_sta_lta(
  samples : Array[Double],
  sta_len? : Int = 10,
  lta_len? : Int = 100,
  trigger_on? : Double = 3.0,
  trigger_off? : Double = 1.0,
  min_duration? : Int = 5,
  pad_before? : Int = 10,
  pad_after? : Int = 10,
) -> Array[Event] {
  run_trigger(
    samples,
    sta_len,
    lta_len,
    trigger_on,
    trigger_off,
    min_duration,
    pad_before,
    pad_after,
    Classic,
  )
}

///|
pub fn recursive_sta_lta(
  samples : Array[Double],
  sta_len? : Int = 10,
  lta_len? : Int = 100,
  trigger_on? : Double = 4.0,
  trigger_off? : Double = 1.5,
  min_duration? : Int = 5,
  pad_before? : Int = 10,
  pad_after? : Int = 10,
) -> Array[Event] {
  run_trigger(
    samples,
    sta_len,
    lta_len,
    trigger_on,
    trigger_off,
    min_duration,
    pad_before,
    pad_after,
    Recursive,
  )
}

///|
fn run_trigger(
  samples : Array[Double],
  sta_len : Int,
  lta_len : Int,
  trigger_on : Double,
  trigger_off : Double,
  min_duration : Int,
  pad_before : Int,
  pad_after : Int,
  trigger_type : TriggerType,
) -> Array[Event] {
  if sta_len <= 0 || lta_len <= sta_len || trigger_on <= trigger_off {
    return []
  }
  let ratios = ratio_series(samples, sta_len, lta_len, trigger_type)
  let events : Array[Event] = []
  let mut i = lta_len
  while i < ratios.length() {
    if ratios[i] >= trigger_on {
      let start = i
      let mut end = i
      let mut peak = ratios[i]
      while end < ratios.length() && ratios[end] >= trigger_off {
        peak = peak.max(ratios[end])
        end = end + 1
      }
      if end - start >= min_duration {
        events.push({
          start_index: (start - pad_before).max(0),
          end_index: (end + pad_after).min(samples.length()),
          peak_ratio: peak,
          trigger_type,
          confidence: confidence(peak, trigger_on, end - start),
        })
      }
      i = end.max(i + 1)
    } else {
      i = i + 1
    }
  }
  events
}

///|
fn ratio_series(
  samples : Array[Double],
  sta_len : Int,
  lta_len : Int,
  trigger_type : TriggerType,
) -> Array[Double] {
  let out : Array[Double] = Array::make(samples.length(), 0.0)
  let mut sta = 0.0
  let mut lta = 0.0
  let mut i = 0
  while i < samples.length() {
    let value = samples[i].abs()
    match trigger_type {
      Classic => {
        sta = sta + value
        lta = lta + value
        if i >= sta_len {
          sta = sta - samples[i - sta_len].abs()
        }
        if i >= lta_len {
          lta = lta - samples[i - lta_len].abs()
        }
        if i + 1 >= lta_len && lta > 0.0 {
          out[i] = sta / sta_len.to_double() / (lta / lta_len.to_double())
        }
      }
      Recursive => {
        sta = sta * (1.0 - 1.0 / sta_len.to_double()) +
          value / sta_len.to_double()
        lta = lta * (1.0 - 1.0 / lta_len.to_double()) +
          value / lta_len.to_double()
        if i + 1 >= lta_len && lta > 0.0 {
          out[i] = sta / lta
        }
      }
    }
    i = i + 1
  }
  out
}

///|
fn confidence(peak : Double, threshold : Double, duration : Int) -> Double {
  let strength = ((peak / threshold - 1.0) / 2.0).max(0.0).min(1.0)
  let persistence = (duration.to_double() / 100.0).min(1.0)
  (strength * 0.7 + persistence * 0.3).min(1.0)
}

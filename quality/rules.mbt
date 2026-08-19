///|
/// Flag repeated values at the positive or negative full-scale peak.
pub fn clipping_rule(min_count? : Int = 2) -> Rule {
  fn(trace : @trace.Trace) -> Array[Issue] {
    let samples = trace.samples()
    let mut peak = 0.0
    for value in samples {
      peak = peak.max(value.abs())
    }
    if peak == 0.0 {
      return []
    }
    let mut count = 0
    for value in samples {
      if (value.abs() - peak).abs() <= peak * 1.0e-12 {
        count = count + 1
      }
    }
    if count >= min_count {
      [{ severity: Error, message: "\{count} samples at full-scale peak" }]
    } else {
      []
    }
  }
}

///|
pub fn constant_rule(min_run? : Int = 10) -> Rule {
  fn(trace : @trace.Trace) -> Array[Issue] {
    let samples = trace.samples()
    if samples.length() < min_run {
      return []
    }
    let mut run = 1
    let mut i = 1
    while i < samples.length() {
      if samples[i] == samples[i - 1] {
        run = run + 1
      } else {
        if run >= min_run {
          return [
            { severity: Error, message: "constant run of \{run} samples" },
          ]
        }
        run = 1
      }
      i = i + 1
    }
    if run >= min_run {
      [{ severity: Error, message: "constant run of \{run} samples" }]
    } else {
      []
    }
  }
}

///|
/// Flag samples whose amplitude greatly exceeds the RMS of all other samples.
pub fn spike_rule(ratio? : Double = 20.0) -> Rule {
  fn(trace : @trace.Trace) -> Array[Issue] {
    let samples = trace.samples()
    if samples.length() < 3 {
      return []
    }
    let mut total_squares = 0.0
    for sample in samples {
      total_squares = total_squares + sample * sample
    }
    let mut spikes = 0
    let mut i = 0
    while i < samples.length() {
      let others = (total_squares - samples[i] * samples[i]).max(0.0)
      let baseline = (others / (samples.length() - 1).to_double()).sqrt()
      if baseline > 0.0 && samples[i].abs() > baseline * ratio {
        spikes = spikes + 1
      }
      i = i + 1
    }
    if spikes > 0 {
      [{ severity: Error, message: "\{spikes} spike(s) detected" }]
    } else {
      []
    }
  }
}

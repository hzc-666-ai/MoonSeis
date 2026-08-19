///|
pub(all) enum Severity {
  Info
  Warning
  Error
  Critical
} derive(Eq, Debug)

///|
pub(all) struct Issue {
  severity : Severity
  message : String
} derive(Eq, Debug)

///|
pub fn Issue::severity(self : Issue) -> Severity {
  self.severity
}

///|
pub fn Issue::message(self : Issue) -> String {
  self.message
}

///|
pub(all) struct Metrics {
  max_amplitude : Double
  mean : Double
  stddev : Double
  clip_ratio : Double
  constant_runs : Int
  completeness : Double
} derive(Eq, Debug)

///|
pub fn Metrics::max_amplitude(self : Metrics) -> Double {
  self.max_amplitude
}

///|
pub fn Metrics::mean(self : Metrics) -> Double {
  self.mean
}

///|
pub fn Metrics::stddev(self : Metrics) -> Double {
  self.stddev
}

///|
pub fn Metrics::clip_ratio(self : Metrics) -> Double {
  self.clip_ratio
}

///|
pub fn Metrics::constant_runs(self : Metrics) -> Int {
  self.constant_runs
}

///|
pub fn Metrics::completeness(self : Metrics) -> Double {
  self.completeness
}

///|
pub(all) struct QualityReport {
  sid : String
  issues : Array[Issue]
  metrics : Metrics
  score : Int
} derive(Eq, Debug)

///|
pub fn QualityReport::sid(self : QualityReport) -> String {
  self.sid
}

///|
pub fn QualityReport::issues(self : QualityReport) -> Array[Issue] {
  self.issues
}

///|
pub fn QualityReport::issue_count(self : QualityReport) -> Int {
  self.issues.length()
}

///|
pub fn QualityReport::metrics(self : QualityReport) -> Metrics {
  self.metrics
}

///|
pub fn QualityReport::score(self : QualityReport) -> Int {
  self.score
}

///|
pub type Rule = (@trace.Trace) -> Array[Issue]

///|
pub fn default_rules() -> Array[Rule] {
  [clipping_rule(), constant_rule(), spike_rule()]
}

///|
pub fn inspect_trace(
  trace : @trace.Trace,
  rules : Array[Rule],
) -> QualityReport {
  let issues : Array[Issue] = []
  for rule in rules {
    for issue in rule(trace) {
      issues.push(issue)
    }
  }
  let metrics = compute_metrics(trace)
  { sid: trace.sid(), issues, metrics, score: compute_score(metrics, issues) }
}

///|
fn compute_metrics(trace : @trace.Trace) -> Metrics {
  let samples = trace.samples()
  if samples.is_empty() {
    return {
      max_amplitude: 0.0,
      mean: 0.0,
      stddev: 0.0,
      clip_ratio: 0.0,
      constant_runs: 0,
      completeness: 1.0,
    }
  }
  let mut sum = 0.0
  let mut max_abs = 0.0
  for value in samples {
    sum = sum + value
    max_abs = max_abs.max(value.abs())
  }
  let mean = sum / samples.length().to_double()
  let mut sumsq = 0.0
  let mut clipped = 0
  for value in samples {
    let delta = value - mean
    sumsq = sumsq + delta * delta
    if max_abs > 0.0 && (value.abs() - max_abs).abs() <= max_abs * 1.0e-12 {
      clipped = clipped + 1
    }
  }
  {
    max_amplitude: max_abs,
    mean,
    stddev: (sumsq / samples.length().to_double()).sqrt(),
    clip_ratio: clipped.to_double() / samples.length().to_double(),
    constant_runs: count_constant_runs(samples, 10),
    completeness: completeness(trace),
  }
}

///|
fn completeness(trace : @trace.Trace) -> Double {
  let rate = trace.sample_rate()
  let duration = trace.duration_secs()
  if rate <= 0.0 || duration <= 0.0 {
    return 1.0
  }
  let expected = (rate * duration).round()
  if expected <= 0.0 {
    1.0
  } else {
    (trace.sample_count().to_double() / expected).min(1.0)
  }
}

///|
fn count_constant_runs(samples : Array[Double], minimum : Int) -> Int {
  if samples.is_empty() {
    return 0
  }
  let mut count = 0
  let mut run = 1
  let mut i = 1
  while i < samples.length() {
    if samples[i] == samples[i - 1] {
      run = run + 1
    } else {
      if run >= minimum {
        count = count + 1
      }
      run = 1
    }
    i = i + 1
  }
  if run >= minimum {
    count + 1
  } else {
    count
  }
}

///|
fn compute_score(metrics : Metrics, issues : Array[Issue]) -> Int {
  let mut score = 100
  score = score - ((1.0 - metrics.completeness) * 50.0).round().to_int()
  for issue in issues {
    match issue.severity {
      Info => score = score - 1
      Warning => score = score - 5
      Error => score = score - 15
      Critical => score = score - 30
    }
  }
  score.max(0)
}

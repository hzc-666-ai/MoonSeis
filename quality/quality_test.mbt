///|
fn make_trace(samples : Array[Double]) -> @trace.Trace {
  let start = @time.Time::from_epoch_ns(0L)
  let end = start.add_ns(
    (samples.length().to_double() / 20.0 * 1.0e9).round().to_int64(),
  )
  {
    sid: "FDSN:IU_ANMO_00_B_H_Z",
    start,
    end,
    sample_rate: 20.0,
    samples,
    records: [],
  }
}

///|
test "quality rules flag clipping constant runs and spikes" {
  assert_true(
    inspect_trace(make_trace([2.0, 2.0, 0.0]), [clipping_rule()]).issue_count() >
    0,
  )
  assert_true(
    inspect_trace(make_trace([5.0, 5.0, 5.0, 5.0]), [constant_rule(min_run=4)]).issue_count() >
    0,
  )
  let samples : Array[Double] = Array::make(100, 1.0)
  samples[50] = 1000.0
  assert_true(
    inspect_trace(make_trace(samples), [spike_rule()]).issue_count() > 0,
  )
}

///|
test "clean trace scores high" {
  let samples : Array[Double] = []
  let mut i = 0
  while i < 100 {
    samples.push(i.to_double() / 100.0)
    i = i + 1
  }
  let report = inspect_trace(make_trace(samples), default_rules())
  assert_true(report.score() >= 90)
  assert_eq(report.issue_count(), 0)
}

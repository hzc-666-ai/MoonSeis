///|
fn event_signal() -> Array[Double] {
  let samples : Array[Double] = Array::make(400, 0.1)
  let mut i = 200
  while i < 260 {
    samples[i] = 8.0
    i = i + 1
  }
  samples
}

///|
test "classic and recursive STA LTA detect an event" {
  let classic = classic_sta_lta(
    event_signal(),
    sta_len=10,
    lta_len=100,
    trigger_on=3.0,
    trigger_off=1.0,
    min_duration=5,
  )
  assert_true(classic.length() >= 1)
  assert_true(classic[0].peak_ratio() >= 3.0)
  let recursive = recursive_sta_lta(
    event_signal(),
    sta_len=10,
    lta_len=100,
    trigger_on=3.0,
    trigger_off=1.2,
    min_duration=5,
  )
  assert_true(recursive.length() >= 1)
}

///|
test "quiet signal produces no events and bad config is safe" {
  assert_eq(classic_sta_lta(Array::make(400, 0.001)).length(), 0)
  assert_eq(classic_sta_lta([1.0, 2.0], sta_len=10, lta_len=5).length(), 0)
}

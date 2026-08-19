///|
test "preprocessing and statistics" {
  let input = [1.0, 2.0, 3.0, 4.0]
  let centered = demean(input)
  assert_true(mean(centered).abs() < 1.0e-12)
  let trend = detrend(input)
  assert_true(peak(trend) < 1.0e-12)
  assert_eq(normalize([-2.0, 1.0]), [-1.0, 0.5])
  assert_true((rms([3.0, 4.0]) - 12.5.sqrt()).abs() < 1.0e-12)
  assert_eq(energy([3.0, 4.0]), 25.0)
}

///|
test "taper sliding RMS and resample" {
  let tapered = hann_taper([1.0, 1.0, 1.0, 1.0], 1)
  assert_true(tapered[0] < 1.0 && tapered[3] < 1.0)
  assert_eq(sliding_rms([1.0, 1.0, 1.0], 1), [1.0, 1.0, 1.0])
  assert_eq(resample_basic([0.0, 1.0, 2.0, 3.0], 4, 2), [0.0, 2.0])
}

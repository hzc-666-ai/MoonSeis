///|
pub fn mean(samples : Array[Double]) -> Double {
  if samples.is_empty() {
    return 0.0
  }
  let mut sum = 0.0
  for value in samples {
    sum = sum + value
  }
  sum / samples.length().to_double()
}

///|
pub fn demean(samples : Array[Double]) -> Array[Double] {
  let center = mean(samples)
  samples.map(fn(value) { value - center })
}

///|
pub fn detrend(samples : Array[Double]) -> Array[Double] {
  let n = samples.length()
  if n < 2 {
    return samples.copy()
  }
  let xbar = (n - 1).to_double() / 2.0
  let ybar = mean(samples)
  let mut numerator = 0.0
  let mut denominator = 0.0
  let mut i = 0
  while i < n {
    let dx = i.to_double() - xbar
    numerator = numerator + dx * (samples[i] - ybar)
    denominator = denominator + dx * dx
    i = i + 1
  }
  let slope = if denominator > 0.0 { numerator / denominator } else { 0.0 }
  let out : Array[Double] = Array::make(n, 0.0)
  i = 0
  while i < n {
    out[i] = samples[i] - (ybar + slope * (i.to_double() - xbar))
    i = i + 1
  }
  out
}

///|
pub fn peak(samples : Array[Double]) -> Double {
  let mut result = 0.0
  for value in samples {
    result = result.max(value.abs())
  }
  result
}

///|
pub fn normalize(samples : Array[Double]) -> Array[Double] {
  let scale = peak(samples)
  if scale == 0.0 {
    samples.copy()
  } else {
    samples.map(fn(value) { value / scale })
  }
}

///|
pub fn hann_taper(samples : Array[Double], count : Int) -> Array[Double] {
  let out = samples.copy()
  let edge = count.min(samples.length() / 2)
  let mut i = 0
  while i < edge {
    let weight = 0.5 *
      (1.0 - @math.cos(@math.PI * (i + 1).to_double() / (edge + 1).to_double()))
    out[i] = out[i] * weight
    out[out.length() - 1 - i] = out[out.length() - 1 - i] * weight
    i = i + 1
  }
  out
}

///|
pub fn rms(samples : Array[Double]) -> Double {
  if samples.is_empty() {
    return 0.0
  }
  (energy(samples) / samples.length().to_double()).sqrt()
}

///|
pub fn energy(samples : Array[Double]) -> Double {
  let mut result = 0.0
  for value in samples {
    result = result + value * value
  }
  result
}

///|
pub fn stddev(samples : Array[Double]) -> Double {
  if samples.is_empty() {
    return 0.0
  }
  let center = mean(samples)
  let mut sum = 0.0
  for value in samples {
    let delta = value - center
    sum = sum + delta * delta
  }
  (sum / samples.length().to_double()).sqrt()
}

///|
pub fn skewness(samples : Array[Double]) -> Double {
  if samples.length() < 3 {
    return 0.0
  }
  let center = mean(samples)
  let deviation = stddev(samples)
  if deviation == 0.0 {
    return 0.0
  }
  let mut sum = 0.0
  for value in samples {
    let normalized = (value - center) / deviation
    sum = sum + normalized * normalized * normalized
  }
  sum / samples.length().to_double()
}

///|
pub fn kurtosis(samples : Array[Double]) -> Double {
  if samples.length() < 4 {
    return 0.0
  }
  let center = mean(samples)
  let deviation = stddev(samples)
  if deviation == 0.0 {
    return -3.0
  }
  let mut sum = 0.0
  for value in samples {
    let normalized = (value - center) / deviation
    sum = sum + normalized * normalized * normalized * normalized
  }
  sum / samples.length().to_double() - 3.0
}

///|
pub fn sliding_rms(samples : Array[Double], radius : Int) -> Array[Double] {
  let out : Array[Double] = Array::make(samples.length(), 0.0)
  let mut i = 0
  while i < samples.length() {
    let low = (i - radius).max(0)
    let high = (i + radius + 1).min(samples.length())
    let mut sum = 0.0
    let mut j = low
    while j < high {
      sum = sum + samples[j] * samples[j]
      j = j + 1
    }
    out[i] = (sum / (high - low).to_double()).sqrt()
    i = i + 1
  }
  out
}

///|
/// Basic linear interpolation resampler for visualization and triggers.
pub fn resample_basic(
  samples : Array[Double],
  input_rate : Int,
  output_rate : Int,
) -> Array[Double] {
  if samples.is_empty() ||
    input_rate <= 0 ||
    output_rate <= 0 ||
    input_rate == output_rate {
    return samples.copy()
  }
  let output_length = (samples.length().to_double() *
    output_rate.to_double() /
    input_rate.to_double())
    .round()
    .to_int()
  let out : Array[Double] = Array::make(output_length.max(0), 0.0)
  let ratio = input_rate.to_double() / output_rate.to_double()
  let mut i = 0
  while i < output_length {
    let position = i.to_double() * ratio
    let left = position.floor().to_int().min(samples.length() - 1)
    let right = (left + 1).min(samples.length() - 1)
    let fraction = position - left.to_double()
    out[i] = samples[left] * (1.0 - fraction) + samples[right] * fraction
    i = i + 1
  }
  out
}

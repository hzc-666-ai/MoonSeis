# MoonSeis

Pure MoonBit toolkit for seismic waveform data parsing, quality control, and
STA/LTA event detection.

## Scope (phases 1-4)

- miniSEED 3 record parsing (fixed header, source identifier, extra headers, CRC-32C)
- Uncompressed sample decoding: Int16, Int32, Float32, Float64, Text, Opaque
- Continuous waveform (Trace) reconstruction with gap/overlap/duplicate detection
- Waveform quality rules and scoring
- Waveform preprocessing: detrend, taper, RMS, statistics
- Classic and Recursive STA/LTA event triggering
- JSON / CSV / GeoCSV / Markdown / terminal output
- Command-line tool under `cmd/main`

## Out of scope (later milestones)

Steim-1/2/3 decompression, miniSEED 2.4 reading, Wasm waveform viewer, full SARIF adapter.

> This library is for software development, education, and offline data
> analysis. Detected events are algorithmic candidates, not authoritative
> earthquake conclusions.

///|
/// Kind of discontinuity between adjacent record segments.
pub(all) enum SegmentKind {
  Gap
  Overlap
  Duplicate
  RateChange
} derive(Eq, Debug)

///|
pub(all) struct SegmentIssue {
  kind : SegmentKind
  at : @time.Time
  detail : String
} derive(Eq, Debug)

///|
pub fn SegmentIssue::kind(self : SegmentIssue) -> SegmentKind {
  self.kind
}

///|
pub fn SegmentIssue::at(self : SegmentIssue) -> @time.Time {
  self.at
}

///|
pub fn SegmentIssue::detail(self : SegmentIssue) -> String {
  self.detail
}

///|
pub(all) struct SegmentReport {
  gap_count : Int
  overlap_count : Int
  duplicate_count : Int
  rate_change_count : Int
  total_gap_seconds : Double
  issues : Array[SegmentIssue]
} derive(Eq, Debug)

///|
pub fn SegmentReport::gap_count(self : SegmentReport) -> Int {
  self.gap_count
}

///|
pub fn SegmentReport::overlap_count(self : SegmentReport) -> Int {
  self.overlap_count
}

///|
pub fn SegmentReport::duplicate_count(self : SegmentReport) -> Int {
  self.duplicate_count
}

///|
pub fn SegmentReport::rate_change_count(self : SegmentReport) -> Int {
  self.rate_change_count
}

///|
pub fn SegmentReport::total_gap_seconds(self : SegmentReport) -> Double {
  self.total_gap_seconds
}

///|
pub fn SegmentReport::issues(self : SegmentReport) -> Array[SegmentIssue] {
  self.issues
}

///|
/// Inspect adjacent records independently for each SID.
pub fn inspect_segments(records : Array[@record.Record]) -> SegmentReport {
  let issues : Array[SegmentIssue] = []
  let mut gap_seconds = 0.0
  let traces = build_traces(records)
  for trace in traces {
    let group = trace.records()
    let mut i = 1
    while i < group.length() {
      let previous = group[i - 1]
      let current = group[i]
      let at = current.start_time()
      if previous.start_time().to_epoch_ns() == at.to_epoch_ns() {
        issues.push({ kind: Duplicate, at, detail: "same SID and start time" })
      } else {
        match previous.end_time() {
          Some(previous_end) => {
            let delta = at.diff_secs(previous_end)
            let tolerance = if previous.header().rate_hz() > 0.0 {
              0.5 / previous.header().rate_hz()
            } else {
              0.0
            }
            if delta > tolerance {
              issues.push({ kind: Gap, at, detail: "gap of \{delta} seconds" })
              gap_seconds = gap_seconds + delta
            } else if delta < -tolerance {
              issues.push({
                kind: Overlap,
                at,
                detail: "overlap of \{-delta} seconds",
              })
            }
          }
          None => ()
        }
      }
      if previous.header().rate_hz() != current.header().rate_hz() {
        issues.push({ kind: RateChange, at, detail: "sample rate changed" })
      }
      i = i + 1
    }
  }
  let mut gaps = 0
  let mut overlaps = 0
  let mut duplicates = 0
  let mut rate_changes = 0
  for issue in issues {
    match issue.kind {
      Gap => gaps = gaps + 1
      Overlap => overlaps = overlaps + 1
      Duplicate => duplicates = duplicates + 1
      RateChange => rate_changes = rate_changes + 1
    }
  }
  {
    gap_count: gaps,
    overlap_count: overlaps,
    duplicate_count: duplicates,
    rate_change_count: rate_changes,
    total_gap_seconds: gap_seconds,
    issues,
  }
}

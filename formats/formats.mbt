///|
pub fn record_json(record : @record.Record) -> String {
  "{" +
  "\"sid\":\"\{json_escape(record.sid())}\"," +
  "\"encoding\":\{record.header().encoding()}," +
  "\"sample_rate\":\{record.header().rate_hz()}," +
  "\"sample_count\":\{record.header().sample_count()}," +
  "\"start_time\":\"\{record.start_time().to_iso8601()}\"," +
  "\"crc\":\{record.header().crc()}" +
  "}"
}

///|
pub fn inspect_json(records : Array[@record.Record]) -> String {
  let sids : Array[String] = []
  for record in records {
    if !sids.contains(record.sid()) {
      sids.push(record.sid())
    }
  }
  "{\"record_count\":\{records.length()},\"sources\":\{sids.length()}}"
}

///|
pub fn trace_csv(trace : @trace.Trace) -> String {
  let mut output = "sid,time_seconds,sample\n"
  if trace.records().is_empty() {
    let mut i = 0
    while i < trace.samples().length() {
      let seconds = if trace.sample_rate() > 0.0 {
        i.to_double() / trace.sample_rate()
      } else {
        0.0
      }
      output = output + "\{trace.sid()},\{seconds},\{trace.samples()[i]}\n"
      i = i + 1
    }
    return output
  }
  for record in trace.records() {
    let rate = record.header().rate_hz()
    let offset = record.start_time().diff_secs(trace.start_time())
    let samples = record.samples()
    let mut i = 0
    while i < samples.length() {
      let seconds = if rate > 0.0 {
        offset + i.to_double() / rate
      } else {
        offset
      }
      output = output + "\{trace.sid()},\{seconds},\{samples[i]}\n"
      i = i + 1
    }
  }
  output
}

///|
pub fn trace_geocsv(trace : @trace.Trace) -> String {
  "# dataset: GeoCSV 2.0\n# field_unit: second,count\n" + trace_csv(trace)
}

///|
pub fn events_markdown(events : Array[@trigger.Event]) -> String {
  let mut output = "# Events\n\n| Event | Start | End | Peak ratio | Confidence |\n|---:|---:|---:|---:|---:|\n"
  let mut index = 1
  for event in events {
    output = output +
      "| \{index} | \{event.start_index()} | \{event.end_index()} | \{fmt3(event.peak_ratio())} | \{fmt3(event.confidence())} |\n"
    index = index + 1
  }
  output
}

///|
pub fn analysis_json(
  items : Array[Result[@record.Record, @miniseed3.ParseError]],
) -> String {
  let records = valid_records(items)
  let traces = @trace.build_traces(records)
  let segments = @trace.inspect_segments(records)
  let mut total_samples = 0
  let mut total_events = 0
  let mut total_issues = 0
  let mut total_score = 0
  for trace in traces {
    total_samples = total_samples + trace.sample_count()
    let events = @trigger.classic_sta_lta(trace.samples())
    let report = @quality.inspect_trace(trace, @quality.default_rules())
    total_events = total_events + events.length()
    total_issues = total_issues + report.issue_count()
    total_score = total_score + report.score()
  }
  let average_score = if traces.is_empty() {
    0
  } else {
    (total_score.to_double() / traces.length().to_double()).round().to_int()
  }
  let mut out = "{"
  out = out + "\"schema\":\"moonseis.analysis.v1\","
  out = out + "\"summary\":{"
  out = out + "\"record_count\":\{items.length()},"
  out = out + "\"valid_records\":\{records.length()},"
  out = out + "\"parse_errors\":\{items.length() - records.length()},"
  out = out + "\"trace_count\":\{traces.length()},"
  out = out + "\"sample_count\":\{total_samples},"
  out = out + "\"event_count\":\{total_events},"
  out = out + "\"issue_count\":\{total_issues},"
  out = out + "\"average_score\":\{average_score}"
  out = out + "},"
  out = out + segment_report_json(segments) + ","
  out = out + parse_errors_json(items) + ","
  out = out + "\"traces\":["
  let mut trace_index = 0
  for trace in traces {
    if trace_index > 0 {
      out = out + ","
    }
    let report = @quality.inspect_trace(trace, @quality.default_rules())
    let events = @trigger.classic_sta_lta(trace.samples())
    out = out + trace_report_json(trace, report, events)
    trace_index = trace_index + 1
  }
  out = out + "]}"
  out
}

///|
fn valid_records(
  items : Array[Result[@record.Record, @miniseed3.ParseError]],
) -> Array[@record.Record] {
  let records : Array[@record.Record] = []
  for item in items {
    match item {
      Ok(record) => records.push(record)
      Err(_) => ()
    }
  }
  records
}

///|
fn segment_report_json(report : @trace.SegmentReport) -> String {
  let mut out = "\"segments\":{"
  out = out + "\"gap_count\":\{report.gap_count()},"
  out = out + "\"overlap_count\":\{report.overlap_count()},"
  out = out + "\"duplicate_count\":\{report.duplicate_count()},"
  out = out + "\"rate_change_count\":\{report.rate_change_count()},"
  out = out + "\"total_gap_seconds\":\{fmt3(report.total_gap_seconds())},"
  out = out + "\"issues\":["
  let mut index = 0
  for issue in report.issues() {
    if index > 0 {
      out = out + ","
    }
    out = out + "{"
    out = out + "\"kind\":\"\{segment_kind_name(issue.kind())}\","
    out = out + "\"at\":\"\{issue.at().to_iso8601()}\","
    out = out + "\"detail\":\"\{json_escape(issue.detail())}\""
    out = out + "}"
    index = index + 1
  }
  out = out + "]}"
  out
}

///|
fn parse_errors_json(
  items : Array[Result[@record.Record, @miniseed3.ParseError]],
) -> String {
  let mut out = "\"parse_errors\":["
  let mut item_index = 0
  let mut error_index = 0
  for item in items {
    match item {
      Ok(_) => ()
      Err(error) => {
        if error_index > 0 {
          out = out + ","
        }
        out = out +
          "{\"record_index\":\{item_index},\"message\":\"\{json_escape(error.to_string())}\"}"
        error_index = error_index + 1
      }
    }
    item_index = item_index + 1
  }
  out = out + "]"
  out
}

///|
fn trace_report_json(
  trace : @trace.Trace,
  report : @quality.QualityReport,
  events : Array[@trigger.Event],
) -> String {
  let metrics = report.metrics()
  let mut out = "{"
  out = out + "\"sid\":\"\{json_escape(trace.sid())}\","
  out = out + "\"start\":\"\{trace.start_time().to_iso8601()}\","
  out = out + "\"end\":\"\{trace.end_time().to_iso8601()}\","
  out = out + "\"sample_rate\":\{fmt3(trace.sample_rate())},"
  out = out + "\"duration_seconds\":\{fmt3(trace.duration_secs())},"
  out = out + "\"sample_count\":\{trace.sample_count()},"
  out = out + "\"record_count\":\{trace.records().length()},"
  out = out + "\"score\":\{report.score()},"
  out = out + "\"metrics\":{"
  out = out + "\"max_amplitude\":\{fmt3(metrics.max_amplitude())},"
  out = out + "\"mean\":\{fmt3(metrics.mean())},"
  out = out + "\"stddev\":\{fmt3(metrics.stddev())},"
  out = out + "\"clip_ratio\":\{fmt3(metrics.clip_ratio())},"
  out = out + "\"constant_runs\":\{metrics.constant_runs()},"
  out = out + "\"completeness\":\{fmt3(metrics.completeness())}"
  out = out + "},"
  out = out + quality_issues_json(report.issues()) + ","
  out = out + events_json(trace, events)
  out = out + "}"
  out
}

///|
fn quality_issues_json(issues : Array[@quality.Issue]) -> String {
  let mut out = "\"issues\":["
  let mut index = 0
  for issue in issues {
    if index > 0 {
      out = out + ","
    }
    out = out +
      "{\"severity\":\"\{severity_name(issue.severity())}\",\"message\":\"\{json_escape(issue.message())}\"}"
    index = index + 1
  }
  out = out + "]"
  out
}

///|
fn events_json(trace : @trace.Trace, events : Array[@trigger.Event]) -> String {
  let mut out = "\"events\":["
  let mut index = 0
  for event in events {
    if index > 0 {
      out = out + ","
    }
    out = out + "{"
    out = out + "\"start_index\":\{event.start_index()},"
    out = out + "\"end_index\":\{event.end_index()},"
    out = out +
      "\"start_time\":\"\{event_time_text(trace, event.start_index())}\","
    out = out + "\"end_time\":\"\{event_time_text(trace, event.end_index())}\","
    out = out + "\"peak_ratio\":\{fmt3(event.peak_ratio())},"
    out = out + "\"confidence\":\{fmt3(event.confidence())},"
    out = out + "\"type\":\"\{trigger_type_name(event.trigger_type())}\""
    out = out + "}"
    index = index + 1
  }
  out = out + "]"
  out
}

///|
pub fn analysis_html(traces : Array[@trace.Trace]) -> String {
  let mut total_records = 0
  let mut total_samples = 0
  let mut total_events = 0
  let mut total_issues = 0
  let mut total_score = 0
  for trace in traces {
    total_records = total_records + trace.records().length()
    total_samples = total_samples + trace.sample_count()
    let events = @trigger.classic_sta_lta(trace.samples())
    let report = @quality.inspect_trace(trace, @quality.default_rules())
    total_events = total_events + events.length()
    total_issues = total_issues + report.issue_count()
    total_score = total_score + report.score()
  }
  let average_score = if traces.is_empty() {
    0
  } else {
    (total_score.to_double() / traces.length().to_double()).round().to_int()
  }

  let mut output = "<!doctype html>\n"
  output = output + "<html lang=\"zh-CN\">\n"
  output = output + "<head>\n"
  output = output + "<meta charset=\"utf-8\">\n"
  output = output +
    "<meta name=\"viewport\" content=\"width=device-width, initial-scale=1\">\n"
  output = output + "<title>MoonSeis 分析报告</title>\n"
  output = output + "<style>\n"
  output = output +
    "body{font-family:system-ui,-apple-system,BlinkMacSystemFont,'Segoe UI',sans-serif;line-height:1.5;margin:0;background:#f6f8fb;color:#102033;}\n"
  output = output +
    ".wrap{max-width:1120px;margin:0 auto;padding:32px 20px 48px;}\n"
  output = output +
    ".hero{background:linear-gradient(135deg,#123b66,#1e78c8);color:#fff;border-radius:20px;padding:28px 32px;box-shadow:0 18px 50px rgba(18,59,102,.18);}\n"
  output = output + ".hero h1{margin:0 0 8px;font-size:32px;}\n"
  output = output + ".hero p{margin:6px 0 0;opacity:.92;}\n"
  output = output +
    ".grid{display:grid;grid-template-columns:repeat(auto-fit,minmax(180px,1fr));gap:14px;margin:20px 0;}\n"
  output = output +
    ".card{background:#fff;border-radius:16px;padding:18px 20px;box-shadow:0 8px 28px rgba(16,32,51,.08);}\n"
  output = output +
    ".card .label{font-size:12px;text-transform:uppercase;letter-spacing:.08em;color:#667;}\n"
  output = output +
    ".card .value{font-size:28px;font-weight:700;margin-top:6px;color:#102033;}\n"
  output = output +
    ".section{background:#fff;border-radius:20px;padding:24px 24px 10px;margin-top:20px;box-shadow:0 8px 28px rgba(16,32,51,.08);}\n"
  output = output + ".section h2{margin:0 0 12px;font-size:22px;}\n"
  output = output +
    ".meta{display:grid;grid-template-columns:repeat(auto-fit,minmax(220px,1fr));gap:10px;margin-bottom:14px;}\n"
  output = output +
    ".meta div,.issue,.event{background:#f8fbff;border:1px solid #e3edf9;border-radius:14px;padding:12px 14px;}\n"
  output = output +
    ".meta strong,.issue strong,.event strong{display:block;margin-bottom:4px;color:#102033;}\n"
  output = output +
    ".score{display:inline-block;padding:4px 10px;border-radius:999px;font-weight:700;}\n"
  output = output + ".score.good{background:#e6f7ee;color:#16794c;}\n"
  output = output + ".score.warn{background:#fff4db;color:#a16500;}\n"
  output = output + ".score.bad{background:#ffe4e4;color:#b42318;}\n"
  output = output +
    ".issues,.events{display:grid;gap:10px;margin:12px 0 20px;}\n"
  output = output +
    ".empty{color:#667;font-style:italic;padding:6px 2px 18px;}\n"
  output = output +
    ".table{width:100%;border-collapse:collapse;margin:8px 0 18px;}\n"
  output = output +
    ".table th,.table td{border-bottom:1px solid #e3edf9;padding:10px 8px;text-align:left;vertical-align:top;}\n"
  output = output +
    ".table th{font-size:13px;color:#445;letter-spacing:.02em;}\n"
  output = output +
    ".waveform{background:#f8fbff;border:1px solid #e3edf9;border-radius:16px;padding:12px;margin:10px 0 18px;}\n"
  output = output + ".waveform svg{display:block;width:100%;height:180px;}\n"
  output = output + ".axis{stroke:#d5e5f6;stroke-width:1;}\n"
  output = output +
    ".wave-line{fill:none;stroke:#1e78c8;stroke-width:2;stroke-linejoin:round;stroke-linecap:round;}\n"
  output = output + ".event-band{fill:#ffb020;opacity:.22;}\n"
  output = output + ".wave-caption{font-size:12px;color:#667;margin-top:6px;}\n"
  output = output + "</style>\n"
  output = output + "</head>\n"
  output = output + "<body>\n"
  output = output + "<div class=\"wrap\">\n"
  output = output + "<div class=\"hero\">\n"
  output = output + "<h1>MoonSeis 分析报告</h1>\n"
  output = output +
    "<p>miniSEED 3 波形解析、质量检查与事件候选检测结果。</p>\n"
  output = output + "</div>\n"
  output = output + "<div class=\"grid\">\n"
  output = output + metric_card("Trace", traces.length().to_string())
  output = output + metric_card("Record", total_records.to_string())
  output = output + metric_card("Sample", total_samples.to_string())
  output = output + metric_card("Event", total_events.to_string())
  output = output + metric_card("Issue", total_issues.to_string())
  output = output + metric_card("Avg score", average_score.to_string())
  output = output + "</div>\n"

  let mut index = 1
  for trace in traces {
    let report = @quality.inspect_trace(trace, @quality.default_rules())
    let events = @trigger.classic_sta_lta(trace.samples())
    output = output + trace_section_html(index, trace, report, events)
    index = index + 1
  }

  output = output + "</div>\n</body>\n</html>\n"
  output
}

///|
fn trace_section_html(
  index : Int,
  trace : @trace.Trace,
  report : @quality.QualityReport,
  events : Array[@trigger.Event],
) -> String {
  let mut out = "<section class=\"section\">\n"
  out = out + "<h2>#\{index} \{html_escape(trace.sid())}</h2>\n"
  out = out + "<div class=\"meta\">\n"
  out = out + meta_item("Start", trace.start_time().to_iso8601())
  out = out + meta_item("End", trace.end_time().to_iso8601())
  out = out + meta_item("Rate", fmt3(trace.sample_rate()) + " Hz")
  out = out + meta_item("Samples", trace.sample_count().to_string())
  out = out + meta_item("Duration", fmt3(trace.duration_secs()) + " s")
  out = out + meta_item("Score", report.score().to_string())
  out = out + "</div>\n"
  out = out +
    "<span class=\"score \{trace_score_class(report.score())}\">Score: \{report.score()}</span>\n"
  out = out + "<h3>Waveform preview</h3>\n"
  out = out + waveform_svg(trace, events)
  out = out + "<table class=\"table\">\n"
  out = out + "<tr><th>Metric</th><th>Value</th></tr>\n"
  out = out +
    "<tr><td>Max amplitude</td><td>\{fmt3(report.metrics().max_amplitude())}</td></tr>\n"
  out = out +
    "<tr><td>Mean</td><td>\{fmt3(report.metrics().mean())}</td></tr>\n"
  out = out +
    "<tr><td>Stddev</td><td>\{fmt3(report.metrics().stddev())}</td></tr>\n"
  out = out +
    "<tr><td>Clip ratio</td><td>\{fmt3(report.metrics().clip_ratio() * 100.0)}%</td></tr>\n"
  out = out +
    "<tr><td>Constant runs</td><td>\{report.metrics().constant_runs()}</td></tr>\n"
  out = out +
    "<tr><td>Completeness</td><td>\{fmt3(report.metrics().completeness() * 100.0)}%</td></tr>\n"
  out = out + "</table>\n"

  out = out + "<h3>Issues</h3>\n"
  if report.issues().is_empty() {
    out = out + "<div class=\"empty\">No issues found.</div>\n"
  } else {
    out = out + "<div class=\"issues\">\n"
    for issue in report.issues() {
      out = out + issue_item(issue)
    }
    out = out + "</div>\n"
  }

  out = out + "<h3>Events</h3>\n"
  if events.is_empty() {
    out = out + "<div class=\"empty\">No event candidates found.</div>\n"
  } else {
    out = out + "<table class=\"table\">\n"
    out = out +
      "<tr><th>#</th><th>Start</th><th>End</th><th>Peak ratio</th><th>Confidence</th><th>Type</th></tr>\n"
    let mut event_index = 1
    for event in events {
      out = out +
        "<tr><td>\{event_index}</td><td>\{event_time_text(trace, event.start_index())}</td><td>\{event_time_text(trace, event.end_index())}</td><td>\{fmt3(event.peak_ratio())}</td><td>\{fmt3(event.confidence())}</td><td>\{trigger_type_name(event.trigger_type())}</td></tr>\n"
      event_index = event_index + 1
    }
    out = out + "</table>\n"
  }
  out = out + "</section>\n"
  out
}

///|
fn waveform_svg(trace : @trace.Trace, events : Array[@trigger.Event]) -> String {
  let samples = trace.samples()
  if samples.is_empty() {
    return "<div class=\"empty\">No samples available for waveform preview.</div>\n"
  }
  let peak = peak_abs(samples)
  if peak == 0.0 {
    return "<div class=\"empty\">Waveform preview is flat: all samples are zero.</div>\n"
  }
  let width = 800.0
  let height = 180.0
  let pad = 12.0
  let mid = height / 2.0
  let plot_height = height - pad * 2.0
  let mut out = "<div class=\"waveform\">\n"
  out = out +
    "<svg viewBox=\"0 0 800 180\" role=\"img\" aria-label=\"Waveform preview\" preserveAspectRatio=\"none\">\n"
  out = out + "<line class=\"axis\" x1=\"0\" y1=\"90\" x2=\"800\" y2=\"90\"/>\n"
  for event in events {
    let x1 = sample_x(event.start_index(), samples.length(), width, pad)
    let x2 = sample_x(event.end_index(), samples.length(), width, pad)
    let band_width = (x2 - x1).abs().max(2.0)
    out = out +
      "<rect class=\"event-band\" x=\"\{fmt3(x1.min(x2))}\" y=\"0\" width=\"\{fmt3(band_width)}\" height=\"180\"/>\n"
  }
  out = out + "<polyline class=\"wave-line\" points=\""
  let max_points = 240
  let points = samples.length().min(max_points)
  let mut i = 0
  while i < points {
    let sample_index = if points <= 1 {
      0
    } else {
      (i.to_double() *
      (samples.length() - 1).to_double() /
      (points - 1).to_double())
      .round()
      .to_int()
    }
    let x = sample_x(sample_index, samples.length(), width, pad)
    let y = mid - samples[sample_index] / peak * (plot_height / 2.0)
    out = out + "\{fmt3(x)},\{fmt3(y)} "
    i = i + 1
  }
  out = out + "\"/>\n"
  out = out + "</svg>\n"
  out = out +
    "<div class=\"wave-caption\">Waveform preview: \{samples.length()} samples, peak amplitude \{fmt3(peak)}. Orange bands mark STA/LTA event candidates.</div>\n"
  out = out + "</div>\n"
  out
}

///|
fn sample_x(
  index : Int,
  sample_count : Int,
  width : Double,
  pad : Double,
) -> Double {
  if sample_count <= 1 {
    return width / 2.0
  }
  let clipped = index.max(0).min(sample_count - 1)
  pad +
  clipped.to_double() / (sample_count - 1).to_double() * (width - pad * 2.0)
}

///|
fn peak_abs(samples : Array[Double]) -> Double {
  let mut peak = 0.0
  for sample in samples {
    peak = peak.max(sample.abs())
  }
  peak
}

///|
fn metric_card(label : String, value : String) -> String {
  "<div class=\"card\"><div class=\"label\">\{html_escape(label)}</div><div class=\"value\">\{html_escape(value)}</div></div>\n"
}

///|
fn meta_item(label : String, value : String) -> String {
  "<div><strong>\{html_escape(label)}</strong>\{html_escape(value)}</div>\n"
}

///|
fn issue_item(issue : @quality.Issue) -> String {
  "<div class=\"issue\"><strong>\{severity_name(issue.severity())}</strong>\{html_escape(issue.message())}</div>\n"
}

///|
fn trace_score_class(score : Int) -> String {
  if score >= 80 {
    "good"
  } else if score >= 60 {
    "warn"
  } else {
    "bad"
  }
}

///|
fn severity_name(severity : @quality.Severity) -> String {
  match severity {
    Info => "Info"
    Warning => "Warning"
    Error => "Error"
    Critical => "Critical"
  }
}

///|
fn trigger_type_name(trigger_type : @trigger.TriggerType) -> String {
  match trigger_type {
    Classic => "Classic"
    Recursive => "Recursive"
  }
}

///|
fn segment_kind_name(kind : @trace.SegmentKind) -> String {
  match kind {
    Gap => "Gap"
    Overlap => "Overlap"
    Duplicate => "Duplicate"
    RateChange => "RateChange"
  }
}

///|
fn event_time_text(trace : @trace.Trace, index : Int) -> String {
  let rate = trace.sample_rate()
  if rate <= 0.0 {
    return "-"
  }
  let nanos = (index.to_double() / rate * 1.0e9).round().to_int64()
  trace.start_time().add_ns(nanos).to_iso8601()
}

///|
fn html_escape(value : String) -> String {
  let mut output = ""
  for char in value {
    let escaped = match char {
      '&' => "&amp;"
      '<' => "&lt;"
      '>' => "&gt;"
      '"' => "&quot;"
      '\'' => "&#39;"
      _ => String::make(1, char)
    }
    output = output + escaped
  }
  output
}

///|
fn fmt3(value : Double) -> String {
  ((value * 1000.0).round() / 1000.0).to_string()
}

///|
fn json_escape(value : String) -> String {
  let mut output = ""
  for char in value {
    let escaped = match char {
      '"' => "\\\""
      '\\' => "\\\\"
      '\n' => "\\n"
      '\r' => "\\r"
      '\t' => "\\t"
      _ => String::make(1, char)
    }
    output = output + escaped
  }
  output
}

///|
#borrow(path)
extern "C" fn read_file_bytes(path : String) -> Bytes = "moonseis_read_file_bytes"

///|
extern "C" fn exit_process(code : Int) -> Unit = "moonseis_exit_process"

///|
fn usage() -> Unit {
  println("MoonSeis - miniSEED 3 inspection and waveform analysis")
  println("")
  println("Usage: moon run cmd/main -- <command> <file> [format]")
  println(
    "Commands: inspect, records, validate, traces, quality, detect, convert",
  )
  println("Formats for convert: json, csv, geocsv, md, html, text")
}

///|
fn main {
  let args = @env.args()
  if args.length() >= 2 &&
    (args[1] == "help" || args[1] == "--help" || args[1] == "-h") {
    usage()
    return
  }
  if args.length() < 3 {
    usage()
    exit_process(1)
    return
  }
  let command = args[1]
  let path = args[2]
  let raw = read_file_bytes(path)
  if raw.length() == 0 {
    println("error: cannot read file or file is empty: \{path}")
    exit_process(1)
    return
  }
  match command {
    "inspect" => command_inspect(raw)
    "records" => command_records(raw)
    "validate" => if !command_validate(raw) { exit_process(2) }
    "traces" => command_traces(raw)
    "quality" => command_quality(raw)
    "detect" => command_detect(raw)
    "convert" =>
      if args.length() < 4 {
        println("error: convert requires a format")
        exit_process(1)
      } else if !command_convert(raw, args[3]) {
        exit_process(1)
      }
    _ => {
      println("error: unknown command '\{command}'")
      usage()
      exit_process(1)
    }
  }
}

///|
fn command_inspect(raw : Bytes) -> Unit {
  let items = @record.iterate_records(raw)
  let records = collect_records(items)
  let traces = @trace.build_traces(records)
  let segments = @trace.inspect_segments(records)
  let mut crc_failures = 0
  for item in items {
    match item {
      Err(BadCrc(_, _)) => crc_failures = crc_failures + 1
      _ => ()
    }
  }
  let mut sample_count = 0
  let mut event_count = 0
  for trace in traces {
    sample_count = sample_count + trace.sample_count()
    event_count = event_count +
      @trigger.classic_sta_lta(trace.samples()).length()
  }
  println("Records:       \{items.length()}")
  println("Valid:         \{records.length()}")
  println("Errors:        \{items.length() - records.length()}")
  println("CRC failures:  \{crc_failures}")
  println("Sources:       \{traces.length()}")
  println("Samples:       \{sample_count}")
  if !traces.is_empty() {
    let mut start = traces[0].start_time()
    let mut end = traces[0].end_time()
    for trace in traces {
      if trace.start_time().to_epoch_ns() < start.to_epoch_ns() {
        start = trace.start_time()
      }
      if trace.end_time().to_epoch_ns() > end.to_epoch_ns() {
        end = trace.end_time()
      }
    }
    println("Start:         \{start.to_iso8601()}")
    println("End:           \{end.to_iso8601()}")
  }
  println("Gaps:          \{segments.gap_count()}")
  println("Overlaps:      \{segments.overlap_count()}")
  println("Duplicates:    \{segments.duplicate_count()}")
  println("Rate changes:  \{segments.rate_change_count()}")
  println("Events:        \{event_count}")
}

///|
fn command_records(raw : Bytes) -> Unit {
  println("idx\tstatus\tsid\tstart\tcount\trate")
  let mut index = 1
  for item in @record.iterate_records(raw) {
    match item {
      Ok(record) =>
        println(
          "\{index}\tok\t\{record.sid()}\t\{record.start_time().to_iso8601()}\t\{record.header().sample_count()}\t\{record.header().rate_hz()}",
        )
      Err(error) => println("\{index}\terror\t-\t-\t-\t\{error.to_string()}")
    }
    index = index + 1
  }
}

///|
fn command_validate(raw : Bytes) -> Bool {
  let mut valid = 0
  let mut errors = 0
  for item in @record.iterate_records(raw) {
    match item {
      Ok(record) => {
        valid = valid + 1
        println("ok\t\{record.sid()}")
      }
      Err(error) => {
        errors = errors + 1
        println("fail\t\{error.to_string()}")
      }
    }
  }
  println("summary\tok=\{valid}\terrors=\{errors}")
  errors == 0
}

///|
fn command_traces(raw : Bytes) -> Unit {
  println("Trace\tStart\tEnd\tRate\tSamples")
  for trace in parsed_traces(raw) {
    println(
      "\{trace.sid()}\t\{trace.start_time().to_iso8601()}\t\{trace.end_time().to_iso8601()}\t\{trace.sample_rate()}\t\{trace.sample_count()}",
    )
  }
}

///|
fn command_quality(raw : Bytes) -> Unit {
  for trace in parsed_traces(raw) {
    let report = @quality.inspect_trace(trace, @quality.default_rules())
    println(
      "\{trace.sid()}\tscore=\{report.score()}\tissues=\{report.issue_count()}",
    )
    for issue in report.issues() {
      println("  \{severity_name(issue.severity())}\t\{issue.message()}")
    }
  }
}

///|
fn command_detect(raw : Bytes) -> Unit {
  for trace in parsed_traces(raw) {
    let events = @trigger.classic_sta_lta(trace.samples())
    println("\{trace.sid()}\t\{events.length()} event(s)")
    let mut index = 1
    for event in events {
      let offset = if trace.sample_rate() > 0.0 {
        (event.start_index().to_double() / trace.sample_rate() * 1.0e9)
        .round()
        .to_int64()
      } else {
        0L
      }
      println(
        "  #\{index}\t\{trace.start_time().add_ns(offset).to_iso8601()}\tpeak=\{event.peak_ratio()}\tconfidence=\{event.confidence()}",
      )
      index = index + 1
    }
  }
}

///|
fn command_convert(raw : Bytes, format : String) -> Bool {
  let records = collect_records(@record.iterate_records(raw))
  let traces = @trace.build_traces(records)
  match format {
    "json" => println(@formats.inspect_json(records))
    "csv" =>
      for trace in traces {
        println(@formats.trace_csv(trace))
      }
    "geocsv" =>
      for trace in traces {
        println(@formats.trace_geocsv(trace))
      }
    "md" =>
      for trace in traces {
        println(
          @formats.events_markdown(@trigger.classic_sta_lta(trace.samples())),
        )
      }
    "html" => println(@formats.analysis_html(traces))
    "text" =>
      for trace in traces {
        print_waveform(trace)
      }
    _ => {
      println("error: unknown format '\{format}'")
      return false
    }
  }
  true
}

///|
fn print_waveform(trace : @trace.Trace) -> Unit {
  println("# \{trace.sid()}")
  let scale = @signal.peak(trace.samples())
  if scale == 0.0 {
    println("(no signal)")
    return
  }
  for sample in trace.samples() {
    let column = (sample / scale * 20.0 + 20.0).round().to_int().max(0).min(40)
    let mut line = ""
    let mut i = 0
    while i < 41 {
      let mark = if i == column { "*" } else if i == 20 { "|" } else { " " }
      line = line + mark
      i = i + 1
    }
    println(line)
  }
}

///|
fn parsed_traces(raw : Bytes) -> Array[@trace.Trace] {
  @trace.build_traces(collect_records(@record.iterate_records(raw)))
}

///|
fn collect_records(
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
fn severity_name(severity : @quality.Severity) -> String {
  match severity {
    Info => "info"
    Warning => "warning"
    Error => "error"
    Critical => "critical"
  }
}

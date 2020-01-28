require "./main"

class Prog < Main
  var logger : Logger = Pretty::Logger.new(STDERR)

  def execute
    watch   = Pretty::Stopwatch.new.start

    # command line variables
    header   = false
    fields   = "0"
    colorize = true
    silent   = false
    quiet    = false
    verbose  = false
    interval = 1
    limit    = 1_000_000
    delta    = 0.001
    type     = ""

    output_path = nil
    
    # parse command line arguments
    parser = OptionParser.new do |parser|
      parser.banner = "Usage: %s [OPTION]... TSV1 TSV2" % File.basename(PROGRAM_NAME)

      parser.on("-H", "--header", "Use first line as header") { header = true }
      parser.on("-f", "--fields=LIST", "Use theses fields as primary keys") { |v| fields = v }
      parser.on("-t NAME", "--type=TYPE", "Specifies the type (ex. ad2)") { |v| type = v }
      parser.on("-l LOG", "--log=LOG", "Specifies the output log file name") { |v| output_path = v }
      parser.on("-L MAX", "--limit=MAX", "Specifies the number of max input files") { |v| limit = v.to_i }
      parser.on("-p SEC", "--progress=SEC", "Specify progress interval seconds") { |v| interval = v.to_i }
      parser.on("--delta FLOAT", "Threshold for the same float value (default: #{delta})") { |v|  delta = v.to_f }
      parser.on("--no-color", "Disable colored output") { colorize = false }
      parser.on("-s", "--silent", "Silent mode. No progress, but show similarity value") { silent = true }
      parser.on("-q", "--quiet", "Quiet mode. Print nothing without errors") { quiet = true }
      parser.on("-v", "Verbose") { verbose = true }
      parser.on("-h", "--help", "Show this help") { puts parser; exit(0) }
    end
    parser.parse
    
    # input files
    path1 = ARGV.shift? || raise ArgumentError.new("Requires two files. But TSV1 is missing")
    path2 = ARGV.shift? || raise ArgumentError.new("Requires two files. But TSV2 is missing")

    # logger
    if path = output_path
      self.logger = Logger.new(File.new(path, "w+"))
    end
#    logger.formatter = "{{mark}},[{{time=%H:%M:%S}}] {{message}}"
    logger.colorize = true
    logger.level = (verbose ? "DEBUG" : "INFO")
    if silent || quiet
      logger.level = "FATAL"
      interval = Int32::MAX
    end
    
    # primary keys
    keys = ["0"]
    keys = fields.split(",") if !fields.empty?
    keys = keys.map(&.to_i) if keys.all?(&.=~ /^\d+$/)
    keys.any? || raise ArgumentError.new("Specify primary keys by '-t' or '-f'")

    # load tsv
    use_basename = ! (File.basename(path1) == File.basename(path2))
    src1 = load_src(path1, basename: use_basename)
    src2 = load_src(path2, basename: use_basename)

    # assume the first line is header when it starts with '#'
    header ||= src1.first?.try(&.first?.try(&.starts_with?("#")))
    
    diff = DiffTsv::Diff.new(src1, src2, keys: keys, header: header)
    diff.logger = logger
    diff.delta  = delta
    diff.progress.interval = interval
    diff.execute

    if quiet
      buf = ""
    elsif silent
      buf = (diff.similarity_pct? || 0).to_s
    else
      buf = "%s (%s) %s" % [diff.result_buffer.to_s.chomp, watch.stop.last, proc_mem]
    end
    STDOUT.puts buf if !buf.empty?
    logger.info buf if output_path
    exit(diff.result_code)
  end

  private def load_src(path : String, basename = false) : Array(Array(String))
    watch = Pretty::Stopwatch.new
    rows  = watch.measure{ CSV.parse(File.read(path), separator: '\t') }
    bytes = Pretty.bytes(File.size(path), prefix: "")
    file  = basename ? File.basename(path) : path
    # Loaded 500580 rows (35.9MB) in 1.0 sec # out
    logger.info "Loaded #{rows.size} rows (#{bytes}) in #{watch.last} # #{file}" 
    return rows
  rescue err : Errno
    raise Halt.new(err.to_s, code: 1)
  end
end

Prog.main

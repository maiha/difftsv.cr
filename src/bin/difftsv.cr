require "./main"

class Prog < Main
  var logger : Logger = Pretty::Logger.new(STDERR)
  var colorize = true

  def execute
    watch   = Pretty::Stopwatch.new.start

    # command line variables
    header   = false
    fields   = "0"
    strategy = DiffTsv::Loader::Strategy::CSV
    silent   = false
    quiet    = false
    verbose  = false
    interval = 1
    delta    = 0.001
    version  = false

    output_path = nil
    
    # parse command line arguments
    parser = OptionParser.new do |parser|
      parser.banner = "Usage: %s [OPTION]... TSV1 TSV2" % File.basename(PROGRAM_NAME)

      parser.on("-H", "--header", "Use first line as header") { header = true }
      parser.on("-f", "--fields=LIST", "Specify primary keys (1 origin)") { |v| fields = v }
      parser.on("-L", "--loader=LOADER", "'csv' or 'donkey'") { |v| strategy = DiffTsv::Loader::Strategy.parse?(v) || abort "loader must be one of %s" % DiffTsv::Loader::Strategy.values.inspect }
      parser.on("-l", "--log=LOG", "Specify the output log file name") { |v| output_path = v }
      parser.on("-p", "--progress=SEC", "Specify progress interval seconds") { |v| interval = v.to_i }
      parser.on("--delta FLOAT", "Threshold for the same float value (default: #{delta})") { |v|  delta = v.to_f }
      parser.on("--no-color", "Disable colored output") { self.colorize = false }
      parser.on("-s", "--silent", "Silent mode. No progress, but show similarity value") { silent = true }
      parser.on("-q", "--quiet", "Quiet mode. Print nothing without errors") { quiet = true }
      parser.on("-v", "--verbose", "Verbose mode") { verbose = true }
      parser.on("-V", "--version", "Show version") { version = true }
      parser.on("-h", "--help", "Show this help") { puts parser; exit(0) }
    end
    parser.parse

    # "--version"
    if version
      STDOUT.puts "%s %s" % [File.basename(PROGRAM_NAME), Shard.git_description.split(/\s+/, 2).last]
      exit(0)
    end
    
    # input files
    path1 = ARGV.shift? || raise ArgumentError.new("Requires two files. But TSV1 is missing")
    path2 = ARGV.shift? || raise ArgumentError.new("Requires two files. But TSV2 is missing")

    # logger
    if path = output_path
      self.logger = Logger.new(File.new(path, "w+"))
    end
    logger.colorize = colorize
    logger.level = (verbose ? "DEBUG" : "INFO")
    if silent || quiet
      logger.level = "FATAL"
      interval = Int32::MAX
    end
    
    # load tsv
    use_basename = ! (File.basename(path1) == File.basename(path2))
    src1 = load_src(path1, basename: use_basename, strategy: strategy)
    src2 = load_src(path2, basename: use_basename, strategy: strategy)

    # primary keys (needs fields.size to resolve "-f 5-")
    keys = normalize_keys(fields, lookup_fields_size?(src1, src2))
    keys.any? || raise ArgumentError.new("Specify primary keys by '-t' or '-f'")

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

  private def lookup_fields_size?(*srcs) : Int32?
    size = nil
    srcs.each do |src|
      size ||= src.try(&.first.try(&.size))
    end
    return size
  end

  private class StringKeyFound < Exception; end

  # user inputs   : 1 origins
  # internal vals : 0 origins
  private def normalize_key(user_input : String) : Int32
    v = user_input.to_i? || abort "[BUG] normalize key error: #{user_input}"
    if v > 0
      return v - 1
    else
      abort "field index must be > 0, but got #{v}"
    end
  end

  private def normalize_keys(fields : String, size : Int32?)
    # "".split(",") # => [""]
    str_set = Set(String).new( fields.empty? ? %w() : fields.split(",") )

    begin
      set = Set(Int32).new
      str_set.each do |key|
        case key
        when /^(\d+)$/            # "1"
          set << normalize_key($1)
        when /^(\d+)-$/           # "1-"
          if size
            set.concat(normalize_key($1) ... size)
          else
            set << normalize_key($1)
          end
        when /^-(\d+)$/           # "-1"
          set.concat(0 .. normalize_key($1))
        when /^(\d+)-(\d+)$/      # "1-3"
          set.concat(normalize_key($1) .. normalize_key($2))
        else
          raise StringKeyFound.new
        end
      end
      return set.to_a
    rescue StringKeyFound
      return str_set.to_a
    end    
  end

  private def load_src(path : String, strategy, basename = false) : Array(Array(String))
    watch = Pretty::Stopwatch.new
    rows  = watch.measure{ DiffTsv::Loader.new(path, strategy).load }
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

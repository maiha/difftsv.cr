class DiffTsv::Diff
  alias Keys = Array(Int32) | Array(String)

  # input
  var src1 : Array(Array(String))
  var src2 : Array(Array(String))

  # output
  var similarity_pct : Float64
  var result_buffer = IO::Memory.new
  var left  : Array(RowSimilarity)
  var both  : Array(RowSimilarity)
  var right : Array(RowSimilarity)
  
  # config
  var primary_keys       : Array(Int32)
  var delta              : Float64 = 0.001
  var output_sample_size : Int32   = 3     # number of sample rows
  var progress = Pretty::Periodical::Executor.new
  var logger   = Logger.new(nil)

  # internal variables
  private var header      : Header
  private var value_keys  : Array(Int32)
  private var rows_offset : Int32 = 0
  
  private var size1 : Int32
  private var size2 : Int32
  
  private var rows1 = src1.map_with_index{|vals, i| Row.new(encode_key(vals), vals, i)}
  private var rows2 = src2.map_with_index{|vals, i| Row.new(encode_key(vals), vals, i)}
  private var keys1 = rows1.map(&.key).to_set
  private var keys2 = rows2.map(&.key).to_set

  # internal variables (provide getter)
  def value_keys; @value_keys.not_nil!; end
  
  def initialize(@src1, @src2, header = nil, keys : Keys = [0], vals : Keys? = nil)
    @header       = build_header(header)
    @primary_keys = build_primary_keys(keys)

    primary_keys.must.any? || raise ArgumentError.new("primary keys not found")
    self.header.any?       || raise ArgumentError.new("header is empty")
    @value_keys = (0...self.header.num_columns).to_a - primary_keys
  end

  private def build_primary_keys(keys : Array(Int32)) : Array(Int32)
    return keys
  end

  private def build_primary_keys(keys : Array(String)) : Array(Int32)
    return keys.map{|key|
      header.names.index(key) || raise ArgumentError.new("Primary key(str:#{key.inspect}) is not found in header(#{header.names.inspect})")
    }
  end

  private def build_header(given_header : Bool | Array(String) | Nil ) : Header
    case given_header
    when true
      self.rows_offset = 1
      src2.shift?             # TODO: check header1 and header2?
      if ary = src1.shift?
        return Header.new(ary)
      end
    when Array(String)
      return Header.new(given_header)
    end

    return Header.new(src1.first?.try(&.size))
  end
  
  def execute : Diff
    logger.debug "header       : %s" % header
    logger.debug "primary keys : %s" % primary_keys.inspect
    logger.debug "value keys   : %s" % value_keys.inspect

    # compare keys
    diff_keys

    # compare rows
    diff_rows

    return self
  end

  # compats with `diff(1)`
  def result_code
    case similarity_pct?
    when 100   ; 0 # inputs are the same
    when Float ; 1 # different
    else       ; 2 # trouble
    end
  end

  # compare keys
  protected def diff_keys
    diff = keys1 ^ keys2
    if sample = diff.first?
      msg = "entry: mismatch %d rows (ex. %s)" % [diff.size, sample.inspect]
      logger.info msg
    else
      logger.debug "entry: %d rows" % [keys1.size]
    end
  end

  # compare rows
  # [target]
  #   - value_keys
  # [output]
  #   - Different
  #   - Worst similarity
  #   - Similarity distribution
  # [how]
  #   1. Classify into 3 groups by primary key (left,both,right)
  #   2. Calculate similarity ratio (%) for elements of all groups
  #     - left : 0.0 (Lowest similarity rate due to no peers)
  #     - both : `Dump::similarity#pct_f`
  #     - right: 0.0 (Lowest similarity rate due to no peers)
  #   3. Calculate average value of similarity
  protected def diff_rows
    # 1. Classify into 3 groups by primary key (left,both,right)
    # 2. Calculate similarity ratio (%) for elements of all groups
    left, both, right = build_left_both_right
    all = left + both + right
    
    # [left] only in TSV1
    if sample = left.first?
      result_buffer.puts "keys only in left : %d rows (ex. %s)" % [left.size, sample]
    end

    # [right] only in TSV2
    if sample = right.first?
      result_buffer.puts "keys only in right: %d rows (ex. %s)" % [right.size, sample]
    end

    diffs = both.select(&.different?)
    if diffs.any?
      # [Different]
      result_buffer.puts "[Different] (first %d)" % output_sample_size
      diffs.first(output_sample_size).each do |sim|
        result_buffer.puts "  #{sim}"
      end

      # [Worst similarity]
      result_buffer.puts "[Worst similarity] (top %d)" % output_sample_size
      ary = diffs.sort_by(&.pct)
      ary.first(output_sample_size).each do |sim|
        result_buffer.puts "  #{sim}"
      end
    end

    # [Similarity distribution]
    result_buffer.puts "[Similarity distribution] (%d rows)" % all.size

    ng   = diffs.size
    ok   = all.size - ng
    rest = all.map(&.pct) # Pct array not displayed yet

    thresholds = {"100%"=>100," 95%"=>95," 90%"=>90," 80%"=>80," ---"=>0}
    thresholds.each do |label, limit|
      cnt = rest.count{|i| i >= limit}
      rest.reject!{|i| i >= limit}
      bar = Pretty::Bar.new(val: cnt, max: all.size, width: 30)
      result_buffer.puts "  #{label}: #{bar}"
    end

    # 3. Calculate average value of similarity
    self.similarity_pct = (all.map(&.pct).sum / all.size rescue 0.0)
    pct_s = (similarity_pct == 100) ? "100" : "%.3f" % similarity_pct
    result_buffer.puts "Similarity: %s" % pct_s
  end

  private def build_left_both_right
    self.left  = Array(RowSimilarity).new # exists in only src1
    self.both  = Array(RowSimilarity).new # exists in both
    self.right = Array(RowSimilarity).new # exists in only src2

    hash1 = Hash(String, Row).new    # key1 => row
    hash2 = Hash(String, Row).new    # key2 => row

    size_width = src1.size.to_s.size # 86470 => 5

    rows1.each do |row|
      key = row.key
      if prev = hash1[key]?
        halt("src1: Found duplicated key %s (line:%s, line:%s)" % [key.inspect, lineno(prev), lineno(row)])
      end
      hash1[key] = row
    end
    logger.debug "hash1: done"
    
    rows2.each do |row|
      key = row.key
      if prev = hash2[key]?
        halt("src2: Found duplicated key %s (line:%s, line:%s)" % [key.inspect, lineno(prev), lineno(row)])
      end
      hash2[key] = row
    end
    logger.debug "hash2: done"

    # left
    hash1.each_with_index do |(key, row), i|
      unless hash2[key]?
        clue = "line:%#{size_width}d [%s] left only" % [lineno(row), key]
        left << RowSimilarity.new(key: key, pct: 0.0, clue: clue)
      end
      show_progress("left : checking...", i+1, hash1.size)
    end
    logger.debug "left : done"
    
    # right
    hash2.each_with_index do |(key, row), i|
      unless hash1[key]?
        clue = "line:%#{size_width}d [%s] right only" % [lineno(row), key]
        right << RowSimilarity.new(key: key, pct: 0.0, clue: clue)
      end
      show_progress("right: checking...", i+1, hash2.size)
    end
    logger.debug "right: done"

    # both
    target_keys = (keys1 & keys2)
    target_keys.each_with_index do |key, i|
      row1 = hash1[key] || halt("[BUG] row1[#{key}] not found")
      row2 = hash2[key] || halt("[BUG] row2[#{key}] not found")
      sim  = similarity(row1, row2, delta)
      clue = "line:%#{size_width}d [%s] %s" % [lineno(row1), key, sim]
      both << RowSimilarity.new(key: key, pct: sim.pct_f, clue: clue)
      show_progress("both : checking...", i+1, target_keys.size)
    end
    logger.debug "both : done"

    return {left, both, right}
  end    
  
  # Calculate similarities in all fields and return the lowest one
  private def similarity(row1, row2, delta) : Similarity
    value_keys.map{|index| calculate_similarity(row1, row2, index, delta)}.sort_by(&.pct_f).first
  end

  # Calculate similarity in the given field
  private def calculate_similarity(row1, row2, index, delta) : Similarity
    v1 = row1.vals[index]?
    v2 = row2.vals[index]?

    if v1 == nil && v2 == nil
      pct = 100.0
    elsif v1 == nil || v2 == nil
      pct = 0.0
    elsif (v1 =~ /^-?\d+$/) && (v2 =~ /^-?\d+$/)
      # [case] {int, int}
      pct = (v1 == v2) ? 100.0 : 0.0
    elsif (v1 =~ /^-?\d+(\.\d+)?$/) && (v2 =~ /^-?\d+(\.\d+)?$/)
      # [case] {float, (float | int)}
      v1 = v1.to_s.to_f
      v2 = v2.to_s.to_f
      diff = (v1 - v2).abs
      if diff <= delta
        pct = 100.0
      else
        max = [v1, v2].max
        pct = (max - (v1 - v2).abs) * 100.0 / max
      end
      # If it is too long, the diff is hard to see, so make it about 8 digits
      v1 = v1.try(&.round(8))
      v2 = v2.try(&.round(8))
    else
      # [case] {string, *}
      pct = (v1 == v2) ? 100.0 : 0.0
    end

    field = header.name?(index) || "col#{index}"
    sim   = Similarity.new(field, pct, v1, v2)
    # logger.debug "calculate_similarity(%s, %s, %s, %s) => %s" % [row1.key, row2.key, index, delta, sim]
    return sim
  end
  
  private def show_progress(name, n, max)
    progress.execute do
      w   = max.to_s.size
      pct = n*100//max
      logger.info "%s %3d%% (%#{w}d/%#{w}d)" % [name, pct, n, max]
    end
  end

  private def encode_key(vals : Array(String))
    primary_keys.map{|index| vals[index]?.to_s}.join(",")
  end
  
  private def lineno(row : Row)
    (row.index + 1) + rows_offset
  end

  private def halt(msg, code = 100)
    raise Halt.new(msg, code)
  end

  def to_s(io : IO)
    io << "src1:%d, src2:%d, pk:%s" % [@size1, @size2, @primary_columns.inspect]
  end
end

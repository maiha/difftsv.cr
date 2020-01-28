class DiffTsv::Similarity
  var field : String  # Field name of lowest similarity
  var pct_f : Float64 # Percent of lowest similarity (0.0～100.0)
  var msg   : String

  def initialize(@field, @pct_f, v1, v2)
    @msg = "%s: %d%% (%s, %s)" % [field, pct, v1.inspect, v2.inspect]
  end

  def different?
    pct_f < 100
  end

  def pct : Int32
    case pct_f
    when        0 ; 0
    when  0...  1 ; 1
    when 99...100 ; 99
    else          ; pct_f.trunc.to_i32
    end
  end

  def to_s(io : IO)
    io << @msg
  end
end

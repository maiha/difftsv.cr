module DiffTsv
  record RowSimilarity, key : String, pct : Float64, clue : String do
    def different?; pct < 100; end
    def to_s(io : IO); io << clue; end
  end
end

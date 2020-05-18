class DiffTsv::Loader
  enum Strategy
    CSV
    DONKEY
  end

  abstract class StrategyImpl
    abstract def load(path : String) : Array(Array(String))
  end

  class CsvStrategy < StrategyImpl
    def load(path : String) : Array(Array(String))
      CSV.parse(File.read(path), separator: '\t')
    end
  end

  class DonkeyStrategy < StrategyImpl
    def load(path : String) : Array(Array(String))
      array = Array(Array(String)).new
      File.each_line(path) do |line|
        array << line.split('\t')
      end
      return array
    end
  end

  var path     : String
  var strategy : StrategyImpl

  def initialize(@path, strategy)
    self.strategy = strategy
  end

  def load
    strategy.load(path)
  end
  
  def strategy=(name : String)
    self.strategy = Strategy.parse(name)
  end

  def strategy=(name : Strategy)
    case name
    when .csv?
      @strategy = CsvStrategy.new
    when .donkey?
      @strategy = DonkeyStrategy.new
    end
  end
end

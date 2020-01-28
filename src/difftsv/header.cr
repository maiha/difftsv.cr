class DiffTsv::Header
  var names : Array(String)
  var num_columns : Int32

  def initialize(vals : Array(String))
    self.names = vals
    self.num_columns = vals.size
  end

  def initialize(@num_columns : Int32?)
  end

  def empty? : Bool
    (num_columns? || 0) == 0
  end

  def any? : Bool
    ! empty?
  end

  def num_columns
    num_columns? || raise ArgumentError.new("num_columns: Header is not set yet")
  end

  def names
    names? || raise ArgumentError.new("Cannot resolve header names")
  end

  def name?(index : Int32) : String?
    names?.try{|a| a[index]?}
  end
end

module DiffTsv
  class Halt < Exception
    var code : Int32
    def initialize(msg, @code)
      super(msg)
    end
  end
end

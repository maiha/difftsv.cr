require "shard"
require "../difftsv"
require "./helper"

class Main
  include DiffTsv
  include Helper
  
  var colorize = true

  def self.run(&block)
    new.run(&block)
  end

  def self.main
    new.run
  end

  def run(&block)
    block.call
  rescue err
    on_error(err)
  end

  def run
    run { execute }
  end
  
  def execute
  end

  private def on_error(err)
    case err
    when Halt
      STDERR.puts red(err.to_s)
      exit(err.code)
    when ArgumentError | OptionParser::Exception
      STDERR.puts red(err.to_s)
      STDERR.puts red("Try '%s --help' for more information." % File.basename(PROGRAM_NAME))
      exit(2)
    else
      STDERR.puts red(err.inspect_with_backtrace)
      exit(100)
    end
  end

  protected def proc_mem(format = "MEM:%s")
    mem = Pretty::MemInfo.process.max.to_s rescue "---"
    format % mem
  end
end

module Helper
  protected def colorize(msg : String, color)
    msg.colorize(color)
  end

  # colorize methods
  # - check config.colorize
  # - handy shortcuts for colors
  {% for color in %w( green cyan yellow red ) %}
    protected def {{color.id}}(msg : String)
      colorize(msg, :{{color.id}})
    end
  {% end %}
end

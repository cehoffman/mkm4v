class Pathname
  alias_method :to_str, :to_s unless respond_to?(:to_str)

  def extname=(ext)
    Pathname.new to_s.gsub(/\.[^\.]*$/, ".#{ext}")
  end
end
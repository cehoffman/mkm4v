require "tempfile"

class Pathname
  alias_method :to_str, :to_s unless respond_to?(:to_str)

  def =~(other)
    self.to_s =~ other
  end

  alias_method :extname_read, :extname
  def extname(ext = nil)
    ext && Pathname.new(self.to_s.gsub(/\.[^\.]*$/, ".#{ext}")) || extname_read
  end

  def self.tmpfile(name, extname = nil)
    tmp = (Pathname.new(Dir.tmpdir) + File.basename(name))
    extname && (tmp.extname extname) || tmp
  end
end
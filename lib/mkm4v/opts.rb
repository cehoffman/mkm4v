require "trollop"

Mkm4v::Opts = Trollop.options do
  version "#{$0} #{Mkm4v::Version} (c) 2010 Chris Hoffman"
  banner <<-EOS
    Usage: #{$0} [options] <filenames>+
  EOS

  # opt :input, "List of input files", type: :strings
end
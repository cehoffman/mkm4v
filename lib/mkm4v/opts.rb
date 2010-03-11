require "trollop"

Mkm4v::Opts = Trollop.options do
  version "#{$0} #{Mkm4v::Version} (c) 2010 Chris Hoffman"
  banner <<-EOS.undent
    Usage: #{$0} [options] -i <filename> [filename ...]
 \n
  EOS

  opt :input, "List of files to convert", type: :strings
end
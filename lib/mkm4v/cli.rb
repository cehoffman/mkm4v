require "trollop"

class Mkm4v::Cli
  Opts = Trollop::Parser.new do
    version "#{$0} Version #{Mkm4v::Version} Copyright (C) 2010 Chris Hoffman"
    banner <<-EOS.undent
      Usage: #{$0} [options] -i <filename> [filename ...]
 \n
    EOS

    opt :input, "List of files to convert", type: :strings
  end

  def self.run(*args)
    Opts.parse args
  rescue Trollop::CommandlineError => e
    Opts.educate
    warn "\nError: #{e.message}"
    exit 1
  rescue Trollop::HelpNeeded
    Opts.educate
    exit
  rescue Trollop::VersionNeeded
    puts Opts.version
    exit
  end
end
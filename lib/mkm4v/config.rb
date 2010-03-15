require "trollop"

module Mkm4v::Config
  def self.included(klass)
    klass.extend ClassMethods
  end

  def config
    Mkm4v::Config::ClassMethods.class_variable_get(:@@config)
  end

  module ClassMethods
    Opts = Trollop::Parser.new do
      version "mkm4v Version #{Mkm4v::Version} Copyright (C) 2010 Chris Hoffman"
      banner "Usage: mkm4v [options] -i <filename> [filename ...]\n \n"

      opt :input, "List of files to convert", type: :strings, required: true
    end

    def parse(*args)
      @@config = Opts.parse args
    rescue Trollop::CommandlineError => e
      Opts.educate
      warn "\nError: #{e.message}"
      exit 1
    rescue Trollop::HelpNeeded
      Opts.educate
      exit 1
    rescue Trollop::VersionNeeded
      puts Opts.version
      exit
    end

    def config
      @@config
    end
  end
end
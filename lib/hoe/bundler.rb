module Hoe::Bundler
  Version = '0.1.0'

  def initialize_bundler
    GemDeps[:default].each { |dep| self.extra_deps << dep }
    GemDeps[:dev].each { |dep| self.extra_dev_deps << dep }
  end

  class GemDeps
    def self.method_missing(*args); end

    def self.gem(name, version, *rest)
      (@@deps[@@group] ||= []) << [name, version]
    end

    def self.group(name, &block)
      @@group = name
      instance_eval &block
      @@group = :default
    end

    def self.[](key)
      @@deps[key]
    end

    @@deps = {}
    @@group = :default
    instance_eval File.read("Gemfile")
  end
end
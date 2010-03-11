module Kernel
  def microsoft?
    processor, platform, *rest = RUBY_PLATFORM.split("-")
    platform =~ /(win|mingw|cygwin)(32|64)?$/
  end
end
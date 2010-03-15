module Mkm4v::Cli
  include Mkm4v::Config

  def self.run(*args)
    parse *args

    config[:input].each do |file|
      config.input.delete(file) && warn("#{file} does not exist") unless File.exist? file
    end

    config[:input].each do |file|
      trans = Mkm4v::Transcoder.new file
      trans.transcode
    end
  end
end
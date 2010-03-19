require "iso-639"

# Rename undetermined to unknown
ISO_639.find_by_code("und")[3] = "Unknown"

class Mp4v2::Track
  attr_reader :lang, :bitrate, :duration, :timescale, :format
  attr_writer :enabled
  attr_accessor :group, :name

  def lang=(lang)
    @lang = (ISO_639.find_by_code(lang) || IOS_639.find_by_english_name(lang)).english_name
  end
  
  def enabled?
    !!@enabled
  end
end
require File.expand_path("../mediainfo/mediainfo", __FILE__)
require File.expand_path("../mediainfo/track", __FILE__)
require File.expand_path("../mediainfo/general", __FILE__)
require File.expand_path("../mediainfo/video", __FILE__)
require File.expand_path("../mediainfo/audio", __FILE__)
require File.expand_path("../mediainfo/menu", __FILE__)
require File.expand_path("../mediainfo/text", __FILE__)
require File.expand_path("../mediainfo/image", __FILE__)

class MediaInfo
  def self.forward(accessor, *methods)
    def_each *methods do |method|
      case accessor
      when Symbol, String
        instance_eval "#{accessor}.first.#{method}"
      when Proc
        instance_exec(&accessor).send method
      end
    end
  end

  forward :general, :file, :duration, :size, :container, :mime_type,
                    :size, :duration, :bitrate, :interleaved?
  forward :video, :dar, :par, :frames, :ntsc?, :pal?, :video_codec => :codec
  forward :audio, :samplerate, :channels, :audio_codec => :codec
  forward -> { video.first || image.first }, :width, :height

  TrackTypes.each { |type| class_eval "def #{type}?; !#{type}.empty?; end" }
end
class Mkm4v::Transcoder
  include Mkm4v::Config

  class TranscodeError < StandardError; end

  def initialize(filename)
    @info = MediaInfo.new filename
    @output = @info.file

    @muxer = case @info.container
             when "Matroska" then Mkv.new @info
             else Generic.new @info
             end
  end

  def dts_to_ac3!
    @info = MediaInfo.new(@muxer.swap(@info.audio.first) { |raw| raw_dts_to_ac3(raw) }) if @info.audio_codec == "DTS"
  end

  def transcode
    dts_to_ac3!

    cmd = [Handbrake::Exe, "-i", @info.file, "-o", @output.extname("m4v") ]
    cmd << %w|-v0 -e x264  -q 20.0 -E ca_aac,ac3 -B 160,160|
    cmd << %w|-6 dpl2,auto -R 48,Auto -D 0.0,0.0 -f mp4 -4 -X 1280 --loose-anamorphic -m|
    cmd << %w|--subtitle scan --subtitle-forced --subtitle-default --subtitle-burn --native-language eng --native-dub|
    cmd << %w|-x cabac=0:ref=2:me=umh:b-adapt=2:weightb=0:trellis=0:weightp=0:vbv-maxrate=9500:vbv-bufsize=9500|

    cmd.flatten!

    puts cmd.join(" ")
    system *cmd
  end

private
  def raw_dts_to_ac3(rawdts)
    rawac3 = Pathname.tmpfile @info.file, "ac3"
    system %{dcadec -o wavall "#{rawdts}" | aften -b 640 - "#{rawac3}"}
    rawac3
  end
end

require File.expand_path("../transcoder/muxer", __FILE__)
require File.expand_path("../transcoder/generic", __FILE__)
require File.expand_path("../transcoder/mkv", __FILE__)

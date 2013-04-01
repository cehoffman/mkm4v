require "nokogiri"
require "open-uri"

module Mp4::Source
  class Webpage
    attr_reader :page, :url

    def initialize(source)
      @page = Nokogiri::HTML(open(source))
      @url = source
    end
  end
end

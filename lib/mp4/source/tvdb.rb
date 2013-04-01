require "nokogiri"
require "open-uri"
require "tmpdir"
require "cgi"

module Mp4
end

require File.expand_path("../template", __FILE__)

module Mp4::Source
    class XMLPage
      attr_reader :url, :page

      def initialize(url)
        @page = Nokogiri::XML(open(url))
        @url = url
      end
    end

    class TVDB
      def self.mirrors
        return @@mirrors if class_variable_defined?(:@@mirrors)

        mirrors = XMLPage.new("http://www.thetvdb.com/api/#{API_KEY}/mirrors.xml")
        mirrors = mirrors.page.xpath("//Mirrors/Mirror")

        @@mirrors = {}
        @@mirrors[:xml] = mirrors.select { |mirror| mirror.xpath("typemask").text.to_i & 1 == 1 }
        @@mirrors[:banner] = mirrors.select { |mirror| mirror.xpath("typemask").text.to_i & 2 == 2 }
        @@mirrors[:zip] = mirrors.select { |mirror| mirror.xpath("typemask").text.to_i & 4 == 4}

        [:xml, :banner, :zip].each do |set|
          @@mirrors[set].map! { |item| item.xpath("mirrorpath").text }
          arr = @@mirrors[set]

          # Make it easy to pick a random mirror for each kind
          def arr.random
            self[rand(count)]
          end
        end

        @@mirrors
      end

      def self.search(name)
        results = XMLPage.new("http://www.thetvdb.com/api/GetSeries.php?seriesname=#{CGI.escape(name.downcase)}")
        series_id = results.page.xpath("//Series[1]//seriesid").text
        return if series_id.empty? || !(tmpdir = _download_and_unzip("#{zip}/api/#{API_KEY}/series/#{series_id}/all/en.zip"))

        info = XMLPage.new("file://" + File.join(tmpdir, "en.xml"))
        banners = XMLPage.new("file://" + File.join(tmpdir, "banners.xml"))

        new(info, banners) rescue nil
      end

      def self._download_and_unzip(url)
        #url = NSURL.URLWithString url
        data = open(url, "rb") { |f| f.read }

        return unless data

        tmpdir = Dir.mktmpdir rescue nil # Raises SystemCallError if can't create
        return unless tmpdir && File.open(File.join(tmpdir, "en.zip"), "wb") { |f| f << data }

        Dir.chdir(tmpdir) { %x[unzip en.zip] }

        tmpdir if $? == 0
      end
      class << self
        private :_download_and_unzip
      end

      # Order is one of :dvd or anything else to be by aired date
      def self.order
        @@order
      end

      def self.order=(ord)
        @@order = ord
      end

      self.order = :dvd

      attr_reader :order

      attr_reader :seasons
      alias_method :season, :seasons

      def initialize(info, banners)
        @info = info
        @banners = banners
        @order = self.class.order

        @seasons = info.page.xpath("//Episode/SeasonNumber").map { |n| n.text.to_i }.uniq.sort
        @seasons = @seasons.inject({}) do |hsh, season|
          episodes = info.page.xpath("//Episode/SeasonNumber[text() = '#{season}']/..")
          images = banners.page.xpath("//BannerType2[text() = 'season']/..")
          images = images.xpath("./Language[text() = 'en']/..")
          images = images.xpath("./Season[text() = '#{season}']/../BannerPath").map { |path| "#{self.class.banner}/banners/#{path.text}" unless path.text.empty? }.uniq
          hsh[season]= Season.new episodes, @order, images
          hsh
        end
      end

      def order=(ord)
        @seasons.each_pair { |key, season| season.order = ord }
      end

      class Season
        attr_reader :episodes, :images
        alias_method :episode, :episodes

        def initialize(episodes, ord, images)
          @episodes = Episodes.new(episodes, ord)
          self.order = ord
          @images = images
        end

        def order=(ord)
          @episodes.order = ord
        end
      end

      class Episodes
        def initialize(episodes, ord)
          @episodes = episodes.map { |episode| Episode.new episode }
          self.order = ord
        end

        def [](idx)
          @episodes[idx-1]
        end

        def order=(ord)
          @episodes.sort! { |a, b| ord == :dvd && a.dvd_number <=> b.dvd_number || a.number <=> b.number }
        end

        def count
          @episodes.count
        end
      end

      class Episode
        include Mp4::Source::Template

        def initialize(data)
          @data = data
        end

        description do
          @data.xpath("./Overview").text
        end

        cast do
          @data.xpath("./GuestStars").text.split("|").uniq - [""] rescue []
        end

        writers do
          @data.xpath("./Writer").text.split("|").uniq - [""] rescue []
        end

        directors do
          @data.xpath("./Director").text.split("|").uniq - [""] rescue []
        end

        season do
          @data.xpath("./SeasonNumber").text.to_i
        end

        number do
          @data.xpath("./EpisodeNumber").text.to_i
        end

        name do
          @data.xpath("./EpisodeName").text
        end

        released do
          @data.xpath("./FirstAired").text
        end

        id do
          @data.xpath("./ProductionCode").text
        end

        def dvd_season
          @disc ||= @data.xpath("./DVD_season").text.to_i
        end

        def dvd_number
          @dvd ||= @data.xpath("./DVD_episodenumber").text.to_i
        end
      end

      private
        API_KEY = "50BC287089F0922A"

        def self.xml
          mirrors[:xml].random
        end

        def self.banner
          mirrors[:banner].random
        end

        def self.zip
          mirrors[:zip].random
        end
    end
end
module Mp4; end

require File.expand_path("../webpage", __FILE__)
require File.expand_path("../template", __FILE__)
require "cgi"

module Mp4::Source
  class TV < Webpage
    def self.search(name)
      Webpage.new("http://www.tv.com/search.php?type=Search&stype=ajax_search&qs=#{CGI.escape(name.downcase)}&search_type=program&pg_results=0&sort=")
    end

    def self.show(name)
      results = search(name)
      TV.new(results.page.xpath("//li//a").first[:href].sub(/\?.+?$/, '')) rescue nil
    end

    attr_reader :seasons
    alias_method :season, :seasons

    def initialize(url)
      super(url)

      @seasons = Seasons.new(@page.xpath("//a[text() = 'Episode Guide']").pop[:href])
    end

    class Seasons < Webpage
      attr_reader :count

      def initialize(url)
        super(url)

        @urls = @page.xpath("//*[@id = 'episode_list_header']//*[text() = 'Season:']/..//a").select { |a| a.text.to_i > 0 }
        @urls = @urls.inject({}) { |arr, url| arr[url.text.to_i] = url[:href]; arr }
        @count = @urls.count
        @seasons = {}
      end

      def [](number)
        @seasons[number] ||= Season.new(@urls[number])
      end
    end

    class Season < Webpage
      attr_reader :episodes
      alias_method :episode, :episodes

      def initialize(url)
        super(url)

        @episodes = Episodes.new(@page.css(".meta").xpath("..//a[text() = 'Episode Overview']").map { |link| link[:href] }.reverse)
      end
    end

    class Episodes
      attr_reader :count

      def initialize(urls)
        @urls = urls
        @count = @urls.count
        @episodes = {}
      end

      def [](number)
        @episodes[number] ||= Episode.new(@urls[number-1])
      end
    end

    class Episode < Webpage
      include Mp4::Source::Template

      name do
        page.css("#episode_header h1").text.split(":", 2).pop.strip
      end

      released do
        page.css("#show_buzz_info p").first.text.strip
      end

      id do
        page.css("#show_buzz_info p").last.text.strip
      end

      cast do
        cast_page.page.css(".full_name").map { |name| name.text.strip }.uniq
      end

      writers do
        crew_page.page.xpath("//*[@id = 'cast_crew_list']//h3[contains(text(), 'Writer')]/../..").css(".full_name").map { |name| name.text.strip }.uniq
      end

      directors do
        crew_page.page.xpath("//*[@id = 'cast_crew_list']//h3[contains(text(), 'Director')]/../..").css(".full_name").map { |name| name.text.strip }.uniq
      end

      producers do
        crew_page.page.css(".role").select { |node| node.text =~ /Producer|Production/i }.map { |node| node.parent.parent.css(".full_name").first.text.strip }.uniq
      end

      description do
        page.css("#episode_recap p").text.strip.squeeze(" ")
      end

      long_description do
        description
      end

      network do
        network = page.css(".tagline").pop.text.strip
        network[/\son\s/] && network[/\son\s+(.*)$/, 1] || network[/(.*)\s+\(/, 1]
      end

      show do
        page.css("#episode_header h1").text.split(":").first.strip
      end

      season do
        page.css("#episode_header span").text[/Season (\d+)/, 1].to_i
      end

      number do
        page.css("#episode_header span").text[/Episode (\d+)/, 1].to_i
      end

      private
        def cast_page
          @cast_page ||= Webpage.new(page.xpath("//a[text() = 'Cast']").first[:href])
        end

        def crew_page
          @crew_page ||= Webpage.new(page.xpath("//a[contains(text(), 'Writers')]").first[:href])
        end
    end
  end
end
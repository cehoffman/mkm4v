require "spec_helper"
require "fakeweb"
#FakeWeb.allow_net_connect = false
require "mp4/source/tvdb"

# Overwrite the _download_and_unzip function so no network hit
module MP4Tag
  module Source
    class TVDB
      def self._download_and_unzip(url)
        series_id = url[%r{series/(\d+)/all}, 1]
        "./spec/fixtures/tvdb/#{series_id}"
      end
    end
  end
end unless ENV['LIVE']

describe "TVDB" do
  it "should get a list of mirrors" do
    #Mp4::Source::TVDB.mirrors.keys.should include(:xml, :zip, :banner)
    Mp4::Source::TVDB.mirrors[:xml].should == ["http://thetvdb.com"]
    Mp4::Source::TVDB.mirrors[:zip].should == ["http://thetvdb.com"]
    Mp4::Source::TVDB.mirrors[:banner].should == ["http://thetvdb.com"]
  end

  # Unfortunately I'd need a mocking framework to confirm this
  it "should pick a random mirror" do
    Mp4::Source::TVDB.mirrors[:zip].should_receive(:random).and_return("http://thetvdb.com")
    Mp4::Source::TVDB.search("farscape")
  end

  # it "should get the zip file for the series" do
  #   MP4Tag::Source::TVDB.expects(:_get_zip_and_unzip).and_return { raise Success }
  #   MP4Tag::Source::TVDB.search("farscape").shoud.raise Success
  # end

  it "should know how many seasons a series has" do
    tv = MP4Tag::Source::TVDB.search("farscape")
    tv.seasons.count.should == 6
  end

  it "should know how many episodes are in a season" do
    tv = MP4Tag::Source::TVDB.search("farscape")
    tv.season[1].episodes.count.should == 22
  end

  describe "TVDB::Season" do

    it "should have a list of images for a season" do
      show = MP4Tag::Source::TVDB.search("farscape")
      show.season[1].images.should.have values("http://thetvdb.com/banners/seasons/1029-1.jpg",
                                               "http://thetvdb.com/banners/seasons/1029-1-2.jpg",
                                               "http://thetvdb.com/banners/seasons/70522-1-4.jpg",
                                               "http://thetvdb.com/banners/seasons/70522-1-3.jpg")

      show.season[1].images.should.not.have values("http://thetvdb.com/banners/seasons/70522-1.jpg",
                                                   "http://thetvdb.com/banners/seasons/70522-1-2.jpg")
    end
  end

  describe "TVDB::Episode" do

    before  do
      @show = MP4Tag::Source::TVDB.search("farscape")
      @episode = @show.season[1].episode[5]
    end

    it "should change the order of episodes according to :dvd or not" do
      @show.order = :dvd
      @show.season[1].episode[2].number.should == 7
      @show.season[1].episode[2].dvd_number.should == 2


      @show.order = :default
      @show.season[1].episode[2].number.should == 2
      @show.season[1].episode[2].dvd_number.should == 3
    end

    it "should know the name" do
      @episode.name.should == "Back and Back and Back to the Future"
    end

    it "should know the description" do
      @episode.description.should == "The crew come across a ship that is molecularly de-stabilizing. D'Argo makes everyone bring it aboard when he discovers that there are Ilanics on board. Crichton goes on to the escape pod he gets a shock and starts experiencing strange visions of the future, firstly of himself and Matala, then of Moya's destruction"
    end

    it "should know the aired date" do
      @episode.release_date.should == "1999-04-02"
    end

    it "should know the production code" do
      @episode.id.should == "#10105"
    end

    it "should know the episode number" do
      @episode.number.should == 3
    end

    it "should know the season number" do
      @episode.season.should == 1
    end

    it "should know the cast" do
      @episode.cast.should.have only_values("Lisa Hensley", "John Clayton")
    end

    it "should know the directors" do
      @episode.directors.should.have only_values("Rowan Woods")
    end

    it "should know the writers" do
      @episode.writers.should.have only_values("Babs Greyhosky")
    end
  end
end
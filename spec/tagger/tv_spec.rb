require "spec_helper"
require "mp4/source/tv"

describe "TV" do
  before(:all) do
    @tv = Mp4::Source::TV.show("House")
  end

  it "should know how many seasons there are" do
    @tv.seasons.count.should == 6
  end

  it "should know how many episodes are in a season" do
    @tv.season[4].episodes.count.should == 16
  end

  describe "Episode" do
    before(:all) do
      @episode = @tv.season[4].episode[1]
    end

    it "should know the name" do
      @episode.name.should == "Alone"
    end

    it "should know the network" do
      @episode.network.should == "FOX"
    end

    it "should know the show" do
      @episode.show.should == "House"
    end

    it "should know the season number" do
      @episode.season.should == 4
    end

    it "should know the episode number" do
      @episode.number.should == 1
    end

    it "should know the episode id" do
      @episode.id.should == "HOU-401"
    end

    it "should know the description" do
      @episode.description.should == "With his diagnostic team gone, House tries to diagnose a young woman who survived an office building collapse. With the condition getting worse, Cuddy puts pressure on House to hire a new team, but instead attempts a differential diagnosis with help from the janitor."
    end

    it "should know the aired date" do
      @episode.released.should == "Tuesday September 25, 2007"
    end

    it "should know the cast" do
      @episode.cast.should include("Robert Sean Leonard", "Hugh Laurie", "Lisa Edelstein",
              "Bobbin Bergstrom", "Shannon McClung", "Xhercis", "Maurice Godin",
              "Leo Vargas", "Ken Takemoto", "Kathryn Adams (II)", "Pat Millicano",
              "Bevin Prince", "Conor Dubin", "Kay Lenz", "Liliya Toneva")
    end

    it "should know the writers" do
      @episode.writers.should include("Peter Blake (IV)", "David Shore")
    end

    it "should know the directors" do
      @episode.directors.should include("Deran Sarafian")
    end

    it "should know the producers" do
      @episode.producers.should include("Derek R. Hill", "Steven Heth", "David Hoselton",
              "David Foster (II)", "Katie Jacobs", "Paul Attanasio", "David Shore",
              "Bryan Singer", "Garrett Lerner", "Russel Friend", "Thomas L. Moran",
              "Deran Sarafian", "Eli Attie", "Doris Egan", "Gerrit Van Der Meer",
              "Sean Whitesell", "Liz Friedman", "Marcy G. Kaplan", "Peter Blake (IV)",
              "Leonard Dick", "James S. Conway")
    end
  end

  describe "TV::Episode corner cases" do
    it "should get the network when the series has ended" do
      tv = Mp4::Source::TV.show("clone high, usa")
      tv.season[1].episode[10].network.should == "TeleToon"
    end

    it "should only strip the show name from episode names" do
      tv = Mp4::Source::TV.show("clone high, usa")
      tv.season[1].episode[10].name.should == "Litter Kills: Litterally"
    end
  end
end
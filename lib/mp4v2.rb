require "ostruct"
require "plist"
require File.expand_path("../mp4v2/mp4v2", __FILE__)
require File.expand_path("../mp4v2/artwork", __FILE__)

class Mp4v2

private
  @@rating_map = [
                   ["mpaa|NR|000|",           ["Not Rated", :us]],
                   ["mpaa|G|100|",            ["G", :us]],
                   ["mpaa|PG|200|",           ["PG", :us]],
                   ["mpaa|PG-13|300|",        ["PG-13", :us]],
                   ["mpaa|R|400|",            ["R", :us]],
                   ["mpaa|NC-17|500|",        ["NC-17", :us]],
                   ["mpaa|Unrated|???|",      ["Unrated", :us]],

                   ["us-tv|TV-Y|100|",        ["TV-Y", :us]],
                   ["us-tv|TV-Y7|200|",       ["TV-Y7", :us]],
                   ["us-tv|TV-G|300|",        ["TV-G", :us]],
                   ["us-tv|TV-PG|400|",       ["TV-PG", :us]],
                   ["us-tv|TV-14|500|",       ["TV-14", :us]],
                   ["us-tv|TV-MA|600|",       ["TV-MA", :us]],
                   ["us-tv|Unrated|???|",     ["Unrated", :us]],

                   ["uk-movie|NR|000|",       ["Not Rated", :uk]],
                   ["uk-movie|U|100|",        ["U", :uk]],
                   ["uk-movie|Uc|150|",       ["Uc", :uk]],
                   ["uk-movie|PG|200|",       ["PG", :uk]],
                   ["uk-movie|12|300|",       ["12", :uk]],
                   ["uk-movie|12A|325|",      ["12A", :uk]],
                   ["uk-movie|15|350|",       ["15", :uk]],
                   ["uk-movie|18|400|",       ["18", :uk]],
                   ["uk-movie|R18|600|",      ["R18", :uk]],
                   ["uk-movie|E|0|",          ["Exempt", :uk]],
                   ["uk-movie|Unrated|???|",  ["Unrated", :uk]],

                   ["uk-tv|Caution|500|",     ["Caution", :uk]],

                   ["de-movie|FSK 0|100|",    ["FSK 0", :de]],
                   ["de-movie|FSK 6|200|",    ["FSK 6", :de]],
                   ["de-movie|FSK 12|300|",   ["FSK 12", :de]],
                   ["de-movie|FSK 16|400|",   ["FSK 16", :de]],
                   ["de-movie|FSK 18|500|",   ["FSK 18", :de]]
                 ]

  def rating_from_itmf(itmf)
    puts "Getting rating for '#{itmf}'"

    rating = @@rating_map.select { |map| map.first == itmf }.pop

    rating && rating.last || nil
  end
  
  def itmf_from_rating
    itmf = @@rating_map.select { |map| map.last == self.rating }
    itmf = self.kind == :tv && itmf.last || itmf.first
    itmf && itmf.first || nil
  end
end
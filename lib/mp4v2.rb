require "ostruct"
require "plist"
require File.expand_path("../mp4v2/mp4v2", __FILE__)
require File.expand_path("../mp4v2/artwork", __FILE__)

class Mp4v2

private
  @@rating_map = [
                   ["mpaa|NR|000|",           "Not Rated"],
                   ["mpaa|G|100|",            "G"],
                   ["mpaa|PG|200|",           "PG"],
                   ["mpaa|PG-13|300|",        "PG-13"],
                   ["mpaa|R|400|",            "R"],
                   ["mpaa|NC-17|500|",        "NC-17"],
                   ["mpaa|Unrated|???|",      "Unrated"],
                   [nil, nil],
                   ["us-tv|TV-Y|100|",        "TV-Y"],
                   ["us-tv|TV-Y7|200|",       "TV-Y7"],
                   ["us-tv|TV-G|300|",        "TV-G"],
                   ["us-tv|TV-PG|400|",       "TV-PG"],
                   ["us-tv|TV-14|500|",       "TV-14"],
                   ["us-tv|TV-MA|600|",       "TV-MA"],
                   ["us-tv|Unrated|???|",     "Unrated"],
                   [nil, nil],
                   ["uk-movie|NR|000|",       "Not Rated"],
                   ["uk-movie|U|100|",        "U"],
                   ["uk-movie|Uc|150|",       "Uc"],
                   ["uk-movie|PG|200|",       "PG"],
                   ["uk-movie|12|300|",       "12"],
                   ["uk-movie|12A|325|",      "12A"],
                   ["uk-movie|15|350|",       "15"],
                   ["uk-movie|18|400|",       "18"],
                   ["uk-movie|R18|600|",      "R18"],
                   ["uk-movie|E|0|",          "Exempt"],
                   ["uk-movie|Unrated|???|",  "Unrated"],
                   [nil, nil],
                   ["uk-tv|Caution|500|",     "Caution"],
                   [nil, nil],
                   ["de-movie|FSK 0|100|",    "FSK 0"],
                   ["de-movie|FSK 6|200|",    "FSK 6"],
                   ["de-movie|FSK 12|300|",   "FSK 12"],
                   ["de-movie|FSK 16|400|",   "FSK 16"],
                   ["de-movie|FSK 18|500|",   "FSK 18"],
                   [nil, nil],
                   ["",                       "Unknown"]
                 ]

  def rating_from_itmf(itmf)
    puts "Getting rating for '#{itmf}'"

    rating = @@rating_map.select { |map| map.first == itmf }.pop

    rating && rating.last || nil
  end
end
require "pathname"

lib = Pathname.new(__FILE__).parent()

require lib + "hacks/class"
require lib + "hacks/string"
require lib + "hacks/kernel"
require lib + "hacks/pathname"
require lib + "mediainfo"
require lib + "mkm4v/version"
require lib + "mkm4v/config"
require lib + "mkm4v/cli"

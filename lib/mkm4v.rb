require "pathname"

lib = Pathname.new(__FILE__).parent()

require lib + "hacks/string"
require lib + "hacks/kernel"
require lib + "hacks/pathname"
require lib + "mkm4v/version"
require lib + "mkm4v/opts"
require lib + "mkm4v/cli"
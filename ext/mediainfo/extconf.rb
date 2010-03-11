require "mkmf"
require "pathname"

root = Pathname.new(__FILE__).dirname.realpath

puts "#{root + "Project/GNU/Library/configure"} --enable-shared --disable-static --libdir=/usr/lib"
system "#{root + "Project/GNU/Library/configure"} --enable-shared --disable-static --libdir=/usr/lib"
system "cd #{root + "Project/GNU/Library"} && make"

create_makefile("mediainfo/mediainfo")
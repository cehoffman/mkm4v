require "mkmf"
require "pathname"

root = Pathname.new(__FILE__).dirname.realpath

Dir.chdir root + "ZenLib/Project/GNU/Library" do
  system "./configure --libdir=#{root}"
  system "make install"
end

Dir.chdir root + "MediaInfoLib/Project/GNU/Library" do
  system "./configure --libdir=#{root}" # --enable-shared --disable-static
  system "make install"
end

# Wow mkmf is such a pain to get this working
RbConfig::MAKEFILE_CONFIG['CC'] = ENV['CC'] = "g++"
with_cflags "-I#{root + "ZenLib/Source"} -I#{root + "MediaInfoLib/Source"}" do
  with_ldflags "-L#{root} -lmediainfo -lzen" do
    create_makefile("mediainfo/mediainfo")
  end
end
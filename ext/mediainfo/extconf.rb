require "mkmf"
require "pathname"

root = Pathname.new(__FILE__).dirname.realpath

processors = case RUBY_PLATFORM
             when /darwin/ then `hwprefs cpu_count`.strip
             when /linux/ then File.read("/proc/cpuinfo").strip
             else 2
             end

Dir.chdir root + "ZenLib/Project/GNU/Library" do
  system "./configure --libdir=#{root}"
  system "make install -j#{processors}"
end

Dir.chdir root + "MediaInfoLib/Project/GNU/Library" do
  system "./configure --libdir=#{root}"
  system "make install -j#{processors}"
end

# Wow mkmf is such a pain to get this working
with_cflags "-I#{root + "ZenLib/Source"} -I#{root + "MediaInfoLib/Source"}" do
  with_ldflags "-L#{root} -lmediainfo -lzen" do
    create_makefile("mediainfo/mediainfo")
  end
end
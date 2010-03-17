require "mkmf"
require "pathname"

root = Pathname.new(__FILE__).dirname.realpath

processors = case RUBY_PLATFORM
             when /darwin/ then `hwprefs cpu_count`.strip
             when /linux/ then File.read("/proc/cpuinfo").strip
             else 2
             end

Dir.chdir root + "mp4v2" do
  system "autoreconf -fiv"
  system "./configure --libdir=#{root} --disable-util --disable-shared --disable-debug"
  system "make -j#{processors}"
end

# Wow mkmf is such a pain to get this working
with_cflags "-I#{root + "mp4v2/include"} -Wall" do
  with_ldflags "-L#{root + "mp4v2/.libs"} -lmp4v2" do
    create_makefile("mp4v2/mp4v2")
  end
end
#!/usr/bin/env rake
require 'bundler/gem_tasks'

gemspec = Bundler.load_gemspec(Dir['{,*}.gemspec'].first)
# gemspec = Bundler::GemHelper.gemspec

require 'rubygems/package_task'
Gem::PackageTask.new(gemspec) do |pkg|

end

require "rake/extensiontask"
Rake::ExtensionTask.new('mediainfo', gemspec) do |ext|
  ext.lib_dir = File.join('lib', 'mediainfo')
  ext.source_pattern = "*.{c,cpp}"
end

Rake::ExtensionTask.new('mp4v2', gemspec) do |ext|
  ext.lib_dir = File.join('lib', 'mp4v2')
  ext.source_pattern = "*.{c,cpp}"
end

Rake::Task[:spec].prerequisites << :compile

# Rake::TaskManager.class_eval do
#   def remove_task(*task_name)
#     [*task_name].each { |task| @tasks.delete(task.to_s) }
#   end

#   def rename_task(old_name, new_name)
#     old = @tasks.delete old_name.to_s
#     old.instance_variable_set :@name, new_name.to_s
#     @tasks[new_name.to_s] = old
#   end
# end

# Rake.application.remove_task :post_blog, :post_news, :publish_docs, :debug_email, :announce, :rcov
# Rake.application.remove_task "deps:email", "deps:fetch", :config_hoe, :newb, :release_to_rubyforge
# Rake.application.rename_task :install_gem, :install
# Rake.application.rename_task :release_to_gemcutter, :release

require 'rspec/core/rake_task'
puts RSpec::Core::RakeTask.new(:spec).send(:spec_command)

desc "Build the man documentation"
task "man:build" do
  sh "bundle exec ronn -br5 --organization=ByHoffman --manual='mkm4v Manual' man/*.ronn"
end

desc "Show the man page in man"
task :man => "man:build" do
  sh "man man/mkm4v.1"
end

desc "Open and irb session with the project environment"
task :irb => :compile do
  sh "bundle exec irb -r./lib/mkm4v"
end

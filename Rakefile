begin
  # Try to require the preresolved locked set of gems.
  require File.expand_path('../.bundle/environment', __FILE__)
rescue LoadError
  # Fall back on doing an unlocked resolve at runtime.
  require "rubygems"
  require "bundler"
  Bundler.setup
end

$LOAD_PATH.unshift File.expand_path("../lib", __FILE__)
require "hoe"
require "mkm4v/version"

Hoe.plugin :gemcutter
Hoe.plugin :clean
Hoe.plugin :git
Hoe.plugin :bundler

gem = Hoe.spec 'mkm4v' do
  developer('Chris Hoffman', 'cehoffman@gmail.com')

  self.version = Mkm4v::Version
  self.readme_file = 'README.rdoc'
  self.history_file = 'Changelog.rdoc'
  self.test_globs = 'spec/**/*_spec.rb'
  self.spec_extras = { extensions: ["ext/mediainfo/extconf.rb", "ext/mp4v2/extconf.rb"] }
end

require "rake/extensiontask"
Rake::ExtensionTask.new('mediainfo', gem.spec) do |ext|
  ext.lib_dir = File.join('lib', 'mediainfo')
  ext.source_pattern = "*.{c,cpp}"
end

Rake::ExtensionTask.new('mp4v2', gem.spec) do |ext|
  ext.lib_dir = File.join('lib', 'mp4v2')
  ext.source_pattern = "*.{c,cpp}"
end

Rake::Task[:spec].prerequisites << :compile

Rake::TaskManager.class_eval do
  def remove_task(*task_name)
    [*task_name].each { |task| @tasks.delete(task.to_s) }
  end

  def rename_task(old_name, new_name)
    old = @tasks.delete old_name.to_s
    old.instance_variable_set :@name, new_name.to_s
    @tasks[new_name.to_s] = old
  end
end

Rake.application.remove_task :post_blog, :post_news, :publish_docs, :debug_email, :announce, :rcov
Rake.application.remove_task "deps:email", "deps:fetch", :config_hoe, :newb, :release_to_rubyforge
Rake.application.rename_task :install_gem, :install
Rake.application.rename_task :release_to_gemcutter, :release

require 'spec/rake/spectask'
namespace :spec do
  desc "Run specs"
  Spec::Rake::SpecTask.new do |t|
    t.spec_files = FileList['spec/**/*_spec.rb']
    t.spec_opts = "--options spec/spec.opts"

    # t.rcov = true
    # t.rcov_opts << '--sort coverage --text-summary --sort-reverse'
    # t.rcov_opts << "--comments --exclude pkg,#{ENV['GEM_HOME']}"
  end
end

desc "Build the man documentation"
task "man:build" do
  sh "bundle exec vendor/bin/ronn -br5 --organization=ByHoffman --manual='mkm4v Manual' man/*.ronn"
end

desc "Show the man page in man"
task :man => "man:build" do
  sh "man man/mkm4v.1"
end

desc "Open and irb session with the project environment"
task :irb => :compile do
  sh "bundle exec irb -r./lib/mkm4v"
end

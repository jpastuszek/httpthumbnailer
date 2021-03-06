# encoding: utf-8

require 'rubygems'
require 'bundler'
begin
  Bundler.setup(:default, :development)
rescue Bundler::BundlerError => e
  $stderr.puts e.message
  $stderr.puts "Run `bundle install` to install missing gems"
  exit e.status_code
end
require 'rake'

require 'jeweler'
Jeweler::Tasks.new do |gem|
  # gem is a Gem::Specification... see http://docs.rubygems.org/read/chapter/20 for more options
  gem.name = "httpthumbnailer"
  gem.homepage = "http://github.com/jpastuszek/httpthumbnailer"
  gem.license = "MIT"
  gem.summary = %Q{HTTP API server for image thumbnailing, editing and format conversion}
  gem.description = %Q{Statless HTTP server that provides API for thumbnailing images with different aspect ratio keeping methods, applying image edits (like rotate, crop, blur, pixelate, etc.), identification of image format and size and more. It is using ImageMagick or GraphicsMagick via RMagick gem as the image processing library.}
  gem.email = "jpastuszek@gmail.com"
  gem.authors = ["Jakub Pastuszek"]
  gem.files.exclude "features/**/*"
  gem.files.exclude "gatling/**/*"
  gem.files.exclude "spec/**/*"
  gem.files.exclude "test_plugins/**/*"
  gem.files.exclude "*.gemspec"
  gem.files.exclude ".rspec"
  # dependencies defined in Gemfile
end
Jeweler::RubygemsDotOrgTasks.new

require 'rspec/core'
require 'rspec/core/rake_task'
RSpec::Core::RakeTask.new(:spec) do |spec|
  spec.pattern = FileList['spec/**/*_spec.rb']
end

RSpec::Core::RakeTask.new(:rcov) do |spec|
  spec.pattern = 'spec/**/*_spec.rb'
  spec.rcov = true
end

require 'cucumber/rake/task'
Cucumber::Rake::Task.new(:features)

task :default => :spec

#require 'rake/rdoctask'
#Rake::RDocTask.new do |rdoc|
require 'rdoc/task'
RDoc::Task.new do |rdoc|
  version = File.exist?('VERSION') ? File.read('VERSION') : ""

  rdoc.rdoc_dir = 'rdoc'
  rdoc.title = "httpthumbnailer #{version}"
  rdoc.rdoc_files.include('README*')
  rdoc.rdoc_files.include('lib/**/*.rb')
end

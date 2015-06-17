# Generated by jeweler
# DO NOT EDIT THIS FILE DIRECTLY
# Instead, edit Jeweler::Tasks in Rakefile, and run 'rake gemspec'
# -*- encoding: utf-8 -*-
# stub: httpthumbnailer 1.3.0 ruby lib

Gem::Specification.new do |s|
  s.name = "httpthumbnailer"
  s.version = "1.3.0"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.require_paths = ["lib"]
  s.authors = ["Jakub Pastuszek"]
  s.date = "2015-06-17"
  s.description = "Statless HTTP server that provides API for thumbnailing images with different aspect ratio keeping methods, applying image edits (like rotate, crop, blur, pixelate, etc.), identification of image format and size and more. It is using ImageMagick or GraphicsMagick via RMagick gem as the image processing library."
  s.email = "jpastuszek@gmail.com"
  s.executables = ["httpthumbnailer"]
  s.extra_rdoc_files = [
    "LICENSE.txt",
    "README.md"
  ]
  s.files = [
    ".document",
    "Gemfile",
    "Gemfile.lock",
    "LICENSE.txt",
    "README.md",
    "Rakefile",
    "VERSION",
    "bin/httpthumbnailer",
    "lib/httpthumbnailer/error_reporter.rb",
    "lib/httpthumbnailer/ownership.rb",
    "lib/httpthumbnailer/plugin.rb",
    "lib/httpthumbnailer/plugin/thumbnailer.rb",
    "lib/httpthumbnailer/plugin/thumbnailer/service.rb",
    "lib/httpthumbnailer/plugin/thumbnailer/service/built_in_plugins.rb",
    "lib/httpthumbnailer/plugin/thumbnailer/service/images.rb",
    "lib/httpthumbnailer/plugin/thumbnailer/service/magick.rb",
    "lib/httpthumbnailer/thumbnail_specs.rb",
    "lib/httpthumbnailer/thumbnailer.rb"
  ]
  s.homepage = "http://github.com/jpastuszek/httpthumbnailer"
  s.licenses = ["MIT"]
  s.rubygems_version = "2.4.7"
  s.summary = "HTTP API server for image thumbnailing, editing and format conversion"

  if s.respond_to? :specification_version then
    s.specification_version = 4

    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0') then
      s.add_runtime_dependency(%q<unicorn-cuba-base>, ["~> 1.6"])
      s.add_runtime_dependency(%q<rmagick>, ["~> 2"])
      s.add_development_dependency(%q<rspec>, ["~> 2.13"])
      s.add_development_dependency(%q<rspec-mocks>, ["~> 2.13"])
      s.add_development_dependency(%q<cucumber>, ["~> 1.3"])
      s.add_development_dependency(%q<capybara>, ["~> 1.1"])
      s.add_development_dependency(%q<jeweler>, [">= 1.8.8", "~> 1.8"])
      s.add_development_dependency(%q<httpclient>, ["~> 2.3"])
      s.add_development_dependency(%q<rdoc>, ["~> 3.9"])
      s.add_development_dependency(%q<multipart-parser>, ["~> 0.1.1"])
      s.add_development_dependency(%q<daemon>, ["~> 1.1"])
    else
      s.add_dependency(%q<unicorn-cuba-base>, ["~> 1.6"])
      s.add_dependency(%q<rmagick>, ["~> 2"])
      s.add_dependency(%q<rspec>, ["~> 2.13"])
      s.add_dependency(%q<rspec-mocks>, ["~> 2.13"])
      s.add_dependency(%q<cucumber>, ["~> 1.3"])
      s.add_dependency(%q<capybara>, ["~> 1.1"])
      s.add_dependency(%q<jeweler>, [">= 1.8.8", "~> 1.8"])
      s.add_dependency(%q<httpclient>, ["~> 2.3"])
      s.add_dependency(%q<rdoc>, ["~> 3.9"])
      s.add_dependency(%q<multipart-parser>, ["~> 0.1.1"])
      s.add_dependency(%q<daemon>, ["~> 1.1"])
    end
  else
    s.add_dependency(%q<unicorn-cuba-base>, ["~> 1.6"])
    s.add_dependency(%q<rmagick>, ["~> 2"])
    s.add_dependency(%q<rspec>, ["~> 2.13"])
    s.add_dependency(%q<rspec-mocks>, ["~> 2.13"])
    s.add_dependency(%q<cucumber>, ["~> 1.3"])
    s.add_dependency(%q<capybara>, ["~> 1.1"])
    s.add_dependency(%q<jeweler>, [">= 1.8.8", "~> 1.8"])
    s.add_dependency(%q<httpclient>, ["~> 2.3"])
    s.add_dependency(%q<rdoc>, ["~> 3.9"])
    s.add_dependency(%q<multipart-parser>, ["~> 0.1.1"])
    s.add_dependency(%q<daemon>, ["~> 1.1"])
  end
end


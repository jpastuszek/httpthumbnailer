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
  s.date = "2015-05-24"
  s.description = "Provides HTTP API for thumbnailing images"
  s.email = "jpastuszek@gmail.com"
  s.executables = ["httpthumbnailer"]
  s.extra_rdoc_files = [
    "LICENSE.txt",
    "README.md"
  ]
  s.files = [
    ".document",
    ".rspec",
    "Gemfile",
    "Gemfile.lock",
    "LICENSE.txt",
    "README.md",
    "Rakefile",
    "VERSION",
    "bin/httpthumbnailer",
    "features/edits.feature",
    "features/httpthumbnailer.feature",
    "features/identify.feature",
    "features/plugins.feature",
    "features/step_definitions/httpthumbnailer_steps.rb",
    "features/support/env.rb",
    "features/support/test-large.jpg",
    "features/support/test-transparent.png",
    "features/support/test.jpg",
    "features/support/test.png",
    "features/support/test.txt",
    "features/thumbnail.feature",
    "features/thumbnails.feature",
    "httpthumbnailer.gemspec",
    "lib/httpthumbnailer/error_reporter.rb",
    "lib/httpthumbnailer/ownership.rb",
    "lib/httpthumbnailer/plugin.rb",
    "lib/httpthumbnailer/plugin/thumbnailer.rb",
    "lib/httpthumbnailer/plugin/thumbnailer/service.rb",
    "lib/httpthumbnailer/plugin/thumbnailer/service/built_in_plugins.rb",
    "lib/httpthumbnailer/plugin/thumbnailer/service/images.rb",
    "lib/httpthumbnailer/plugin/thumbnailer/service/magick.rb",
    "lib/httpthumbnailer/thumbnail_specs.rb",
    "lib/httpthumbnailer/thumbnailer.rb",
    "load_test/extralarge.jpg",
    "load_test/large.jpg",
    "load_test/large.png",
    "load_test/load_test-374846090-1.1.0-rc1-identify-only.csv",
    "load_test/load_test-374846090-1.1.0-rc1.csv",
    "load_test/load_test-cd9679c.csv",
    "load_test/load_test-v0.3.1.csv",
    "load_test/load_test.jmx",
    "load_test/medium.jpg",
    "load_test/small.jpg",
    "load_test/soak_test-ac0c6bcbe5e-broken-libjpeg-tatoos.csv",
    "load_test/soak_test-cd9679c.csv",
    "load_test/soak_test-f98334a-tatoos.csv",
    "load_test/soak_test.jmx",
    "load_test/tiny.jpg",
    "load_test/v0.0.13-loading.csv",
    "load_test/v0.0.13.csv",
    "load_test/v0.0.14-no-optimization.csv",
    "load_test/v0.0.14.csv",
    "spec/ownership_spec.rb",
    "spec/plugin_thumbnailer_spec.rb",
    "spec/spec_helper.rb",
    "spec/support/square_even.png",
    "spec/support/square_odd.png",
    "spec/support/test_image.rb",
    "spec/thumbnail_specs_spec.rb",
    "test_plugins/p1/cut_method.rb",
    "test_plugins/p1/empty.rb",
    "test_plugins/p2/blur_method.rb"
  ]
  s.homepage = "http://github.com/jpastuszek/httpthumbnailer"
  s.licenses = ["MIT"]
  s.rubygems_version = "2.2.2"
  s.summary = "HTTP thumbnailing server"

  if s.respond_to? :specification_version then
    s.specification_version = 4

    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0') then
      s.add_runtime_dependency(%q<unicorn-cuba-base>, ["~> 1.5.0"])
      s.add_runtime_dependency(%q<rmagick>, ["~> 2"])
      s.add_development_dependency(%q<rspec>, ["~> 2.13"])
      s.add_development_dependency(%q<rspec-mocks>, ["~> 2.13"])
      s.add_development_dependency(%q<cucumber>, [">= 0"])
      s.add_development_dependency(%q<capybara>, ["~> 1.1"])
      s.add_development_dependency(%q<jeweler>, [">= 1.8.8", "~> 1.8"])
      s.add_development_dependency(%q<httpclient>, ["~> 2.3"])
      s.add_development_dependency(%q<rdoc>, ["~> 3.9"])
      s.add_development_dependency(%q<multipart-parser>, ["~> 0.1.1"])
      s.add_development_dependency(%q<daemon>, [">= 0"])
    else
      s.add_dependency(%q<unicorn-cuba-base>, ["~> 1.5.0"])
      s.add_dependency(%q<rmagick>, ["~> 2"])
      s.add_dependency(%q<rspec>, ["~> 2.13"])
      s.add_dependency(%q<rspec-mocks>, ["~> 2.13"])
      s.add_dependency(%q<cucumber>, [">= 0"])
      s.add_dependency(%q<capybara>, ["~> 1.1"])
      s.add_dependency(%q<jeweler>, [">= 1.8.8", "~> 1.8"])
      s.add_dependency(%q<httpclient>, ["~> 2.3"])
      s.add_dependency(%q<rdoc>, ["~> 3.9"])
      s.add_dependency(%q<multipart-parser>, ["~> 0.1.1"])
      s.add_dependency(%q<daemon>, [">= 0"])
    end
  else
    s.add_dependency(%q<unicorn-cuba-base>, ["~> 1.5.0"])
    s.add_dependency(%q<rmagick>, ["~> 2"])
    s.add_dependency(%q<rspec>, ["~> 2.13"])
    s.add_dependency(%q<rspec-mocks>, ["~> 2.13"])
    s.add_dependency(%q<cucumber>, [">= 0"])
    s.add_dependency(%q<capybara>, ["~> 1.1"])
    s.add_dependency(%q<jeweler>, [">= 1.8.8", "~> 1.8"])
    s.add_dependency(%q<httpclient>, ["~> 2.3"])
    s.add_dependency(%q<rdoc>, ["~> 3.9"])
    s.add_dependency(%q<multipart-parser>, ["~> 0.1.1"])
    s.add_dependency(%q<daemon>, [">= 0"])
  end
end


# Generated by jeweler
# DO NOT EDIT THIS FILE DIRECTLY
# Instead, edit Jeweler::Tasks in Rakefile, and run 'rake gemspec'
# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = "httpthumbnailer"
  s.version = "0.0.4"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = ["Jakub Pastuszek"]
  s.date = "2011-11-29"
  s.description = "Provides HTTP API for thumbnailing images"
  s.email = "jpastuszek@gmail.com"
  s.executables = ["httpthumbnailer"]
  s.extra_rdoc_files = [
    "LICENSE.txt",
    "README.rdoc"
  ]
  s.files = [
    ".document",
    ".rspec",
    "Gemfile",
    "Gemfile.lock",
    "LICENSE.txt",
    "README.rdoc",
    "Rakefile",
    "VERSION",
    "bin/httpthumbnailer",
    "features/httpthumbnailer.feature",
    "features/step_definitions/httpthumbnailer_steps.rb",
    "features/support/env.rb",
    "features/support/test-transparent.png",
    "features/support/test.jpg",
    "features/support/test.txt",
    "httpthumbnailer.gemspec",
    "lib/httpthumbnailer/multipart_response.rb",
    "lib/httpthumbnailer/thumbnail_specs.rb",
    "lib/httpthumbnailer/thumbnailer.rb",
    "spec/multipart_response_spec.rb",
    "spec/spec_helper.rb",
    "spec/thumbnail_specs_spec.rb",
    "spec/thumbnailer_spec.rb"
  ]
  s.homepage = "http://github.com/jpastuszek/httpthumbnailer"
  s.licenses = ["MIT"]
  s.require_paths = ["lib"]
  s.rubygems_version = "1.8.10"
  s.summary = "HTTP thumbnailing server"

  if s.respond_to? :specification_version then
    s.specification_version = 3

    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0') then
      s.add_runtime_dependency(%q<sinatra>, [">= 1.2.6"])
      s.add_runtime_dependency(%q<mongrel>, [">= 1.1.5"])
      s.add_runtime_dependency(%q<rmagick>, ["~> 2"])
      s.add_runtime_dependency(%q<haml>, ["~> 3"])
      s.add_development_dependency(%q<rspec>, ["~> 2.3.0"])
      s.add_development_dependency(%q<cucumber>, [">= 0"])
      s.add_development_dependency(%q<bundler>, ["~> 1.0.0"])
      s.add_development_dependency(%q<jeweler>, ["~> 1.6.4"])
      s.add_development_dependency(%q<rcov>, [">= 0"])
      s.add_development_dependency(%q<daemon>, ["~> 1"])
      s.add_development_dependency(%q<httpclient>, ["~> 2.2"])
      s.add_development_dependency(%q<rdoc>, ["~> 3.9"])
    else
      s.add_dependency(%q<sinatra>, [">= 1.2.6"])
      s.add_dependency(%q<mongrel>, [">= 1.1.5"])
      s.add_dependency(%q<rmagick>, ["~> 2"])
      s.add_dependency(%q<haml>, ["~> 3"])
      s.add_dependency(%q<rspec>, ["~> 2.3.0"])
      s.add_dependency(%q<cucumber>, [">= 0"])
      s.add_dependency(%q<bundler>, ["~> 1.0.0"])
      s.add_dependency(%q<jeweler>, ["~> 1.6.4"])
      s.add_dependency(%q<rcov>, [">= 0"])
      s.add_dependency(%q<daemon>, ["~> 1"])
      s.add_dependency(%q<httpclient>, ["~> 2.2"])
      s.add_dependency(%q<rdoc>, ["~> 3.9"])
    end
  else
    s.add_dependency(%q<sinatra>, [">= 1.2.6"])
    s.add_dependency(%q<mongrel>, [">= 1.1.5"])
    s.add_dependency(%q<rmagick>, ["~> 2"])
    s.add_dependency(%q<haml>, ["~> 3"])
    s.add_dependency(%q<rspec>, ["~> 2.3.0"])
    s.add_dependency(%q<cucumber>, [">= 0"])
    s.add_dependency(%q<bundler>, ["~> 1.0.0"])
    s.add_dependency(%q<jeweler>, ["~> 1.6.4"])
    s.add_dependency(%q<rcov>, [">= 0"])
    s.add_dependency(%q<daemon>, ["~> 1"])
    s.add_dependency(%q<httpclient>, ["~> 2.2"])
    s.add_dependency(%q<rdoc>, ["~> 3.9"])
  end
end


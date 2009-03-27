#! /usr/bin/env gem build

require 'rubygems'

Gem::Specification::new do |spec|
  $VERBOSE = nil

  shiteless = lambda do |list|
    list.delete_if do |file|
      file =~ %r/\.git/ or
      file =~ %r/\.svn/ or
      file =~ %r/\.tmp/
    end
  end

  spec.name = $lib
  spec.version = $version
  spec.platform = Gem::Platform::RUBY
  spec.summary = $lib

  spec.files = shiteless[Dir::glob("**/**")]
  spec.executables = shiteless[Dir::glob("bin/*")].map{|exe| File::basename(exe)}
  
  spec.require_path = "lib" 

  spec.has_rdoc = true #File::exist? "doc" 
  # spec.test_suite_file = "test/#{ $lib }.rb" if File::file?("test/#{ $lib }.rb")
  spec.add_dependency 'rest-client'
  spec.add_dependency 'nokogiri'
  spec.add_dependency 'threadify'
  spec.add_dependency 'tagz', '>= 5.0.1'

  spec.extensions << "extconf.rb" if File::exists? "extconf.rb"

  spec.rubyforge_project = 'gnip'
  spec.author = "Ara T. Howard"
  spec.email = "ara.t.howard@gmail.com"
  spec.homepage = "http://gnip.com"
end


BEGIN{ 
  Dir.chdir(File.dirname(__FILE__))
  $lib = 'gnip'
  Kernel.load "./lib/#{ $lib }.rb"
  $version = Gnip.version
}

$:.unshift File.expand_path("../lib", __FILE__)
require 'date'
require 'denmark/version'

Gem::Specification.new do |s|
  s.name              = "denmark"
  s.version           = Denmark::VERSION
  s.date              = Date.today.to_s
  s.summary           = "A quick smell test for Puppet modules to help identify concerns."
  s.homepage          = "https://github.com/binford2k/denmark"
  s.license           = 'Apache-2.0'
  s.email             = "ben.ford@puppet.com"
  s.authors           = ["Ben Ford"]
  s.require_path      = "lib"
  s.executables       = %w( denmark )
  s.files             = %w( README.md LICENSE )
  s.files            += Dir.glob("lib/**/*")
  s.files            += Dir.glob("bin/**/*")
  s.add_dependency      "json",             '~> 2.0'
  s.add_dependency      "gli",              '~> 2.0'
  s.add_dependency      "httpclient",       '~> 2.0'
  s.add_dependency      "little-plugger",   '~> 1.0'
  s.add_dependency      "puppet_forge",     '~> 3.0'
  s.add_dependency      "semantic_puppet",  '~> 1.0'
  s.add_dependency      "octokit",          '~> 4.0'
  s.add_dependency      "gitlab",           '~> 4.0'
  s.add_dependency      "paint",            '~> 2.0'
  s.add_dependency      "paint-shortcuts",  '~> 2.0'
  s.add_dependency      'gems',             '~> 1.0'

  s.description       = <<~desc
  Denmark will check a Puppet module for things you should be concerned about, like signs of an
  unmaintained module. It uses the Puppet Forge API and GitHub/GitLab APIs to discover information
  about the module.
  desc

end

# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require "qtquick/version"

Gem::Specification.new do |s|
  s.name        = "qtquick"
  s.version     = QtQuick::VERSION
  s.authors     = ["Lars Kanis"]
  s.email       = ["kanis@comcard.de"]
  s.homepage    = "http://rubygems/gems/qtquick"
  s.summary     = %q{QtQuick for Ruby}
  s.description = %q{This is a lightwight binding to Qt-Quick}

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]

  # specify any dependencies here; for example:
  # s.add_development_dependency "rspec"
  # s.add_runtime_dependency "rest-client"
end

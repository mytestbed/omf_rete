# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require "omf_rete/version"

Gem::Specification.new do |s|
  s.name        = "omf_rete"
#  s.version     = OmfWeb::VERSION
  s.version     = OMF::Rete::VERSION
  s.authors     = ["NICTA"]
  s.email       = ["omf-user@lists.nicta.com.au"]
  s.homepage    = "https://www.mytestbed.net"
  s.summary     = %q{A Rete implementation.}
  s.description = %q{Tuple store with query and filter functionality.}

  s.rubyforge_project = "omf_rete"

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- {bin,sbin}/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]

  # specify any dependencies here; for example:
#  s.add_development_dependency "minitest", "~> 2.11.3"
end

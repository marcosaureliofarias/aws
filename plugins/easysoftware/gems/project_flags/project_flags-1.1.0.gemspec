# -*- encoding: utf-8 -*-
# stub: project_flags 1.1.0 ruby lib

Gem::Specification.new do |s|
  s.name = "project_flags".freeze
  s.version = "1.1.0"

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.metadata = { "allowed_push_host" => "https://gems.easysoftware.com" } if s.respond_to? :metadata=
  s.require_paths = ["lib".freeze]
  s.authors = ["Gitmakers.com".freeze]
  s.date = "2021-02-16"
  s.description = "Description of ProjectFlags.".freeze
  s.email = ["build@gitmakers.com".freeze]
  s.homepage = "https://easysoftware.com".freeze
  s.licenses = ["GNU/GPL 2".freeze]
  s.rubygems_version = "3.0.8".freeze
  s.summary = "Summary of ProjectFlags.".freeze

  s.installed_by_version = "3.0.8" if s.respond_to? :installed_by_version

  if s.respond_to? :specification_version then
    s.specification_version = 4

    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0') then
      s.add_runtime_dependency(%q<rys>.freeze, [">= 0"])
      s.add_development_dependency(%q<pry-rails>.freeze, [">= 0"])
    else
      s.add_dependency(%q<rys>.freeze, [">= 0"])
      s.add_dependency(%q<pry-rails>.freeze, [">= 0"])
    end
  else
    s.add_dependency(%q<rys>.freeze, [">= 0"])
    s.add_dependency(%q<pry-rails>.freeze, [">= 0"])
  end
end

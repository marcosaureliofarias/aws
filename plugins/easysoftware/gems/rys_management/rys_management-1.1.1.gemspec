# -*- encoding: utf-8 -*-
# stub: rys_management 1.1.1 ruby lib

Gem::Specification.new do |s|
  s.name = "rys_management".freeze
  s.version = "1.1.1"

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.metadata = { "allowed_push_host" => "https://gems.easysoftware.com" } if s.respond_to? :metadata=
  s.require_paths = ["lib".freeze]
  s.authors = ["Ond\u0159ej Morav\u010D\u00EDk".freeze]
  s.date = "2021-01-12"
  s.description = "Description of RysManagement.".freeze
  s.email = ["info@easysoftware.com".freeze]
  s.homepage = "https://easysoftware.com".freeze
  s.licenses = ["GPL-2.0-or-later".freeze]
  s.rubygems_version = "3.0.8".freeze
  s.summary = "Summary of RysManagement.".freeze

  s.installed_by_version = "3.0.8" if s.respond_to? :installed_by_version

  if s.respond_to? :specification_version then
    s.specification_version = 4

    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0') then
      s.add_runtime_dependency(%q<rys>.freeze, ["~> 1.4.12"])
    else
      s.add_dependency(%q<rys>.freeze, ["~> 1.4.12"])
    end
  else
    s.add_dependency(%q<rys>.freeze, ["~> 1.4.12"])
  end
end

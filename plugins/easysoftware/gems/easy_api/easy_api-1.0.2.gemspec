# -*- encoding: utf-8 -*-
# stub: easy_api 1.0.2 ruby lib

Gem::Specification.new do |s|
  s.name = "easy_api".freeze
  s.version = "1.0.2"

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.metadata = { "allowed_push_host" => "https://gems.easysoftware.com" } if s.respond_to? :metadata=
  s.require_paths = ["lib".freeze]
  s.authors = ["Easy Software".freeze, "Ond\u0159ej Morav\u010D\u00EDk".freeze, "Luk\u00E1\u0161 Pokorn\u00FD".freeze]
  s.date = "2019-10-18"
  s.description = "Description of EasyApi.".freeze
  s.email = ["info@easysoftware.com".freeze]
  s.homepage = "https://easysoftware.com".freeze
  s.licenses = ["GPL-2.0-or-later".freeze]
  s.rubygems_version = "3.0.8".freeze
  s.summary = "Summary of EasyApi.".freeze

  s.installed_by_version = "3.0.8" if s.respond_to? :installed_by_version

  if s.respond_to? :specification_version then
    s.specification_version = 4

    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0') then
      s.add_runtime_dependency(%q<rys>.freeze, [">= 0"])
    else
      s.add_dependency(%q<rys>.freeze, [">= 0"])
    end
  else
    s.add_dependency(%q<rys>.freeze, [">= 0"])
  end
end

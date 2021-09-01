# -*- encoding: utf-8 -*-
# stub: security_user_lock 1.0.9 ruby lib

Gem::Specification.new do |s|
  s.name = "security_user_lock".freeze
  s.version = "1.0.9"

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.metadata = { "allowed_push_host" => "https://gems.easysoftware.com" } if s.respond_to? :metadata=
  s.require_paths = ["lib".freeze]
  s.authors = ["Constantin Grosu".freeze, "Luk\u00E1\u0161 Pokorn\u00FD".freeze]
  s.date = "2021-02-25"
  s.description = "Description of SecurityUserLock.".freeze
  s.email = ["build@gitmakers.com".freeze]
  s.homepage = "https://easysoftware.com".freeze
  s.licenses = ["GPL-2.0-or-later".freeze]
  s.rubygems_version = "3.0.8".freeze
  s.summary = "Lock user after few failed attempts.".freeze

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

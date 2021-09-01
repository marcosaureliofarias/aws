# -*- encoding: utf-8 -*-
# stub: rys 1.4.17 ruby lib

Gem::Specification.new do |s|
  s.name = "rys".freeze
  s.version = "1.4.17"

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.metadata = { "allowed_push_host" => "https://gems.easysoftware.com" } if s.respond_to? :metadata=
  s.require_paths = ["lib".freeze]
  s.authors = ["Easy Software".freeze]
  s.date = "2020-07-10"
  s.email = ["info@easysoftware.com".freeze]
  s.homepage = "https://www.easysoftware.com".freeze
  s.licenses = ["GPL-2.0-or-later".freeze]
  s.rubygems_version = "3.0.8".freeze
  s.summary = "Feature toggler, patch manager, plugin generator".freeze

  s.installed_by_version = "3.0.8" if s.respond_to? :installed_by_version

  if s.respond_to? :specification_version then
    s.specification_version = 4

    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0') then
      s.add_runtime_dependency(%q<request_store>.freeze, [">= 0"])
      s.add_runtime_dependency(%q<tty-prompt>.freeze, [">= 0"])
      s.add_runtime_dependency(%q<redmine_extensions>.freeze, [">= 0"])
    else
      s.add_dependency(%q<request_store>.freeze, [">= 0"])
      s.add_dependency(%q<tty-prompt>.freeze, [">= 0"])
      s.add_dependency(%q<redmine_extensions>.freeze, [">= 0"])
    end
  else
    s.add_dependency(%q<request_store>.freeze, [">= 0"])
    s.add_dependency(%q<tty-prompt>.freeze, [">= 0"])
    s.add_dependency(%q<redmine_extensions>.freeze, [">= 0"])
  end
end

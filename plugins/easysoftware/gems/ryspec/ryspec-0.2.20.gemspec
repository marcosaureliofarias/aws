# -*- encoding: utf-8 -*-
# stub: ryspec 0.2.20 ruby lib

Gem::Specification.new do |s|
  s.name = "ryspec".freeze
  s.version = "0.2.20"

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.metadata = { "allowed_push_host" => "https://gems.easysoftware.com" } if s.respond_to? :metadata=
  s.require_paths = ["lib".freeze]
  s.authors = ["Ond\u0159ej Morav\u010D\u00EDk".freeze]
  s.date = "2021-01-27"
  s.description = "Description of Ryspec.".freeze
  s.email = ["info@easysoftware.com".freeze]
  s.homepage = "https://easysoftware.com".freeze
  s.licenses = ["GPL-2.0-or-later".freeze]
  s.rubygems_version = "3.0.8".freeze
  s.summary = "Summary of Ryspec.".freeze

  s.installed_by_version = "3.0.8" if s.respond_to? :installed_by_version

  if s.respond_to? :specification_version then
    s.specification_version = 4

    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0') then
      s.add_runtime_dependency(%q<rys>.freeze, [">= 0"])
      s.add_runtime_dependency(%q<rspec-rails>.freeze, ["~> 4.0"])
      s.add_runtime_dependency(%q<capybara>.freeze, [">= 0"])
      s.add_runtime_dependency(%q<database_cleaner>.freeze, ["~> 1.7.0"])
      s.add_runtime_dependency(%q<factory_bot_rails>.freeze, ["~> 5.1"])
      s.add_runtime_dependency(%q<faker>.freeze, ["~> 1.8.7"])
      s.add_runtime_dependency(%q<launchy>.freeze, ["~> 2.4.3"])
      s.add_runtime_dependency(%q<poltergeist>.freeze, [">= 0"])
      s.add_runtime_dependency(%q<webmock>.freeze, ["~> 3.8.1"])
    else
      s.add_dependency(%q<rys>.freeze, [">= 0"])
      s.add_dependency(%q<rspec-rails>.freeze, ["~> 4.0"])
      s.add_dependency(%q<capybara>.freeze, [">= 0"])
      s.add_dependency(%q<database_cleaner>.freeze, ["~> 1.7.0"])
      s.add_dependency(%q<factory_bot_rails>.freeze, ["~> 5.1"])
      s.add_dependency(%q<faker>.freeze, ["~> 1.8.7"])
      s.add_dependency(%q<launchy>.freeze, ["~> 2.4.3"])
      s.add_dependency(%q<poltergeist>.freeze, [">= 0"])
      s.add_dependency(%q<webmock>.freeze, ["~> 3.8.1"])
    end
  else
    s.add_dependency(%q<rys>.freeze, [">= 0"])
    s.add_dependency(%q<rspec-rails>.freeze, ["~> 4.0"])
    s.add_dependency(%q<capybara>.freeze, [">= 0"])
    s.add_dependency(%q<database_cleaner>.freeze, ["~> 1.7.0"])
    s.add_dependency(%q<factory_bot_rails>.freeze, ["~> 5.1"])
    s.add_dependency(%q<faker>.freeze, ["~> 1.8.7"])
    s.add_dependency(%q<launchy>.freeze, ["~> 2.4.3"])
    s.add_dependency(%q<poltergeist>.freeze, [">= 0"])
    s.add_dependency(%q<webmock>.freeze, ["~> 3.8.1"])
  end
end

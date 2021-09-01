# -*- encoding: utf-8 -*-
# stub: dependent_list_custom_field 1.0.16 ruby lib

Gem::Specification.new do |s|
  s.name = "dependent_list_custom_field".freeze
  s.version = "1.0.16"

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.metadata = { "allowed_push_host" => "https://gems.easysoftware.com" } if s.respond_to? :metadata=
  s.require_paths = ["lib".freeze]
  s.authors = ["Gitmakers.com".freeze]
  s.date = "2021-03-16"
  s.description = "Description of DependentListCustomField.".freeze
  s.email = ["build@gitmakers.com".freeze]
  s.homepage = "https://easysoftware.com".freeze
  s.licenses = ["GNU/GPL 2".freeze]
  s.rubygems_version = "3.0.8".freeze
  s.summary = "Summary of DependentListCustomField.".freeze

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

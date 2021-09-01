# -*- encoding: utf-8 -*-
# stub: easy_swagger 3.2.18 ruby lib

Gem::Specification.new do |s|
  s.name = "easy_swagger".freeze
  s.version = "3.2.18"

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.metadata = { "allowed_push_host" => "https://gems.easysoftware.com" } if s.respond_to? :metadata=
  s.require_paths = ["lib".freeze]
  s.authors = ["Gitmakers.com".freeze]
  s.date = "2021-03-30"
  s.description = "Description of Swagger.".freeze
  s.email = ["build@gitmakers.com".freeze]
  s.homepage = "https://easysoftware.com".freeze
  s.licenses = ["GNU/GPL 2".freeze]
  s.rubygems_version = "3.0.8".freeze
  s.summary = "Summary of Swagger.".freeze

  s.installed_by_version = "3.0.8" if s.respond_to? :installed_by_version

  if s.respond_to? :specification_version then
    s.specification_version = 4

    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0') then
      s.add_runtime_dependency(%q<easy_api>.freeze, ["~> 1.0"])
      s.add_runtime_dependency(%q<rys>.freeze, [">= 0"])
      s.add_runtime_dependency(%q<swagger-blocks>.freeze, ["~> 3.0"])
      s.add_development_dependency(%q<pry-rails>.freeze, [">= 0"])
      s.add_development_dependency(%q<ryspec>.freeze, [">= 0"])
    else
      s.add_dependency(%q<easy_api>.freeze, ["~> 1.0"])
      s.add_dependency(%q<rys>.freeze, [">= 0"])
      s.add_dependency(%q<swagger-blocks>.freeze, ["~> 3.0"])
      s.add_dependency(%q<pry-rails>.freeze, [">= 0"])
      s.add_dependency(%q<ryspec>.freeze, [">= 0"])
    end
  else
    s.add_dependency(%q<easy_api>.freeze, ["~> 1.0"])
    s.add_dependency(%q<rys>.freeze, [">= 0"])
    s.add_dependency(%q<swagger-blocks>.freeze, ["~> 3.0"])
    s.add_dependency(%q<pry-rails>.freeze, [">= 0"])
    s.add_dependency(%q<ryspec>.freeze, [">= 0"])
  end
end

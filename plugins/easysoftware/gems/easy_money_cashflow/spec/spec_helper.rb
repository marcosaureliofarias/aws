require 'bundler'

spec = Bundler.load.specs.find { |s| s.name.to_s == 'ryspec' }

if !spec
  abort('Gem ryspec was not found. Please add it and run bundle install again.')
end

require File.join(spec.full_gem_path, 'spec/spec_helper')

if (Redmine::Plugin.installed?(:easy_money) && (easy_money = Redmine::Plugin.find "easy_money"))
  begin
    require File.join(easy_money.directory, "test", "factories", "easy_money.rb")
  rescue StandardError => ex
    puts ex.to_s
    # probably already loaded -> ignore
  end
end

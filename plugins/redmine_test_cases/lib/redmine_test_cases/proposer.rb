easy_extensions = Redmine::Plugin.registered_plugins[:easy_extensions]
unless easy_extensions.nil? || Gem::Version.new(easy_extensions.version) < Gem::Version.new('2016.05.08')
  EasyExtensions::ActionProposer.add({ controller: 'test_cases', action: 'index' })
end
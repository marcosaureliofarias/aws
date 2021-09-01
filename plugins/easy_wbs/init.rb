Redmine::Plugin.register :easy_wbs do
  name 'Easy WBS plugin'
  author 'Easy Software Ltd'
  description 'new WBS tree hierarchy generator'
  version '1.6'
  url 'www.easyredmine.com'
  author_url 'www.easysoftware.cz'

  requires_redmine_plugin :easy_mindmup, version_or_higher: '1.1'

  if Redmine::Plugin.installed?(:easy_extensions)
    depends_on [:easy_mindmup]
  end

end

unless Redmine::Plugin.installed?(:easy_extensions)
  require_relative 'after_init'
end

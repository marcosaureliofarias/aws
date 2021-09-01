class EasyLicenseKeyPlugin < ActiveResource::Base
  self.site         = 'https://build.easysoftware.cz'
  self.element_name = 'plugin'

  def easy_hosting_plugin
    EasyHostingPlugin.find_by(plugin_name: name)
  end

end

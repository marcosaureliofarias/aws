class EasyLicenseKey < ActiveResource::Base
  self.site                 = 'https://build.easysoftware.com'
  self.element_name         = 'license_key'
  self.include_root_in_json = true

  has_many :products, class_name: 'EasyLicenseKeyProduct'
  has_many :plugins, class_name: 'EasyLicenseKeyPlugin'

  def self.get_valid_easy_license_key(key, hostname = nil)
    find(:one, from: :validate, params: { key: key, hostname: hostname || Setting.host_name })
  rescue ActiveResource::ResourceNotFound
  end

  def apply_license_key
    update_easy_settings
    activate_or_deactivate_plugins
  end

  def update_easy_settings
    self.license_key_settings.each do |license_key_setting|
      set_easy_settings(license_key_setting.name, license_key_setting.value)
    end

    set_easy_settings('license_key', self.generated_key)
  end

  def set_easy_settings(key, value)
    setting       = EasySetting.find_or_initialize_by(name: key, project_id: nil)
    setting.value = value
    setting.save
  end

  def activate_or_deactivate_plugins
    case self.valid_type
    when 'all_products'
      self.plugins.each do |plugin|
        pp plugin.name, plugin.easy_hosting_plugin
      end
    when 'add_new_products'
      self.plugins.each do |plugin|
        pp plugin.name, plugin.easy_hosting_plugin
      end
    when 'selected_products_only'
      EasyHostingPlugin.update_all(activated: false)

      self.plugins.each do |plugin|
        next if !plugin.easy_hosting_plugin

        plugin.easy_hosting_plugin.activate
      end
    end
  end

end

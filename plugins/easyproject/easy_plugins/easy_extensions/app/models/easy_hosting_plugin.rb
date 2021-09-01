class EasyHostingPlugin < ActiveRecord::Base

  TRIAL_DAYS = 30

  validates :plugin_name, uniqueness: { message: proc { |ehp| I18n.t(:error_easy_hosting_plugin_exists, plugin: ehp.plugin_name) } }
  validate :validate_dependencies_on_deactivation, if: proc { |ehp| self.activated_changed? && !ehp.is_activated? }

  before_save :ensure_dependencies_on_activation, if: proc { |ehp| ehp.is_activated? }

  scope :like, lambda { |q| where(self.arel_table[:plugin_name].matches("%#{q}%")) }
  scope :activated, lambda { where(activated: true) }
  scope :deactivated, lambda { where(activated: false) }

  def self.available_plugins
    available_plugins = Redmine::Plugin.all(only_visible: true).map { |i| i.id.to_s }
    available_plugins.concat RysManagement.all.select{ |i| i.hosting_plugin }.map { |i| i.rys_id.to_s } if Object.const_defined?(:RysManagement)
    available_plugins
  end

  def self.ensure_new_plugins
    (available_plugins - EasyHostingPlugin.pluck(:plugin_name)).map do |plugin|
      EasyHostingPlugin.create(plugin_name: plugin)
    end
  end

  def self.check_activations
    EasyHostingPlugin.where(activated: true).where(['activated_to < ?', Date.today.end_of_day]).each do |ehp|
      ehp.deactivate
    end
  end

  def plugin_disabled?
    if EasyHostingServices::EasyMultiTenancy.activated? &&
        EasyHostingServices::EasyMultiTenancy::PERMANENTLY_DISABLED_PLUGINS.include?(plugin_name)
      return true
    end

    !activated?
  end

  def should_be_trial?
    trial_count == 0
  end

  def make_trial
    return false unless should_be_trial?

    make_trial!
  end

  def make_trial!
    self.activated    = true
    self.activated_by = User.current.id
    self.activated_to = Date.today + TRIAL_DAYS.days
    self.trial_count  = self.trial_count + 1

    save
  end

  def activate(valid_to = nil)
    self.activated    = true
    self.activated_to = valid_to
    self.activated_by = User.current.id

    save
  end

  def deactivate
    self.activated = false

    save
  end

  def plugin
    Redmine::Plugin.find_or_nil(self.plugin_name)
  end

  def is_activated?
    self.activated_changed? && self.activated_was == false
  end

  def activated_unlimitedly?
    activated? && activated_to.nil?
  end

  private

  def ensure_dependencies_on_activation
    self.plugin.depends_on_plugins.each do |p|
      ehp = self.class.find_or_initialize_by(plugin_name: p.id)

      # Depended plugin must be activated as long as this plugin
      next if ehp.activated_unlimitedly?

      ehp.activated    = true
      ehp.activated_by = self.activated_by
      ehp.activated_to = self.activated_to
      ehp.trial_count  = ehp.trial_count + 1 if self.activated_to

      return false if !ehp.save
    end if self.plugin
  end

  def validate_dependencies_on_deactivation
    dependencies = self.plugin.dependent_plugins({ :without_disabled => true }) if self.plugin
    if dependencies.present?
      self.errors.add(:base, l(:error_easy_hosting_plugin_conflict, {
          :disabling => I18n.t(self.plugin.name),
          :disabled  => dependencies.map { |p| I18n.t(p.name) }.join(', ')
      }))
    end
  end

end

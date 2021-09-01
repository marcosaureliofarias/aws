class EasyPageModule < ActiveRecord::Base
  TRANSLATABLE_KEYS = []

  has_many :available_in_pages, :class_name => 'EasyPageAvailableModule', :foreign_key => 'easy_page_modules_id', :dependent => :destroy
  has_many :all_modules, :through => :available_in_pages, :dependent => :destroy
  has_many :all_template_modules, :through => :available_in_pages, :dependent => :destroy

  attr_accessor :page_zone_module, :template_zone_module

  class_attribute :registered_for_scope
  self.registered_for_scope = {}

  class_attribute :registered_for_page
  self.registered_for_page = {}

  class_attribute :registered_for_all
  self.registered_for_all = []

  class_attribute :registered_for_user_defined
  self.registered_for_user_defined = []

  def self.disabled_sti_class
    EpmDisabled
  end

  def self.translatable_keys
    self::TRANSLATABLE_KEYS
  end

  def self.register_to_page(*args)
    raise ArgumentError, 'Cannot register EasyPageModule. Use inherited class instead' if self == EasyPageModule

    opts = args.extract_options!

    args.each do |page_name|
      registered_for_page[page_name] ||= []
      registered_for_page[page_name] << [self, opts] if !registered_for_page[page_name].detect { |klass, _| klass == self }
    end

    return true
  end

  def self.register_to_scope(*args)
    raise ArgumentError, 'Cannot register EasyPageModule. Use inherited class instead' if self == EasyPageModule

    opts = args.extract_options!

    args.each do |scope_name|
      registered_for_scope[scope_name.to_s] ||= []
      registered_for_scope[scope_name.to_s] << [self, opts] if !registered_for_scope[scope_name.to_s].detect { |klass, _| klass == self }
    end

    return true
  end

  def self.register_to_all(opts = {})
    raise ArgumentError, 'Cannot register EasyPageModule. Use inherited class instead' if self == EasyPageModule

    registered_for_all << [self, opts] if !registered_for_all.detect { |klass, _| klass == self }

    return true
  end

  def self.register_to_user_defined(opts = {})
    raise ArgumentError, 'Cannot register EasyPageModule. Use inherited class instead' if self == EasyPageModule

    registered_for_user_defined << [self, opts] if !registered_for_user_defined.detect { |klass, _| klass == self }

    return true
  end

  def self.ensure_all_registered_modules
    install_all_registered_modules

    # TODO uninstall

    return true
  end

  def self.install_all_registered_modules
    EasyPage.all.each do |easy_page|
      install_all_registered_modules_to_page easy_page
    end

    return true
  end

  def self.install_all_registered_modules_to_page(easy_page)
    install_modules_to_page(registered_for_all, easy_page)
    install_modules_to_page(registered_for_page[easy_page.page_name], easy_page)
    install_modules_to_page(registered_for_user_defined, easy_page) if easy_page.is_user_defined?

    if !easy_page.page_scope.blank? && (modules = registered_for_scope[easy_page.page_scope])
      install_modules_to_page(modules, easy_page)
    end

    return true
  end

  def self.install_modules_to_page(modules_with_options, target_page_or_page_name)
    return true if modules_with_options.blank?

    modules_with_options.each do |klass, options|
      condition = options[:if]

      next unless condition.respond_to?(:call) ? condition.call : (condition.nil? ? true : condition)

      klass.install_to_page target_page_or_page_name
    end

    return true
  end

  def self.install_to_page(page_or_page_name)
    raise ArgumentError, 'Cannot install EasyPageModule. Use inherited class instead' if self == EasyPageModule

    if page_or_page_name.is_a?(EasyPage) && !page_or_page_name.new_record?
      easy_page = page_or_page_name
    else
      easy_page = EasyPage.where(:page_name => page_or_page_name.to_s).first
    end

    return false if !easy_page.is_a?(EasyPage)

    epm = self.where(:type => self.name).first
    epm = self.create! if epm.nil?

    EasyPageAvailableModule.create!(:easy_pages_id => easy_page.id, :easy_page_modules_id => epm.id) if EasyPageAvailableModule.where(:easy_pages_id => easy_page.id, :easy_page_modules_id => epm.id).empty?

    return true
  end

  def self.uninstall_from_page(page_or_page_name)
    raise ArgumentError, 'Cannot install EasyPageModule. Use inherited class instead' if self == EasyPageModule
  end

  def self.uninstall_from_all_pages
    raise ArgumentError, 'Cannot install EasyPageModule. Use inherited class instead' if self == EasyPageModule

    self.destroy_all
  end

  def self.css_icon
    ''
  end

  def module_name
    @module_name ||= self.class.name.underscore.sub('epm_', '')
  end

  def query_module?
    module_name.end_with?('_query')
  end

  def category_name
    raise ArgumentError, 'The category name cannot be null.'
  end

  def editable?
    true
  end

  def collapsible?
    true
  end

  def chart_included?(settings)
    false
  end

  def caching_available?
    false
  end

  def cache_on?(settings)
    caching_available?
  end

  def max_row_limit
    50
  end

  def show_path
    "easy_page_modules/#{category_name}/#{module_name}_show"
  end

  def edit_path
    if editable?
      "easy_page_modules/#{category_name}/#{module_name}_edit"
    else
      show_path
    end
  end

  def additional_basic_attributes_path
    nil
  end

  def page_module_toggling_container_options_helper_method
    "get_#{self.class.name.underscore}_toggling_container_options"
  end

  def get_show_data(settings, user, page_context = {})
    nil
  end

  def get_edit_data(settings, user, page_context = {})
    nil
  end

  def default_settings
    @default_settings ||= HashWithIndifferentAccess.new
  end

  def permissions
    []
  end

  def runtime_permissions(user)
    true
  end

  def translated_name
    l(module_name, :scope => [:easy_pages, :modules]).html_safe
  end

  def module_allowed?(user = nil)
    user ||= User.current
    return false if Redmine::Plugin.disabled?(registered_in_plugin)

    if self.permissions.blank?
      perm = true
    else
      perm = self.permissions.inject(true) do |allowed, perm|
        allowed && user.allowed_to?(perm, nil, :global => true)
      end
    end

    return false if !perm

    return (runtime_permissions(user) == true)
  end

  def registered_in_plugin
    klass_path = method(:category_name).source_location.first
    core_path  = EasyExtensions::EASYPROJECT_EASY_PLUGINS_DIR

    (klass_path.split('/') - core_path.split('/')).first
  end

  def before_from_params(page_module, params)
  end

  def output(settings)
    settings['outputs'].is_a?(Array) ? settings['outputs'].first : settings['output']
  end

  def add_additional_filters_from_global_filters!(page_context, query_settings)
    query_settings ||= {}

    if page_context[:active_global_currency]
      query_settings['easy_currency_code'] = page_context[:active_global_currency]
    end

    if page_context[:active_global_filters].is_a?(Hash) && query_settings['global_filters'].is_a?(Hash)
      query_settings['additional_filters'] = {}
      saved_filters                        = EasyExtensions::GlobalFilters.prepare_query_filters(query_settings['global_filters'])

      page_context[:active_global_filters].each do |filter_id, value|
        saved_filter = saved_filters[filter_id]
        next if saved_filter.blank?

        if saved_filter['set_previous_period'].to_s.to_boolean
          value += "<<-1"
        end

        # type DateFromToPeriod
        if value.respond_to?(:values)
          value = value.values.join('|')
        end

        query_settings['additional_filters'][saved_filter['filter']] = value
      end
    end
  end

  def get_row_limit(limit)
    limit = (limit.presence || 10).to_i
    if limit < 1 || limit > max_row_limit
      limit = max_row_limit
    end
    limit
  end

  def page_zone_module_before_save(pzm)
  end

  def page_zone_module_after_load(pzm)
  end

  def deprecated?
    false
  end

  def snapshot_supported?
    false
  end

  def snapshot?
    page_zone_module&.settings&.dig('daily_snapshot') == '1'
  end

  def snapshot_initialized?
    page_zone_module&.easy_query_snapshot.present?
  end

end

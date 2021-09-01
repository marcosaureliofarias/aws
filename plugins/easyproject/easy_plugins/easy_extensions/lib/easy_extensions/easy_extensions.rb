module EasyExtensions

  @@domain_name, @@version, @@platform_version, @@build_version, @@additional_installer_rake_tasks = nil, nil, nil, nil, []

  mattr_writer :easy_quotes_engine

  mattr_accessor :deferred_js
  self.deferred_js = true

  # Skip rails middleware XmlParamsParser if path start with
  #mattr_accessor :skip_middleware_xml_parser_for
  #self.skip_middleware_xml_parser_for = %w(/webdav /carddav /caldav)

  mattr_accessor :global_filters_enabled
  self.global_filters_enabled = false

  mattr_accessor :chart_onclick_enabled
  self.chart_onclick_enabled = false

  mattr_accessor :easy_rake_tasks_trigger
  self.easy_rake_tasks_trigger = 'rake'

  EASY_HELPERS_DIR                       = 'easy_helpers'
  EASY_PLUGINS_DIR                       = 'easy_plugins'
  RELATIVE_EASYPROJECT_PLUGIN_PATH       = File.join('plugins', 'easyproject')
  RELATIVE_EASYPROJECT_EASY_PLUGINS_PATH = File.join(RELATIVE_EASYPROJECT_PLUGIN_PATH, EASY_PLUGINS_DIR)
  PATH_TO_EASYPROJECT_ROOT               = File.join(Rails.root, RELATIVE_EASYPROJECT_PLUGIN_PATH)
  INSTALLATION_TASKS                     = /install|migrate|multitenants|precompile/

  EASYPROJECT_EASY_PLUGINS_DIR = File.join(Rails.root, RELATIVE_EASYPROJECT_EASY_PLUGINS_PATH)
  EASY_EXTENSIONS_DIR          = File.join(EASYPROJECT_EASY_PLUGINS_DIR, 'easy_extensions')

  DEFAULT_PDF_LOGO_FILENAME = 'default_pdf_logo.png'

  SUPPORTED_LANGS = %i(ar cs da de en es fi fr he hr hu it ja ka ko mk nl no
                    pl pt-BR pt ro th tr sk sl sq sr sr-YU sv ru zh-TW zh)

  REDMINE_CUSTOM_FIELDS = %w(DocumentCategoryCustomField GroupCustomField IssueCustomField IssuePriorityCustomField ProjectCustomField
                           TimeEntryActivityCustomField TimeEntryCustomField UserCustomField VersionCustomField)

  CACHE_CSS_NAME        = 'easy_stylesheets'
  CACHE_JS_NAME         = 'easy_javascripts'
  REDMINE_CACHE_JS_NAME = 'redmine_cached_js'

  def self.domain_name
    Rails.cache.fetch('easy_extensions/domain_name') do
      begin
        [Setting.host_name, (Rails.root.to_s.split(/[\\\/]/) - ['public_html']).last].uniq.join('#')
      rescue
        'nodomain'
      end
    end
  end

  def self.easy_quotes_engine_instance
    @@easy_quotes_engine ||= EasyExtensions::EasyQuotes::EasyCustomQuotesEngine.new
  end

  def self.version
    unless @@version
      ep_site_version = nil
      version_path    = File.join(Rails.root, 'version')
      File.open(version_path, 'r') do |f|
        begin
          ep_site_version = f.readline
        rescue
        end
      end if File.exists?(version_path)
      @@version = ep_site_version.to_s.strip
      @@version = '(brand not detected)' if @@version.blank?
    end
    @@version
  end

  def self.platform_version
    unless @@platform_version
      ep_site_version = nil
      version_path    = File.join(Rails.root, 'platform_version')
      File.open(version_path, 'r') do |f|
        begin
          ep_site_version = f.readline
        rescue
        end
      end if File.exists?(version_path)
      @@platform_version = ep_site_version.to_s.strip
      @@platform_version = '(platform not detected)' if @@platform_version.blank?
    end
    @@platform_version
  end

  def self.build_version
    unless @@build_version
      ep_site_version = nil
      version_path    = File.join(Rails.root, 'build_version')
      File.open(version_path, 'r') do |f|
        begin
          ep_site_version = f.readline
        rescue
        end
      end if File.exists?(version_path)
      @@build_version = ep_site_version.to_s.strip
      @@build_version = '(build not detected)' if @@build_version.blank?
    end
    @@build_version
  end

  def self.full_version
    platform_version
  end

  def self.render_sidebar?(controller_name, action_name, params)
    val = EasyProjectSettings.disabled_sidebar[controller_name]
    if val.is_a?(Hash)
      if (val.has_key?(action_name))
        ca_val = val[action_name]
        if (ca_val.is_a?(String))
          return false
        elsif (ca_val.is_a?(Hash))
          ca_val.each do |k, v|
            unless (params[k].nil?)
              return false if params[k] == v
            end
          end
        end
      end
    elsif val.is_a?(Array)
      return false if val.include?(action_name)
    end if (val)

    return true
  end

  def self.easy_searchable_column_types
    @@easy_searchable_column_types ||= %w(name description comment other)
  end

  def self.register_additional_installer_tasks(task_name)
    @@additional_installer_rake_tasks ||= []
    @@additional_installer_rake_tasks << task_name unless @@additional_installer_rake_tasks.include?(task_name)
  end

  def self.additional_installer_rake_tasks
    @@additional_installer_rake_tasks || []
  end

  def self.puts(msg)
    STDOUT.puts(msg.to_s) if STDOUT && !Rails.env.test?
  end

  def self.debug_mode?(context = nil)
    @debug_mode ||= Rails.env.development? && File.exists?(Rails.root.join('tmp', 'debug'))
  end

  module EasyProjectSettings

    mattr_accessor :disabled_sidebar
    self.disabled_sidebar = { 'calendars' => ['show'], 'users' => { 'edit' => { 'tab' => 'my_page' } } }

    mattr_accessor :disabled_features
    self.disabled_features = {
        modules:                %w(boards files wiki wiki_edits messages user_allocations easy_other_permissions easy_attendances gantt calendar),
        permissions:            { 'boards'   => :all, 'files' => :all, 'wiki' => :all, 'wiki_edits' => :all,
                                  'messages' => :all, 'easy_attendances' => :all, 'gantt' => :all, 'calendar' => :all },
        notifiables:            %w(wiki_content_added wiki_content_updated message_posted),
        search_types:           %w(wiki_pages messages),
        suggester_search_types: %w(changesets messages projects),
        others:                 []
    }

    mattr_accessor :easy_color_schemes_count
    self.easy_color_schemes_count = 7

    mattr_accessor :easy_attendance_enabled
    self.easy_attendance_enabled = false

    mattr_accessor :app_name
    self.app_name = 'Easy Project'

    mattr_accessor :app_link
    self.app_link = 'www.easyproject.cz'

    mattr_accessor :app_email
    self.app_email = 'podpora@easyproject.cz'

    mattr_accessor :enable_copying_files_on_restart
    self.enable_copying_files_on_restart = true

    mattr_accessor :enable_copying_easy_images_to_public
    self.enable_copying_easy_images_to_public = true

    mattr_accessor :default_chart_colors
    self.default_chart_colors = %w(#4bb2c5 #eaa228 #c5b47f #579575 #839557 #958c12 #953579 #4b5de4 #d8b83f
                                #ff5800 #0085cc #c747a3 #cddf54 #fbd178 #26b4e3 #bd70c7)

    mattr_accessor :enable_easy_linux_friend
    self.enable_easy_linux_friend = false

    mattr_accessor :enable_easy_enhanced_repository
    self.enable_easy_enhanced_repository = false

    mattr_accessor :default_pdf_logo
    self.default_pdf_logo = File.join(EASY_EXTENSIONS_DIR, 'assets', 'images', DEFAULT_PDF_LOGO_FILENAME)

    mattr_accessor :default_pdf_logo_image
    self.default_pdf_logo_image = '/plugin_assets/easy_extensions/images/' << DEFAULT_PDF_LOGO_FILENAME

    mattr_accessor :iconset
    self.iconset = Pathname.new(EasyExtensions::EASY_EXTENSIONS_DIR).join('assets/stylesheets/scss/_variables_icons.scss')

    mattr_accessor :enable_action_cable
    self.enable_action_cable = false

    # Define a minimal column width for table.list
    # Its defined in Ruby because its much easier to modify
    #   the Array from other plugins or patches
    mattr_accessor :min_columns_widths
    self.min_columns_widths = {
      project: 200,
      attachments: 200,
      watchers: 200,
      parent_project: 200,
      parent: 200,
      relations: 200,
      main_project: 200,
      easy_helpdesk_mailbox_username: 200,

      easy_email_cc: 180,
      easy_email_to: 180,

      assigned_to: 150,
      author: 150,
      activity: 150,
      category: 150,
      closed_on: 150,
      easy_closed_by: 150,
      created_on: 150,
      due_date: 150,
      updated_on: 150,
      easy_last_updated_by: 150,
      fixed_version: 150,
      easy_next_start: 150,
      parent_category: 150,
      start_date: 150,
      tags: 150,
      root_category: 150,
      easy_helpdesk_project_monthly_hours: 150,
      easy_response_date_time: 150,
      easy_due_date_time: 150,
      issue_easy_sprint_relation: 150,

      done_ratio: 120,
      status: 120,
      estimated_hours: 120,
      remaining_timeentries: 120,
      spent_hours: 120,
      total_estimated_hours: 120,
      total_remaining_timeentries: 120,
      total_spent_hours: 120,
      total_spent_estimated_timeentries: 120,
      easy_helpdesk_need_reaction: 120,

      open_duration_in_hours: 110,

      is_private: 100,
      easy_status_updated_on: 100,
      spent_estimated_timeentries: 100,
      easy_response_date_time_remaining: 100,
      easy_story_points: 100,
      tracker: 100,

      priority: 90,
    }

    def self.available_event_types
      Redmine::Activity.available_event_types - disabled_features[:modules]
    end
  end

  # Hack for localizable menu attributes
  class MenuManagerProc < Proc
    def to_s
      self.call
    end
  end

end

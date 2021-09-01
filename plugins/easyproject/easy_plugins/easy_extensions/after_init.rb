Rack::Utils.multipart_part_limit = 0

require_relative './lib/easy_extensions/easy_extensions'
require_relative './lib/easy_extensions/easy_quotes/easy_quotes_engine'
require_relative './lib/easy_extensions/after_start_scripts'
require_relative './lib/easy_extensions/easy_proposer'
require_relative './lib/actionmailer/easy_action_mailer_log_subscriber'
require 'net/imap'
require 'rubyXL/convenience_methods/cell'
require 'rubyXL/convenience_methods/font'
require 'rubyXL/convenience_methods/workbook'
require 'rubyXL/convenience_methods/worksheet'

ActiveSupport::Dependencies.autoload_paths << File.join(EasyExtensions::EASY_EXTENSIONS_DIR, 'app', 'controllers', 'admin')
ActiveSupport::Dependencies.autoload_paths << File.join(EasyExtensions::EASY_EXTENSIONS_DIR, 'app/decorators')
ActiveSupport::Dependencies.autoload_paths << File.join(EasyExtensions::EASY_EXTENSIONS_DIR, 'app/channels')
ActiveSupport::Dependencies.autoload_paths << File.join(EasyExtensions::EASY_EXTENSIONS_DIR, 'lib', 'easy_extensions', 'easy_jobs')

ActionView::Base.include(EntityAttributeHelper)
ActionMailer::EasyLogSubscriber.attach_to :action_mailer

relative_paths = %w[/lib/utils]
relative_paths.each do |path|
  Dir.entries(File.dirname(__FILE__) + path).each do |file|
    next unless file.end_with?('.rb')
    require_relative "./#{path}/#{file}"
  end
end

Dir[File.dirname(__FILE__) + '/test/mailers/previews/*.rb'].each { |file| require_dependency file } if Rails.env.development?

if EasyExtensions::EasyProjectSettings.enable_copying_files_on_restart
  copy_to_public = lambda do |file|
    FileUtils.cp(
      File.join(EasyExtensions::PATH_TO_EASYPROJECT_ROOT, 'easy_plugins/easy_extensions/extra/to_copy', file),
      File.join(Rails.root, 'public', file)
    )
  end

  copy_to_db_migrate = lambda do |file|
    FileUtils.cp(
      File.join(EasyExtensions::PATH_TO_EASYPROJECT_ROOT, 'easy_plugins/easy_extensions/extra/to_copy', file),
      File.join(Rails.root, 'db/migrate', file)
    )
  end

  copy_to_public.call('404.html')
  copy_to_public.call('500.html')
  copy_to_public.call('browserconfig.xml')
  copy_to_db_migrate.call('20150921204850_change_time_entries_comments_limit_to_1024.rb')
  copy_to_db_migrate.call('20161002133421_add_index_on_member_roles_inherited_from.rb')
end

# Load plurals langfiles.
I18n.load_path                 += Dir[File.join(EasyExtensions::EASY_EXTENSIONS_DIR, 'config', 'locales', '*.{rb}')]
I18n.fallbacks                 = I18n::Locale::Fallbacks.new(sk: :cs)

# ActionController::Session::CookieStore::CookieOverflow Error
ActionDispatch::Cookies.send(:remove_const, :MAX_COOKIE_SIZE)
ActionDispatch::Cookies.const_set(:MAX_COOKIE_SIZE, 8.kilobytes)

Rails.application.configure do
  config.active_record.observers       = [:issue_invitation_observer]
  config.i18n.enforce_available_locales = false
  config.action_cable.connection_class = -> { EasyConnection }

  assets_dir = Redmine::Plugin.find(:easy_extensions).assets_directory
  config.assets.paths << File.join(assets_dir, 'easy_fonts')
  config.assets.paths << File.join(assets_dir)
  config.assets.precompile.concat Dir.glob(File.join(assets_dir, 'easy_fonts', '*'))
  config.assets.precompile.concat Dir.glob(File.join(assets_dir, 'javascripts', 'moment_locales', '*'))
  precompile_css = %w(easy_print.css easy_theme.css easy_chart/c3.css easy_jquery_ui/jquery-ui.css)
  precompile_js  = %w(projectindex.js easy_page.js redmine_attachments.js easygantt.js galereya/jquery.galereya.js easy_project_form.js easy_chart/easy_chart.js tablesaw/tablesaw.stackonly.jquery.js easy_page_modules/others/activity_feed.js)
  precompile_js.concat %w(easy_extensions_blocking.js jquery.color.js avatarcrop.js jquery.ui.touch-punch.js agile/easy_agile.js easy_cable.js roles.js)
  config.assets.precompile.concat precompile_css.collect { |n| File.join(assets_dir, 'stylesheets', n) }
  config.assets.precompile.concat precompile_js.collect { |n| File.join(assets_dir, 'javascripts', n) }


  config.assets.precompile += %w( cocoon.js )
  config.assets.precompile << File.join(assets_dir, 'javascripts', 'dart.js')
  config.assets.precompile << File.join(assets_dir, 'javascripts', 'dart.min.js')

  if Rails.env.production?
    config.exceptions_app = lambda do |env|
      request_path = env['REQUEST_PATH'].to_s

      # See RFC 5785
      # If something well-know does not exist -> it should return 404
      # and not 422 with big html body
      if request_path.start_with?('/.well-known')
        [404, {}, ['Not found']]
      else
        EasyErrorsController.action(:show).call(env)
      end
    end
  end

end

EasyExtensions::PatchManager.register_easy_page_controller 'EasyPageLayoutController', 'EasyPageTemplateLayoutController', 'EasyResourceAvailabilitiesController',
                                                           'MyController', 'ProjectsController', 'UsersController', 'EasyPageTemplatesController', 'EasyQueriesController', 'EasyPagesController', 'EasyExtensions::Export::Pdf',
                                                           'EasyEntityAssignmentsController', 'EasyPageTabsController', 'EasyTimeEntriesController', 'EasyVersionsController'

EasyExtensions::PatchManager.register_easy_page_helper 'AttachmentsHelper', 'CustomFieldsHelper', 'EasyAttendancesHelper',
                                                       'EasyIconsHelper', 'EasyJournalHelper', 'EasyPageModulesHelper', 'EasyQueryHelper', 'EpmEntityCreateNewHelper',
                                                       'IssuesHelper', 'IssueRelationsHelper', 'JournalsHelper', 'ProjectsHelper', 'SortHelper', 'TimelogHelper', 'UsersHelper', 'EasyRakeTasksHelper', 'EasyActivitiesHelper'

require_relative './lib/easy_extensions/easy_translator'
require_dependency 'easy_extensions/easy_page_modules'
require_dependency 'easy_extensions/identity_providers'
require_dependency 'easy_extensions/identity_services'

EasyExtensions::AfterStartScripts.add do
  ApplicationHelper.define_easy_links_re
end

EasyExtensions::AfterInstallScripts.add do
  if Redmine::Plugin.installed?(:easy_printable_templates)
    EasyPrintableTemplate.create_from_view!(HashWithIndifferentAccess.new(:name => 'QR', :category => 'easy_qr'), :plugin_name => 'easy_extensions', :internal_name => 'easy_qr')
  end
end

EasyExtensions::AfterInstallScripts.add do
  EasyRakeTaskInfo.where(:status => EasyRakeTaskInfo::STATUS_RUNNING).update_all(:status => EasyRakeTaskInfo::STATUS_ENDED_FORCED)

  EasyPage.where(is_user_defined: false, has_template: false, page_scope: nil).update_all(has_template: true)
end

EasyExtensions::AfterInstallScripts.add do
  require 'utils/easy_page'

  store                = File.join(EasyExtensions::EASYPROJECT_EASY_PLUGINS_DIR, 'easy_extensions/assets/xml_data_store')
  spent_time_data_file = File.join(store, 'spent_time_overview.zip')
  milestones_data_file = File.join(store, 'milestones_overview.zip')

  EasyUtils::EasyPage.import_dashboard(page_name: 'spent-time-overview', data_file: spent_time_data_file, version: 2)
  EasyUtils::EasyPage.import_dashboard(page_name: 'milestones-overview', data_file: milestones_data_file, version: 2)
end

# this block is runed once just after easyproject is started
# means after all plugins(easy) are initialized
ActiveSupport.on_load(:easyproject, yield: true) do
  require 'rails/observers/activerecord/active_record'

  require_relative './lib/easy_extensions/hooks'
  require_relative './lib/easy_extensions/menus'
  require_relative './lib/easy_extensions/permissions'
  require_relative './lib/easy_extensions/proposer'
  require_relative './lib/easy_extensions/internals'
  require_relative './lib/easy_extensions/easy_settings'

  # To prevent circular dependency error
  require_dependency 'easy_issue_mail_handler'

  # Touch
  require 'easy_extensions/permission_resolver'
  require 'easy_extensions/context_menu_resolver'

  Rails.application.configure do
    config.action_cable.allowed_request_origins = ["#{Setting.protocol}://#{Setting.host_name}"]
  end

  LetterAvatar.setup do |config|
    config.fill_color      = 'rgba(255, 255, 255, 1)' # default is 'rgba(255, 255, 255, 0.65)'
    config.cache_base_path = 'public/images/easy_images' # default is 'public/system'
    config.colors_palette  = :iwanthue # default is :google
    # config.weight            = 500                       # default is 300
    # config.annotate_position = '-0+10'                   # default is -0+5
    config.letters_count = 2 # default is 1
    config.pointsize     = 280 # default is 140
  end
end

# this block is called every time rails are reloading code
# in development it means after each change in observed file
# in production it means once just after server has started
RedmineExtensions::Reloader.to_prepare do

  if observers = Rails.configuration.active_record.observers
    ActiveRecord::Base.send :observers=, observers
  end

  Dir[File.dirname(__FILE__) + '/lib/easy_extensions/validators/*.rb'].each { |file| require_dependency file }
  Dir[File.dirname(__FILE__) + '/lib/easy_extensions/field_formats/*.rb'].each { |file| require_dependency file }
  Dir[File.dirname(__FILE__) + '/lib/easy_extensions/paperclip_preprocessors/*.rb'].each { |file| require_dependency file }
  Dir[File.dirname(__FILE__) + '/lib/easy_extensions/image_processing/*.rb'].each { |file| require_dependency file }
  Dir[File.dirname(__FILE__) + '/lib/easy_extensions/image_processing/adapters/*.rb'].each { |file| require_dependency file }
  Dir[File.dirname(__FILE__) + '/lib/easy_extensions/image_processing/adapters/*.rb'].each { |file| require_dependency file }
  Dir[File.dirname(__FILE__) + '/lib/easy_extensions/views/*.rb'].each { |file| require_dependency file }
  Dir[File.dirname(__FILE__) + '/lib/easy_attendances/*.rb'].each { |file| require file }

  require_dependency 'easy_extensions/easy_xml_data/importer'
  require_dependency 'easy_version_category'
  require_dependency 'easy_extensions/yaml_encoder'
  require_dependency 'easy_extensions/easy_external_authentications/easy_external_authentication_provider'
  require_dependency 'easy_extensions/easy_entity_cards/base'
  require_dependency 'easy_extensions/easy_assets'
  require_dependency 'easy_extensions/easy_qr'
  require_dependency 'easy_extensions/easy_tag'
  require_dependency 'easy_extensions/easy_msg_reader'

  if Object.const_defined?(:Oj)
    Oj.optimize_rails
    Oj.default_options = { :mode => :rails }
  end

  # Touch to register subclass
  EasyProjectPriority
  EasyCustomFieldGroup

  # Jobs
  require 'easy_job'

  CustomFieldsHelper::CUSTOM_FIELDS_TABS << { :name => EasyProjectTemplateCustomField.name, :partial => 'custom_fields/index', :label => :label_templates_plural }
  CustomFieldsHelper::CUSTOM_FIELDS_TABS << { :name => 'AttachmentCustomField', :partial => 'custom_fields/index', :label => :label_attachment_plural }

  Redmine::Search.map do |search|
    EasyExtensions::EasyProjectSettings.disabled_features[:search_types].each { |s_t| search.unregister s_t }
  end

  # if EasyExtensions.debug_mode? && File.exists?(Rails.root.join('tmp', 'debug'))
  #   puts 'WARNING: starting in a debug mode!'
  #   require 'easy_extensions/easy_performance_watcher'
  #   Dir[File.dirname(__FILE__) + '/extra/debug/*.rb'].each {|file| require file }
  # end

  require_relative './lib/easy_extensions/easy_repeaters'
  EasyExtensions::EntityRepeater.map do |mapper|
    mapper.register EasyExtensions::IssueRepeater.new
  end

  # excel export
  Mime::Type.register 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet', :xlsx
  Mime::Type.register_alias 'text/javascript', :qr

  Dir.entries(File.dirname(__FILE__) + '/lib/easy_extensions/easy_lookups').each do |file|
    next unless file.end_with?('.rb')
    require_relative "./lib/easy_extensions/easy_lookups/#{file}"
  end
  EasyExtensions::EasyLookups::EasyLookup.map do |easy_lookup|
    easy_lookup.register 'EasyExtensions::EasyLookups::EasyLookupDocument'
    easy_lookup.register 'EasyExtensions::EasyLookups::EasyLookupGroup'
    easy_lookup.register 'EasyExtensions::EasyLookups::EasyLookupIssue'
    easy_lookup.register 'EasyExtensions::EasyLookups::EasyLookupProject'
    easy_lookup.register 'EasyExtensions::EasyLookups::EasyLookupUser'
    easy_lookup.register 'EasyExtensions::EasyLookups::EasyLookupVersion'
  end

  # EasyExtensions::Websocket::EventPublisher.start_polling!

  # List of queries displayed to user on review pages(etc. my_page, sidebar, ...)
  EasyQuery.map do |query|
    query.register 'EasyIssueQuery'
    query.register 'EasyProjectQuery'
    query.register 'EasyProjectTemplateQuery'
    query.register 'EasyUserQuery'
    query.register 'EasyVersionQuery'
    query.register 'EasyAttendanceQuery'
    query.register 'EasyTimeEntryQuery'
    query.register 'EasyIssueTimerQuery'
    query.register 'EasyEasyQueryQuery'
    query.register 'EasyDocumentQuery'
    query.register 'EasyAttendanceUserQuery'
  end

  EasyApiEntity.tap do |api_entity|
    api_entity.register EasyApiDecorators::Issue
    api_entity.register EasyApiDecorators::Project
    api_entity.register EasyApiDecorators::TimeEntry
    api_entity.register EasyApiDecorators::Journal
  end

  RedmineExtensions::BasePresenter.register 'EasyExtensions::EasyQueryHelpers::EasyQueryPresenter', 'EasyQuery'

  EasyExtensions::EasyQueryHelpers::EasyQueryOutput.register_output EasyExtensions::EasyQueryOutputs::ListOutput
  EasyExtensions::EasyQueryHelpers::EasyQueryOutput.register_output EasyExtensions::EasyQueryOutputs::ChartOutput
  EasyExtensions::EasyQueryHelpers::EasyQueryOutput.register_output EasyExtensions::EasyQueryOutputs::CalendarOutput
  EasyExtensions::EasyQueryHelpers::EasyQueryOutput.register_output EasyExtensions::EasyQueryOutputs::ReportOutput
  EasyExtensions::EasyQueryHelpers::EasyQueryOutput.register_output EasyExtensions::EasyQueryOutputs::TilesOutput
  EasyExtensions::EasyQueryHelpers::EasyQueryOutput.register_output EasyExtensions::EasyQueryOutputs::MapOutput

  %w(data file smb).each { |i| Loofah::HTML5::SafeList::ALLOWED_PROTOCOLS.add(i) }

  ActiveSupport::Inflector.inflections do |inflect|
    inflect.uncountable 'GroupAnonymous'
  end

  EasySetting.map.boolean_keys(:project_calculate_start_date, :project_calculate_due_date, :timelog_comment_editor_enabled,
                               :time_entry_spent_on_at_issue_update_enabled, :commit_logtime_enabled, :project_fixed_activity,
                               :enable_activity_roles, :show_issue_id, :commit_cross_project_ref, :issue_recalculate_attributes,
                               :use_easy_cache, :avatar_enabled, :show_personal_statement, :show_bulk_time_entry,
                               :enable_private_issues, :display_issue_relations_on_new_form, :milestone_effective_date_from_issue_due_date,
                               :allow_log_time_to_closed_issue, :project_display_identifiers, :issue_set_done_after_close, :allow_repeating_issues,
                               :required_issue_id_at_time_entry, :required_time_entry_comments, :close_subtask_after_parent, :show_time_entry_range_select,
                               :easy_contact_toolbar_is_enabled, :issue_private_note_as_default, :show_easy_resource_booking,
                               :skip_workflow_for_admin, :hide_login_quotes, :display_project_field_on_issue_detail,
                               :easy_invoicing_use_estimated_time_for_issues, :easy_invoicing_use_easy_money_currency_settings, :hide_imagemagick_warning,
                               :time_entries_locking_enabled, :display_journal_details,
                               :easy_webdav_enabled,
                               :show_avatars_on_query,
                               :easy_user_allocation_by_project_enabled,
                               :ckeditor_syntax_highlight_enabled,
                               :issue_copy_notes_to_parent,
                               :default_project_inherit_members,
                               :ckeditor_autolink_file_protocols,
                               :show_easy_custom_formatting,
                               :show_easy_entity_activity_on_issue,
                               :html5_dates,
                               :dont_verify_server_cert,
                               :chart_numbers_format,
                               :enable_sso,
                               :query_string_enabled,
                               :use_default_user_type_role_for_new_project,
                               :default_no_notified_as_previous_assignee
  )

  EasySetting.map do
    key :easy_online_status_expiration_seconds do
      default 600
    end
    key :project_destroy_preferred_hour do
      default 2
    end
  end

  EasyExtensions::AfterStartScripts.execute

  EasyEntityActivityCategory

  EasyMonitoring::Metadata.configure do |metadata|
    metadata.host_name = Setting.host_name
    metadata.full_version = EasyExtensions.full_version
    metadata.platform_version = EasyExtensions.platform_version
    metadata.build_version = EasyExtensions.build_version
    metadata.db_check = User.any?
  end

end

# ActiveJob required (maybe later)
#
# require 'sucker_punch/async_syntax'
#
# Rails.application.configure do
#   config.active_job.queue_adapter = :sucker_punch
# end

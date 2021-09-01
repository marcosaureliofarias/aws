Dir[File.dirname(__FILE__) + '/lib/easy_redmine/easy_patch/**/*.rb'].each { |file| require_dependency file }

EasyExtensions::EasyProjectSettings.app_name  = 'Easy Redmine'
EasyExtensions::EasyProjectSettings.app_link  = 'www.easyredmine.com'
EasyExtensions::EasyProjectSettings.app_email = 'support@easyredmine.com'
EasyExtensions::EasyProjectSettings.disabled_features[:modules].delete_if { |x| ['boards', 'files', 'wiki', 'wiki_edits', 'messages', 'repository', 'calendar'].include?(x) }
EasyExtensions::EasyProjectSettings.disabled_features[:permissions].delete_if { |x, v| ['boards', 'files', 'wiki', 'wiki_edits', 'messages', 'repository', 'calendar'].include?(x) }
EasyExtensions::EasyProjectSettings.disabled_features[:notifiables].delete_if { |x| ['wiki_content_added', 'wiki_content_updated', 'file_added', 'message_posted'].include?(x) }
EasyExtensions::EasyProjectSettings.disabled_features[:search_types].delete_if { |x| ['wiki_pages', 'messages'].include?(x) }

# Rails.application.config.i18n.load_path += Dir.glob(File.dirname(__FILE__) + '/config/locales/**/*.yml').sort

if defined?(EasyExtensions::EasyProjectSettings.default_pdf_logo) && defined?(EasyExtensions::EasyProjectSettings.default_pdf_logo_image)
  EasyExtensions::EasyProjectSettings.default_pdf_logo       = File.join(EasyExtensions::EASYPROJECT_EASY_PLUGINS_DIR, 'easy_redmine', 'assets', 'images', 'default_pdf_logo.png')
  EasyExtensions::EasyProjectSettings.default_pdf_logo_image = '/plugin_assets/easy_redmine/images/default_pdf_logo.png'
end

unless Redmine::Plugin.installed?(:easy_jp)
  langs = EasyExtensions::SUPPORTED_LANGS
  EasyExtensions.send(:remove_const, :SUPPORTED_LANGS)
  EasyExtensions.const_set(:SUPPORTED_LANGS, langs - [:ja])
end

if EasyExtensions::EasyProjectSettings.enable_copying_files_on_restart
  begin
    FileUtils.cp("#{EasyExtensions::PATH_TO_EASYPROJECT_ROOT}/easy_plugins/easy_redmine/lib/easy_redmine/to_copy/404.html", "#{Rails.root}/public/404.html")
    FileUtils.cp("#{EasyExtensions::PATH_TO_EASYPROJECT_ROOT}/easy_plugins/easy_redmine/lib/easy_redmine/to_copy/500.html", "#{Rails.root}/public/500.html")
    FileUtils.cp("#{EasyExtensions::PATH_TO_EASYPROJECT_ROOT}/easy_plugins/easy_redmine/lib/easy_redmine/to_copy/502.html", "#{Rails.root}/public/502.html")
    FileUtils.cp("#{EasyExtensions::PATH_TO_EASYPROJECT_ROOT}/easy_plugins/easy_redmine/assets/images/favicon/favicon.ico", "#{Rails.root}/public/favicon.ico")
  rescue
  end
end

ActiveSupport.on_load(:easyproject, yield: true) do

  require 'easy_redmine/hooks'
  require 'easy_redmine/menus'

  EasyInvoicing::EasyInvoicingSettings.invoicing_path = '/invoicing' if Redmine::Plugin.installed?(:easy_invoicing)

  Redmine::Plugin.bundled_plugin_ids = {
      basic:     [
                     :easy_gantt,
                     :easy_gantt_pro,
                     :easy_baseline,
                     :easy_project_attachments,
                     :easy_printable_templates,
                     :easy_quick_project_planner,
                     :easy_instant_messages,
                     :easy_to_do_list,
                     :easy_buttons,
                     :easy_calendar,
                     :easy_zoom
                 ],
      resource:  [
                     :easy_resource_dashboard,
                     :easy_gantt_resources,
                     :easy_attendances
                 ],
      finance:   [
                     :easy_money,
                     :easy_budgetsheet,
                     :easy_calculation,
                     :easy_cash_desks,
                     :easy_personal_finances
                 ],
      customers: [
                     :easy_crm,
                     :easy_contacts,
                     :easy_price_books
                 ],
      helpdesk:  [
                     :easy_helpdesk,
                     :easy_alerts
                 ],
      agile:     [
                     :easy_agile_board,
                     :redmine_test_cases
                 ],
      strategic: [
                     :easy_wbs,
                     :easy_knowledge,
                     :easy_earned_values,
                     :easy_business_dashboards,
                     :easy_org_chart,
                     :redmine_re
                 ],
      extra:     [
                     :redmine_dmsf,
                     :easy_entities_sequences,
                     :easy_theme_designer,
                     :easy_computed_custom_fields,
                     :easy_timesheets
                 # :outlook_integration
                 ]
  }

  EasyExtensions::Logo.configure do |config|
    config.path = proc do
      if EasySetting.value('ui_theme')
        File.expand_path(File.join(__dir__, 'assets', 'images', 'logo_18.png'))
      else
        File.expand_path(File.join(__dir__, 'assets', 'images', 'logo.png'))
      end
    end

  end

end

Rails.application.configure do
  config.assets.precompile += %w( manifest.json easy_redmine/er18.css)
end
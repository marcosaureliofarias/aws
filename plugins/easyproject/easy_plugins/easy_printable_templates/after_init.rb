EasyExtensions.register_additional_installer_tasks('easyproject:easy_printable_templates:generate_pdfkit_initializer')

EasyExtensions::PatchManager.register_easy_page_controller 'EasyPrintableTemplatesController'

RedmineExtensions::Reloader.to_prepare do

  EasyQuery.map do |query|
    query.register 'EasyPrintableTemplateQuery'
  end

  if Redmine::Plugin.installed?(:easy_data_templates)
    Dir[File.dirname(__FILE__) + '/lib/easy_printable_templates/easy_xml_data/export/*.rb'].each {|file| require file }
  end
  Dir[File.dirname(__FILE__) + '/lib/easy_printable_templates/easy_xml_data/importables/*.rb'].each {|file| require file }

end

ActiveSupport.on_load(:easyproject, yield: true) do
  require 'easy_printable_templates/proposer'
  require 'easy_printable_templates/hooks'

  Redmine::MenuManager.map :admin_menu do |menu|
    menu.push(:easy_printable_templates_plugin_name, { controller: 'easy_printable_templates', action: 'index', format: nil }, {
        :parent => :documents,
        :if => Proc.new { User.current.admin? },
        :html => { :class => 'icon icon-print', :title => :title_other_formats_links_print },
        :caption => :easy_printable_templates_plugin_name,
        :after => :easy_pdf_themes
      })
  end

  Redmine::AccessControl.map do |map|
    map.project_module :easy_other_permissions do |pmap|
      pmap.permission :view_easy_printable_templates, {
        :easy_printable_templates => [:index, :template_chooser, :preview, :save_to_pdf, :save_to_document, :save_to_attachment, :show, :generate_docx_from_attachment],
      }, :read => true, :global => true

      pmap.permission :manage_easy_printable_templates, {
        :easy_printable_templates => [:new, :edit, :update, :create, :destroy, :copy_with_pages],
      }, :global => true

      pmap.permission :manage_own_easy_printable_templates, {
        :easy_printable_templates => [:new, :edit, :update, :create, :destroy, :copy_with_pages],
      }, :global => true
    end
  end
end

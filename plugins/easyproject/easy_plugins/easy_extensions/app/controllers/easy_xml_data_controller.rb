class EasyXmlDataController < ApplicationController

  layout 'admin'
  menu_item(:easy_xml_data_import)
  menu_item :easy_xml_data_export, :only => [:export_settings, :export]

  before_action :require_admin
  before_action :check_exporter, :only => [:export_settings, :export]
  before_action :create_exporter, :only => [:export]

  include ActionView::Helpers::TextHelper

  def export_settings
    @projects          = Project.order('lft ASC')
    @exportables       = EasyXmlData::Exporter.exportables
    @exportable_labels = EasyXmlData::Exporter.exportable_labels
  end

  def export
    filename = get_filename
    filename.tr!(' ', '_')

    archive_file = @exporter.build_archive
    respond_to do |format|
      format.api do
        send_file(archive_file, filename: filename, disposition: 'attachment')
      end
    end
  end

  def import
    importer                  = EasyXmlData::Importer.new
    importer.auto_mapping_ids = params[:auto_mappings] if params[:auto_mappings].present?
    importer.notifications    = params[:notifications] == '1' if params[:notifications].present?
    if params[:map].present?
      params[:map].each do |entity_type, map|
        importer.add_map(map, entity_type)
      end
    else
      @mapping_data = importer.manual_mapping_data
    end

    if @mapping_data.present?
      render action: entity_mapping
    else
      importer.auto_mapping
      validation_errors = Array(importer.import.validation_errors)
      if validation_errors.any?
        flash[:error] = validation_errors.join("<br>").truncate(600).html_safe
      else
        project_importable = importer.importable_by_id('project')
        imported_projects  = project_importable.processed_entities if project_importable
        if imported_projects && imported_projects.any?
          lines     = []
          max_lines = 10
          imported_projects.each_value do |project|
            entity_type = project.easy_is_easy_template ? l(:label_template) : l(:label_project)
            link        = view_context.link_to(project.name, project, target: '_blank')
            lines << "#{entity_type} #{link} #{l(:xml_data_text_successfully_imported)}"
            break if lines.size == max_lines
          end
          lines << l(:xml_data_text_and_count_more, count: imported_projects.size - max_lines) if imported_projects.size > max_lines
          message = lines.join('<br />').html_safe
        else
          message = l(:label_import_success)
        end
        flash[:notice] = message
      end
      redirect_back_or_default(easy_xml_data_import_settings_path)
    end
  end

  def file_preview
    unless archive_file = params[:archivefile].try(:tempfile)
      flash[:error] = l(:label_import_zip_error)
      redirect_to action: 'import_settings'
      return false
    end

    importer   = EasyXmlData::Importer.new_with_archived_file(archive_file)
    @meta_data = importer.meta_data
    @mappables = mappables_per_entity_type(@meta_data[:entity_type])
    case @meta_data[:entity_type]
    when nil
      flash[:error] = l(:label_import_zip_error)
      redirect_to action: 'import_settings'
      return false
    when 'EasyPage'
      @submit_url = easy_xml_easy_pages_import_path
    when 'EasyPageTemplate'
      @submit_url = easy_xml_easy_page_templates_import_path
    else
      @submit_url = easy_xml_data_import_path
    end

    respond_to do |format|
      format.html
    end
  end

  private

  def check_exporter
    render_404 unless defined? EasyXmlData::Exporter
  end

  def entity_mapping
    'entity_mapping'
  end

  def create_exporter
    params[:projects]    ||= []
    params[:exportables] ||= []

    exportables = EasyXmlData::Exporter.exportables.select { |exportable| params[:exportables].include?(exportable.to_s) }

    @exporter = EasyXmlData::Exporter.new(exportables, params[:projects])
  end

  def get_filename
    if params[:projects] && params[:projects].size == 1
      project_name = Project.where(id: params[:projects]).pluck(:name).first
      filename     = "#{project_name}_#{Time.now}.zip" if project_name
    end
    filename || "export_#{Time.now}.zip"
  end

  def mappables_per_entity_type(entity_type = 'Project')
    case entity_type
    when 'Project', 'ProjectTemplate'
      %w(user group role tracker issue_priority issue_status project_custom_field easy_project_template_custom_field issue_custom_field document_category time_entry_activity)
    else
      []
    end

  end

end

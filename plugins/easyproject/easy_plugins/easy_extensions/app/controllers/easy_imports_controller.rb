class EasyImportsController < ApplicationController

  before_action :require_admin

  def import
    if params[:file]
      case params[:source]
      when 'excel'
        import_from_excel
      when 'jira'
        import_from_jira
      when 'ms_project'
        import_from_ms_project
      when 'asana'
        import_from_asana
      else
        render_flash_error(I18n.t('easy_imports.no_file_uploaded'))
        redirect_back_or_default home_url
      end
    else
      flash[:error] = I18n.t('easy_imports.no_file_uploaded')
      redirect_back_or_default home_url
    end
  end

  def index
    respond_to do |format|
      format.js
      format.html
    end
  end

  def download_sample_file
    file_name   = sanitize_file_name(params[:file_name])
    name_tokens = file_name.split('.')

    if name_tokens.size == 2
      file_name = "#{name_tokens[0]}_#{I18n.locale}.#{name_tokens[1]}"

      unless File.exist?(File.join(Rails.root, "plugins/easyproject/easy_plugins/easy_extensions/assets/easy_imports/#{file_name}"))
        file_name = "#{name_tokens[0]}_en.#{name_tokens[1]}"
      end
    end

    path = (File.join(Rails.root, "plugins/easyproject/easy_plugins/easy_extensions/assets/easy_imports/#{file_name}"))
    send_file(path,
              filename: file_name,
              type:     file_name.match(/\.(.*$)/).try(:[], 1))
  end

  def help
    render_help_for(params[:help])
  end

  private

  def import_from_excel
    @importer  = EasyEntityImports::XlsxSimpleImporter.new
    excel_file = params[:file].tempfile.path if params[:file].presence.try(:tempfile)

    case params[:tab]
    when 'projects_and_tasks'
      if @importer.import(excel_file)
        flash.now[:notice] = I18n.t(:label_import_success)
        @help_page         = :excel
        render template: 'easy_imports/reports/report'
      else
        render_flash_error
        render_help_for(:excel)
      end
    end
  end

  def import_from_jira
    @importer = EasyEntityImports::EasyJiraXmlImporter.new
    jira_file = params[:file].tempfile

    case params[:tab]
    when 'projects_and_tasks'
      types_to_import = [:issue_statuses, :issue_priorities, :trackers, :projects, :issues]
    end

    @importer.types_to_import = types_to_import
    if @importer.import(jira_file)
      flash.now[:notice] = I18n.t(:label_import_success)
      render template: 'easy_imports/reports/report'
    else
      render_flash_error
      render_help_for(:jira)
    end
  end

  def import_from_ms_project
    @importer       = EasyEntityImports::EasyMsProjectImporter.new
    ms_project_file = params[:file].tempfile
    if @importer.import(ms_project_file)
      flash.now[:notice] = I18n.t(:label_import_success)
      render template: 'easy_imports/reports/report'
    else
      render_flash_error
      render_help_for(:ms_project)
    end
  end

  def import_from_asana
    @importer  = EasyEntityImports::EasyAsanaCsvImport.new
    asana_file = params[:file].tempfile
    if @importer.import(asana_file)
      flash.now[:notice] = I18n.t(:label_import_success)
      render template: 'easy_imports/reports/report'
    else
      render_flash_error
      render_help_for(:asana)
    end
  end

  def sanitize_file_name(file_name)
    file_name.gsub(/[^0-9A-Za-z_.]/, '')
  end

  def render_flash_error(message = nil)
    flash.now[:error] = message || (@importer && @importer.log[:fatal_error]) || I18n.t(:xml_data_file_could_not_be_processed)
  end

  def render_help_for(help)
    template_name = File.basename(help.to_s)
    render template: "easy_imports/help/#{template_name}"
  end

end

class EasyDataTemplatesImportController < ApplicationController
  layout 'admin'

  before_action :find_data_template, :only => [:edit, :update, :import_settings, :import]
  before_action :prepare_datarows, :only => [:import_settings, :import]

  helper :attachments
  include AttachmentsHelper
  helper :easy_data_templates
  include EasyDataTemplatesHelper

  def new
    @datatemplate = EasyDataTemplate.new
    @datatemplate.safe_attributes = params[:easy_data_template]

    respond_to do |format|
      format.html
    end
  end

  def edit
    respond_to do |format|
      format.html
    end
  end

  def create
    type = params[:easy_data_template][:type] if params[:easy_data_template]
    unless type.blank?
      @datatemplate = type.constantize.new(params[:easy_data_template])
    end

    if @datatemplate && @datatemplate.save
      Attachment.attach_files(@datatemplate, params[:attachments])
      @datatemplate.reload
    end

    respond_to do |format|
      if @datatemplate && @datatemplate.valid? && @datatemplate.attachments.size == 1
        flash[:notice] = l(:notice_successful_create)
        format.html { redirect_back_or_default({:controller => 'easy_data_templates_import', :action => 'import_settings', :id => @datatemplate}) }
      else
        flash[:error] = l(:error_easy_data_template_attachment_not_uploaded)
        format.html { render :action => 'new' }
      end
    end
  end

  def update
    respond_to do |format|
      if @datatemplate.update_attributes(params[:easy_data_template])
        flash[:notice] = l(:notice_successful_update)
        format.html { redirect_back_or_default({:controller => 'easy_data_templates', :action => 'index'}) }
      else
        format.html { render :action => 'edit' }
      end
    end
  end

  def import_settings
    @datatemplate.save if params[:easy_data_template]

    if request.xhr?
      render :partial => 'easy_data_templates_import/preview', :locals => {:datatemplate => @datatemplate, :datarows => @datarows, :target_project => @target_project}
    else
      render :template => 'easy_data_templates_import/import_settings'
    end
  end

  def import
    @datatemplate.save if params[:easy_data_template]

    TimeEntry.transaction do
      @datarows.each do |row_values, entity|
        entity.save!
      end
    end

    redirect_back_or_default({:controller => 'easy_data_templates', :action => 'index'})
  end

  private

  def find_data_template
    @datatemplate = EasyDataTemplate.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    render_404
  end

  def prepare_datarows
    @datatemplate.attributes = params[:easy_data_template] if params[:easy_data_template]
    @datatemplate.settings['selected_columns'].reject!{|s| s.blank?}
    @target_project = Project.find(@datatemplate.settings['target_project_id'])
    @datarows = []

    fcsv_options = {:headers => true}
    fcsv_options[:encoding] = 'n'
    fcsv_options[:return_headers] = false
    fcsv_options[:col_sep] = (@datatemplate.settings['col_sep'] == "\\t" ? "\t" : @datatemplate.settings['col_sep']) || ';'
    fcsv_options[:quote_char] = @datatemplate.settings['quote_char'] || '"'

    ic = Iconv.new('UTF-8', l(:general_csv_encoding))

    at = @datatemplate.attachments.first
    idx = 0
    CSV.foreach(at.diskfile, fcsv_options){|csv_row|
      row_values = ::ActiveSupport::OrderedHash.new
      @datatemplate.settings['selected_columns'].each do |sc|
        founded_value, import_data_value, original_value = nil, nil, []
        if params[:import_data] && params[:import_data][idx.to_s]
          import_data_value = params[:import_data][idx.to_s][sc]
        end
        if row_values['project'] && row_values['project'][:founded_value].is_a?(Project)
          target_project = row_values['project'][:founded_value]
        else
          target_project = @target_project
        end
        case sc
        when 'activity'
          if import_data_value
            founded_value = TimeEntryActivity.where(:id => import_data_value).first unless founded_value
          end
          if !csv_row['activity_id'].blank?
            original_value << ['activity_id', csv_row['activity_id']]
            founded_value = TimeEntryActivity.where(:id => csv_row['activity_id']).first unless founded_value
          end
        when 'issue'
          if import_data_value
            founded_value = target_project.issues.where(:id => import_data_value).first unless founded_value
          end
          if !csv_row['issue_id'].blank?
            original_value << ['issue_id', csv_row['issue_id']]
            founded_value = target_project.issues.where(:id => csv_row['issue_id']).first unless founded_value
          end
          if !csv_row['issue_subject'].blank?
            v = begin; ic.iconv(csv_row['issue_subject'].to_s); rescue; c.to_s; end
            original_value << ['issue_subject', v]
            founded_value = target_project.issues.where(:subject => v).first unless founded_value
          end
        when 'project'
          if import_data_value
            founded_value = Project.where(:id => import_data_value).first unless founded_value
          end
          if !csv_row['project_id'].blank?
            original_value << ['project_id', csv_row['project_id']]
            founded_value = @target_project.self_and_descendants.where(:id => csv_row['project_id']).first unless founded_value
          end
          if !csv_row['project_name'].blank?
            v = begin; ic.iconv(csv_row['project_name'].to_s); rescue; c.to_s; end
            original_value << ['project_name', v]
            founded_value = @target_project.self_and_descendants.where(:name => v).first unless founded_value
          end
        when 'user'
          if import_data_value
            founded_value = User.where(:id => import_data_value).first unless founded_value
          end
          if !csv_row['user_id'].blank?
            original_value << ['user_id', csv_row['user_id']]
            founded_value = User.where(:id => csv_row['user_id']).first unless founded_value
          end
        end
        founded_value ||= (begin; ic.iconv(csv_row[sc].to_s); rescue; c.to_s; end) if csv_row[sc]
        row_values[sc] = {:founded_value => founded_value, :original_value => original_value}
      end
      @datarows << [row_values, @datatemplate.build_entity_from_csv_row(row_values)]
      idx += 1
    }
  end

end

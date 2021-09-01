require_dependency 'data_template_entity_row_factory'

class EasyDataTemplatesController < ApplicationController
  layout 'admin'

  before_action :require_admin
  before_action :prepare_variables, :only => [:import, :import_data, :export, :export_data]
  before_action :prepare_variables_for_export, :only => [:export, :export_data]
  before_action :prepare_variables_for_import, :only => [:import, :import_data]

  helper :attachments
  include AttachmentsHelper
  helper :easy_data_templates
  include EasyDataTemplatesHelper

  # GET /easy_data_templates
  # GET /easy_data_templates.xml
  def index
    @datatemplates = EasyDataTemplate.where(["user_id = ? OR user_id IS NULL", User.current.id]).order(:name)

    respond_to do |format|
      format.html # index.html.erb
    end
  end

  # GET /easy_data_templates/new
  # GET /easy_data_templates/new.xml
  def new
    @datatemplate = EasyDataTemplate.new
    @datatemplate.safe_attributes = params[:easy_data_template]

    respond_to do |format|
      format.html # new.html.erb
    end
  end

  # GET /easy_data_templates/1/edit
  def edit
    @datatemplate = EasyDataTemplate.find(params[:id])

    respond_to do |format|
      format.html # new.html.erb
    end
  end

  # POST /easy_data_templates
  # POST /easy_data_templates.xml
  def create
    @datatemplate = EasyDataTemplate.new
    @datatemplate.safe_attributes = params[:easy_data_template]
    @datatemplate.settings = {'return_headers'=>"1",'col_sep'=>",",'quote_char'=>"\"",'import_all'=>"1",'preview_rows'=>"5",'encoding'=>"WINDOWS-1250"}

    respond_to do |format|
      if @datatemplate.save

        flash[:notice] = l(:notice_successful_create)
        format.html { redirect_to({:controller => 'easy_data_templates', :action => 'index'}) }
      else
        format.html { render :controller => 'easy_data_templates', :action => "new" }
      end
    end
  end

  # PUT /easy_data_templates/1
  # PUT /easy_data_templates/1.xml
  def update
    @datatemplate = EasyDataTemplate.find(params[:id])

    respond_to do |format|
      if @datatemplate.update_attributes(params[:easy_data_template])
        flash[:notice] = l(:notice_successful_update)
        format.html { redirect_to({:controller => 'easy_data_templates', :action => 'index'}) }
      else
        format.html { render :controller => 'easy_data_templates', :action => "edit" }
      end
    end
  end

  # PUT /easy_data_templates/1
  # PUT /easy_data_templates/1.xml
  def update_settings
    @datatemplate = EasyDataTemplate.find(params[:id])

    respond_to do |format|
      if @datatemplate.update_attributes(params[:easy_data_template])
        flash[:notice] = l(:notice_successful_update)
        format.html { redirect_to({:controller => 'easy_data_templates', :action => @datatemplate.template_type, :id => @datatemplate.id, :show_settings => params[:show_settings]}) }
      else
        format.html { render :controller => 'easy_data_templates', :action => @datatemplate.template_type }
      end
    end
  end

  # DELETE /easy_data_templates/1
  # DELETE /easy_data_templates/1.xml
  def destroy
    @datatemplate = EasyDataTemplate.find(params[:id])
    @datatemplate.destroy

    respond_to do |format|
      format.html { redirect_to({:controller => 'easy_data_templates', :action => 'index'}) }
    end
  end

  # POST /easy_data_templates/import/1
  # POST /easy_data_templates/import/1.xml
  def import
    unless @datatemplate.attachments[0].nil?
      CSV.foreach(@datatemplate.attachments[0].diskfile, @fcsv_options){|x| @csv_data << x.collect{|y| y[1]}}
      @csv_data.each do |row|
        @data_manager.prepare_row_for_import(row)
        @my_errors[:index] += 1
        @my_errors[:rows] += [@my_errors[:index]] unless @data_manager.valid?
        @my_errors[:size] += @data_manager.errors.size
        row << @data_manager.entity
      end
    end

    respond_to do |format|
      format.html { render :template => "easy_data_templates/import" }
    end
  end


  # POST /easy_data_templates/import/1
  # POST /easy_data_templates/import/1.xml
  def import_data
    CSV.foreach(@datatemplate.attachments[0].diskfile, @fcsv_options) do |row|
      @data_manager.prepare_row_for_import(row)
      if @data_manager.save
        Mailer.account_information(@data_manager.entity, params[:password]).deliver if @data_manager.entity.class.name == 'User' && !@datatemplate.assignments.select{|s| s.entity_attribute_name=="send_mail"}.blank? && row[(@datatemplate.assignments.select{|s| s.entity_attribute_name=="send_mail"}.first.file_column_position.to_i-1)].to_s.casecmp("A").zero?
      end
    end

    @datatemplate.attachments[0].destroy

    respond_to do |format|
      format.html { redirect_to({:controller => 'easy_data_templates', :action => 'import', :id => @datatemplate.id}) }
    end
  end

  # POST /easy_data_templates/export/1
  # POST /easy_data_templates/export/1.xml
  def export
    unless @datatemplate.assignments.blank?
      case @datatemplate.entity_type
      when 'Project'
        Project.non_templates.sorted.active.visible.limit(@datatemplate.settings['preview_rows']).each do |project|
          @csv_data << @data_manager.prepare_row_for_export(project)
        end
      when 'Issue'
        Issue.visible.limit(@datatemplate.settings['preview_rows']).each do |issue|
          @csv_data << @data_manager.prepare_row_for_export(issue)
        end
      when 'User'
        User.active.limit(@datatemplate.settings['preview_rows']).each do |user|
          @csv_data << @data_manager.prepare_row_for_export(user)
        end
      end
    end

    respond_to do |format|
      format.html { render :template => "easy_data_templates/export" }
    end
  end

  # POST /easy_data_templates/export/1
  # POST /easy_data_templates/export/1.xml
  def export_data
    case @datatemplate.entity_type
    when 'Project'
      Project.non_templates.sorted.active.visible.each do |project|
        @csv_data << @data_manager.prepare_row_for_export(project)
      end
    when 'Issue'
      Issue.visible.each do |issue|
        @csv_data << @data_manager.prepare_row_for_export(issue)
      end
    when 'User'
      User.active.each do |user|
        @csv_data << @data_manager.prepare_row_for_export(user)
      end
    end

    respond_to do |format|
      format.html { render :template => "easy_data_templates/export" }
      format.csv  { send_data(csv_data_to_csv(@datatemplate,@csv_data), :filename => "#{@datatemplate.entity_type}.csv") }
    end
  end

  private

  def prepare_variables
    @datatemplate = EasyDataTemplate.find(params[:id])
    @datatemplatesassignment = @datatemplate.assignments.new
    @datatemplatesassignment.entity_attribute_name = params[:entity_attribute_name]
    @data_manager = DataTemplateEntityRowFactory.create(@datatemplate)
    @csv_data = []
    @show_settings = params[:show_settings]
    @show_assignment = params[:show_assignment]
    @show_settings ||= '0'
    @show_assignment ||= '0'
  end

  def prepare_variables_for_import
    @fcsv_options = {:headers => true}
    @fcsv_options[:encoding] = "n"
    @fcsv_options[:return_headers] = @datatemplate.settings['return_headers'] == "1" ? false : true
    @fcsv_options[:col_sep] = @datatemplate.settings['col_sep'] == "\\t" ? "\t" : @datatemplate.settings['col_sep']
    @fcsv_options[:quote_char] = @datatemplate.settings['quote_char'] unless @datatemplate.settings['quote_char'] == ""
    unless params['attachments'].blank? || params['attachments']['0']['file'].blank?
      @datatemplate.attachments.destroy_all
      Attachment.attach_files(@datatemplate, params[:attachments])
      @datatemplate = EasyDataTemplate.find(params[:id])
    end
    @my_errors = {:index => 0, :size => 0, :rows=> []}
  end

  def prepare_variables_for_export
    []
  end

  def csv_data_to_csv(datatemplate,data_source)
    return if data_source.blank?

    ic = Iconv.new(datatemplate.settings['encoding'],l('eady_data_template_encoding'))
    export = FasterCSV.generate(:col_sep => @datatemplate.settings['col_sep'], :quote_char => @datatemplate.settings['quote_char']) do |csv|
      if datatemplate.settings['return_headers'] == '1'
        headers = []
        datatemplate.assignments.each do |assignment|
          unless datatemplate.allowed_attributes.select{|attribute| attribute == assignment.entity_attribute_name}.blank?
            headers[(assignment.file_column_position-1)] = l('easy_data_template_entity_attributes_select.'+datatemplate.entity_type.to_s+'.'+assignment.entity_attribute_name.to_s)
          else
            case datatemplate.entity_type
            when 'Project'
              headers[(assignment.file_column_position-1)] = ProjectCustomField.find(assignment.entity_attribute_name.to_i).name.to_s
            when 'Issue'
              headers[(assignment.file_column_position-1)] = IssueCustomField.find(assignment.entity_attribute_name.to_i).name.to_s
            when 'User'
              headers[(assignment.file_column_position-1)] = UserCustomField.find(assignment.entity_attribute_name.to_i).name.to_s
            end
          end
        end
        csv << headers.collect {|c| begin; ic.iconv(c.to_s); rescue; c.to_s; end }
      end

      data_source.each do |data_row|
        fields = []

        data_row.each do |field|
          fields << field.to_s
        end

        csv << fields.collect {|c| begin; ic.iconv(c.to_s); rescue; c.to_s; end }
      end
    end
    export
  end

end

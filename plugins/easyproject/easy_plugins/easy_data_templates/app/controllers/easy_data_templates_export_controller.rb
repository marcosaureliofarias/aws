class EasyDataTemplatesExportController < ApplicationController
  layout 'admin'

  before_action :find_data_template, :only => [:edit, :update, :export_settings, :export]

  helper :attachments
  include AttachmentsHelper
  helper :easy_data_templates
  include EasyDataTemplatesHelper

  def new
    @datatemplate = EasyDataTemplate.new

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

    respond_to do |format|
      if @datatemplate.save
        flash[:notice] = l(:notice_successful_create)
        format.html { redirect_back_or_default({:controller => 'easy_data_templates_export', :action => 'export_settings', :id => @datatemplate}) }
      else
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

  def export_settings
    @datatemplate.attributes = params[:easy_data_template] if params[:easy_data_template]
    @datatemplate.settings['selected_columns'].reject!{|s| s.blank?}
    @datatemplate.save if params[:easy_data_template]
    @datarows = []

    prepare_datarows(5)

    if request.xhr?
      render :partial => 'easy_data_templates_export/preview', :locals => {:datatemplate => @datatemplate, :datarows => @datarows}
    else
      render :template => 'easy_data_templates_export/export_settings'
    end
  end

  def export
    @datatemplate.attributes = params[:easy_data_template] if params[:easy_data_template]
    @datatemplate.settings['selected_columns'].reject!{|s| s.blank?}
    @datatemplate.save if params[:easy_data_template]
    @datarows = []

    prepare_datarows

    respond_to do |format|
      format.html { send_data(data_to_csv, :filename => "#{@datatemplate.name}.csv") }
    end
  end

  private

  def find_data_template
    @datatemplate = EasyDataTemplate.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    render_404
  end

  def prepare_datarows(limit = nil)
    entities = @datatemplate.find_entities(limit)

    entities.each do |te|
      row = []
      @datatemplate.settings['selected_columns'].each do |sc|
        row << @datatemplate.all_allowed_columns[sc].value(te)
      end
      @datarows << row
    end if entities
  end

  def data_to_csv
    ic = Iconv.new(l(:general_csv_encoding), 'UTF-8')
    export = Redmine::Export::CSV.generate do |csv|
      csv << @datatemplate.settings['selected_columns']
      @datarows.each do |row|
        csv << row.collect{|c| begin; ic.iconv(c.to_s); rescue; c.to_s; end }
      end
    end
    export
  end

end

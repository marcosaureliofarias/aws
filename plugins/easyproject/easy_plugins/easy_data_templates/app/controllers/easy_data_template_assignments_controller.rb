class EasyDataTemplateAssignmentsController < ApplicationController
  layout 'admin'

  before_action :require_admin

  before_action :find_easy_data_template

  helper :attachments
  include AttachmentsHelper

  # POST /easy_data_templates_assignmets
  # POST /easy_data_templates_assignmets.xml
  def create
    @datatemplatesassignment = EasyDataTemplateAssignment.new(params[:easy_data_template_assignment])
    @datatemplatesassignment.easy_data_template_id = params[:easy_data_template_id]
    @datatemplatesassignments = @datatemplate.assignments

    respond_to do |format|
      if @datatemplatesassignment.save
        flash[:notice] = l(:notice_successful_create)
        format.html {  redirect_to({:controller => 'easy_data_templates', :action => @datatemplate.template_type, :id => @datatemplate.id, :show_assignment => params[:show_assignment] }) }
      else
        format.html {  redirect_to({:controller => 'easy_data_templates', :action => @datatemplate.template_type, :id => @datatemplate.id, :show_assignment => params[:show_assignment], :entity_attribute_name => @datatemplatesassignment.entity_attribute_name }) }
      end
    end
  end

  # POST /easy_data_templates_assignmets/1
  # POST /easy_data_templates_assignmets/1.xml
  def update

    params[:easy_data_template_assignments].each do |k, v|
      assignment = EasyDataTemplateAssignment.find(k)
      assignment.update_attributes(v)
    end
    
    @datatemplatesassignment = EasyDataTemplateAssignment.new
    @datatemplatesassignments = @datatemplate.assignments

    respond_to do |format|
      flash[:notice] = l(:notice_successful_update)
      format.html {  redirect_to({:controller => 'easy_data_templates', :action => @datatemplate.template_type, :id => @datatemplate.id, :show_assignment => params[:show_assignment] }) }
    end
  end

  # DELETE /easy_data_templates/1
  # DELETE /easy_data_templates/1.xml
  def destroy
    @datatemplatesassignment = EasyDataTemplateAssignment.find(params[:id])
    @datatemplatesassignment.destroy
    @datatemplatesassignments = @datatemplate.assignments

    respond_to do |format|
      format.html {  redirect_to({:controller => 'easy_data_templates', :action => @datatemplate.template_type, :id => @datatemplate.id, :show_assignment => params[:show_assignment]}) }
    end
  end

  private

  def find_easy_data_template
    @datatemplate = EasyDataTemplate.find(params[:easy_data_template_id])
  rescue ActiveRecord::RecordNotFound
    render_404
  end

end
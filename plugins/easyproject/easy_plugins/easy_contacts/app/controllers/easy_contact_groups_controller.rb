class EasyContactGroupsController < ApplicationController

  menu_item :project_easy_contacts
  menu_item :easy_contacts

  default_search_scope :easy_contacts

  before_action :authorize_global

  before_action :find_group, :only => [:show, :edit, :update, :destroy, :add_note, :assign_contact, :toggle_author_note]
  before_action :find_contact, :only => [:assign_contact]
  before_action :find_project
  before_action :find_journals, :only => [:show]

  helper :custom_fields
  include CustomFieldsHelper
  helper :easy_contact_groups
  include EasyContactGroupsHelper
  helper :easy_contacts
  include EasyContactsHelper
  helper :sort
  include SortHelper
  helper :easy_query
  include EasyQueryHelper

  # GET /easy_contact_groups
  def index
    retrieve_query(EasyContactGroupQuery)

    sort_init(@query.sort_criteria_init)
    sort_update({'lft' => "#{EasyContactGroup.table_name}.lft"}.merge(@query.sortable_columns))

    if @project
      @query.project = @project
      @query.available_filters.delete_if {|k,v| k == 'project_groups'}
      @query.add_additional_statement("(entity_id = #{@project.id} AND entity_type = 'Project')")
    else
      @query.add_additional_statement("((entity_id = #{User.current.id} AND entity_type = 'Principal') OR ( entity_id IS NULL))")
    end

    @easy_contact_groups = prepare_easy_query_render

    if request.xhr? && !@entities
      render_404
      return false
    end

    respond_to do |format|
      format.html { render_easy_query_html }
      format.csv  { send_data(export_to_csv(@easy_contact_groups, @query), :filename => get_export_filename(:csv, @query)) }
      format.pdf  { send_file_headers! :type => 'application/pdf', :filename => get_export_filename(:pdf, @query) }
      format.xlsx { send_data(export_to_xlsx(@easy_contact_groups, @query), :filename => get_export_filename(:xlsx, @query)) }
    end
  end

  # GET /easy_contact_groups/:id
  # GET /easy_contact_groups/:id/show
  def show
    render_403 unless User.current.admin? || @easy_contact_group.entity_id.nil? || @easy_contact_group.entity_id == User.current.id || User.current.project_ids.include?(@easy_contact_group.entity_id)
  end

  # GET /easy_contact_groups/new
  def new
    @easy_contact_group = EasyContactGroup.new
    @available_groups = available_groups
  end

  # GET /easy_contact_groups/:id/edit
  def edit
    @available_groups = available_groups
  end

  def available_groups
    ag = Array.new

    if @project.nil?
      if  g = EasyContactGroup.global_groups
        ag << [l('filter.global_groups'), g.collect{|i| [i.group_name, i.id]}] unless g.blank?
      end
      if  u = User.current.easy_contact_groups
        ag << [l('filter.personal_groups'), u.collect{|i| [i.group_name, i.id]}] unless u.blank?
      end
    else
      if @project && p = @project.easy_contact_groups
        ag << [l('filter.project_groups'), p.collect{|i| [i.group_name, i.id]}] unless p.blank?
      end
    end

    return ag
  end

  # POST /easy_contact_groups
  def create
    @easy_contact_group = EasyContactGroup.new
    @easy_contact_group.add_non_primary_custom_fields(params[:easy_contact_group][:custom_field_values]) unless params[:easy_contact_group][:custom_field_values].blank?
    @easy_contact_group.safe_attributes = params[:easy_contact_group]

    if params[:easy_contact_group]['parent_id'] && params[:easy_contact_group]['parent_id'].present?
      parent = EasyContactGroup.find(params[:easy_contact_group]['parent_id'])
      @easy_contact_group.entity = parent.entity
    end
    set_contact_group_entity

    respond_to do |format|
      if @easy_contact_group.save
        @easy_contact_group.set_allowed_parent!(params[:easy_contact_group]['parent_id']) if params[:easy_contact_group].has_key?('parent_id') && !params[:easy_contact_group]['parent_id'].blank?
        #attach_files(@contact, params[:attachments])
        format.html { redirect_to( :action => 'index', :project_id => @project ) }
      else
        format.html { render :action => "new", :project_id => @project }
      end
    end
  end

  # PUT /easy_contact_groups/:id
  def update
    set_contact_group_entity
    @easy_contact_group.add_non_primary_custom_fields(params[:easy_contact_group][:custom_field_values]) unless params[:easy_contact_group][:custom_field_values].blank?
    @easy_contact_group.init_journal(User.current, params[:easy_contact_group][:notes])
    @easy_contact_group.safe_attributes = params[:easy_contact_group]
    if @easy_contact_group.save
      @easy_contact_group.set_allowed_parent!(params[:easy_contact_group]['parent_id']) if params[:easy_contact_group].has_key?('parent_id') && !params[:easy_contact_group]['parent_id'].blank?
      redirect_to( :action => 'index', :project_id => @project )
    else
      render :action => "edit", :project_id => @project
    end

  end

  # DELETE /easy_contact_groups/:id
  def destroy
    @easy_contact_group.destroy

    respond_to do |format|
      format.html {
        flash[:notice] = l(:notice_successful_delete)
        redirect_back_or_default :action => 'index', :project_id => @project
      }
    end
  end

  def toggle_author_note
    respond_to do |format|
      format.js
    end
  end

  def destroy_items
    unless params[:ids].blank?
      EasyContactGroup.where(:id => params[:ids]).destroy_all
      redirect_back_or_default :action => :index, :project_id => @project
    else
      flash[:error] = l(:error_no_contacts_select)
      redirect_back_or_default :action => :index, :project_id => @project
    end
  end

  def add_custom_field
    @custom_field = EasyContactGroupCustomField.find(params[:custom_field_id])
    @custom_value = CustomValue.new :customized_type => 'EasyContactGroup', :custom_field_id => @custom_field.id, :custom_field => @custom_field
  end

  def remove_custom_field
    custom_field_id, entity_id, entity_type = params[:custom_field_id], params[:entity_id], params[:entity_type]
    unless entity_id.blank? || entity_type.blank? || custom_field_id.blank?
      @entity = entity_type.constantize.find(entity_id)
      @entity.custom_values.each do |custom_value|
        custom_value.destroy if custom_value.custom_field_id == custom_field_id.to_i
      end
    end
  end

  def assign_contact
    if !@easy_contact_group.easy_contacts.include?(@easy_contact)
      @easy_contact_group.easy_contacts << @easy_contact
      render_api_ok
    else
      render_error status: 422, message: l(:error_contact_already_assigned)
    end
  end

  private

  def find_group
    @easy_contact_group = EasyContactGroup.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    render_404
  end

  def find_project
    @project = Project.find(params[:project_id]) unless params[:project_id].blank?
  end

  def find_journals
    @journals = @easy_contact_group.journals.preload(:journalized, :user, :details).reorder("#{Journal.table_name}.id ASC").to_a
    @journals.each_with_index {|j,i| j.indice = i+1}
    Journal.preload_journals_details_custom_fields(@journals)
    @journals.reverse! if User.current.wants_comments_in_reverse_order?
  end

  def find_contact
    @easy_contact = EasyContact.find(params[:easy_contact_id])
  rescue ActiveRecord::RecordNotFound
    render_404
  end

  def set_contact_group_entity
    if params[:is_global]
      @easy_contact_group.entity = nil
    elsif @project
      @easy_contact_group.entity = @project
    else
      @easy_contact_group.entity = User.current
    end
  end

end

class EasyCrmCasesController < ApplicationController

  ADVANCED_LIST_FORMAT_CUSTOM_FIELDS = ['easy_lookup', 'text']

  menu_item :easy_crm
  default_search_scope :easy_crm_cases

  before_action :find_easy_crm_case, only: [:show, :edit, :update, :toggle_description, :remove_related_invoice, :render_tab, :description_edit]
  before_action :find_easy_crm_cases, only: [:context_menu, :bulk_edit, :bulk_update, :destroy, :merge_edit, :merge_update]
  before_action :find_project
  before_action :authorize_global, except: [:render_assignments_form_on_issue]
  before_action :build_easy_crm_case, only: [:new, :create]
  before_action :mark_as_read, only: [:show]
  before_action :find_target_crm_case, only: [:merge_edit, :merge_update]

  accept_api_auth :index, :show, :create, :update, :destroy

  helper :issues
  helper :easy_bulk_edit
  helper :issues
  helper :easy_crm
  include EasyCrmHelper
  helper :easy_query
  include EasyQueryHelper
  helper :attachments
  include AttachmentsHelper
  helper :sort
  include SortHelper
  helper :custom_fields
  include CustomFieldsHelper
  helper :journals
  include JournalsHelper
  helper :easy_journal
  include EasyJournalHelper
  helper :easy_contacts
  include EasyContactsHelper
  helper :context_menus
  include ContextMenusHelper
  helper :timelog
  include TimelogHelper
  helper :watchers
  include WatchersHelper

  def index
    if api_request?
      params['column_names'] = ['project']
      preload = [{custom_values: :custom_field}, :easy_crm_case_items, :easy_crm_case_status, :assigned_to, :external_assigned_to, :author]
      before_render = proc { EasyCrmCase.load_available_custom_fields(@entities) }
    end

    index_for_easy_query EasyCrmCaseQuery, [['contract_date', 'desc']],
                         preload: preload,
                         before_render: before_render
  end

  def show
    @journal_limit = EasySetting.value('easy_extensions_journal_history_limit')
    reversed_comments = User.current.wants_comments_in_reverse_order?

    @journals = @easy_crm_case.journals.where(:easy_type => nil).
      preload([{:user => (Setting.gravatar_enabled? ? :email_address : :easy_avatar)}, :details]).order(created_on: :desc)
    # not needed
    # @journal_count = @easy_crm_case.journals.count
    # i = reversed_comments ? @journal_count + 1 : 0
    # @journals.each { |j| j.indice = i+=(reversed_comments ? -1 : 1) }
    @journals = @journals.where(private_notes: false) unless User.current.allowed_to?(:view_private_notes, @easy_crm_case.project)
    @journals = @journals.to_a
    Journal.preload_journals_details_custom_fields(@journals)
    @journals.select! { |journal| journal.notes? || journal.visible_details.any? }
    @journal_count = @journals.size

    @journal_limit = @journal_count if api_request? && params[:journals] == 'all'

    comments_count = 0
    @journals.select!{ |journal| res = comments_count < @journal_limit; comments_count += 1 if journal.notes?; res }

    @journals.reverse! if !reversed_comments

    respond_to do |format|
      format.html
      format.api {render :api => @easy_crm_case}
      format.qr {
        @easy_qr = EasyQr.generate_qr(easy_crm_case_url(@easy_crm_case))
        if request.xhr?
          render :template => 'easy_qr/show', :formats => [:js], :locals => { :modal => true }
        else
          render :template => 'easy_qr/show', :formats => [:html], :content_type => 'text/html'
        end
      }
    end
  end

  def new
    if params[:easy_invoice_id].present? && @project.module_enabled?(:easy_invoicing)
      @easy_crm_case.build_from_easy_invoice(EasyInvoice.where(id: params[:easy_invoice_id]).first)
    end
    @easy_crm_case.easy_crm_case_items.build if @easy_crm_case.easy_crm_case_items.empty?
    respond_to do |format|
      format.html { render layout: !request.xhr? }
      format.js
    end
  end

  def create
    @easy_crm_case.save_attachments(params[:attachments] || (params[:easy_crm_case] && params[:easy_crm_case][:uploads]))
    if @easy_crm_case.project
      @easy_crm_case.easy_invoice_ids |= [params[:easy_invoice_id].to_i] if params[:easy_invoice_id].present? && @project.module_enabled?(:easy_invoicing)
    end

    if @easy_crm_case.save
      if params[:easy_contact_id].blank? && (easy_contact = EasyContact.where(:id => params[:easy_contact_id]).first)
        @easy_crm_case.easy_contacts << easy_contact unless @easy_crm_case.easy_contacts.include?(easy_contact)
      end
      mark_as_read
      easy_crm_after_save

      respond_to do |format|
        format.html {
          render_attachment_warning_if_needed(@easy_crm_case)
          flash[:notice] = l(:notice_successful_create)
          attrs = {:easy_crm_case_status_id => @easy_crm_case.easy_crm_case_status_id}.reject {|k,v| v.nil?}
          next_url = new_project_easy_crm_case_path(@project, :easy_crm_case => attrs)

          if params[:easy_crm_case] && params[:easy_crm_case][:send_to_external_mails] == '1'
            redirect_to preview_external_email_easy_crm_case_path(@easy_crm_case, :back_url => params[:continue] ? next_url : back_url)
          else
            if params[:continue]
              redirect_to next_url
            else
              redirect_back_or_default easy_crm_case_path(@easy_crm_case)
            end
          end
        }
        format.api  { render :action => 'show', :status => :created, :location => easy_crm_case_url(@easy_crm_case) }
      end
      return
    else
      respond_to do |format|
        format.html { render :action => 'new' }
        format.api  { render_validation_errors(@easy_crm_case) }
      end
    end
  end

  def edit
    return unless update_easy_crm_case_from_params
    @easy_crm_case.need_reaction = false

    respond_to do |format|
      format.html
      format.js
    end
  end

  def update
    return unless update_easy_crm_case_from_params

    @easy_crm_case.save_attachments(params[:attachments] || (params[:easy_crm_case] && params[:easy_crm_case][:uploads]))
    saved = false

    begin
      saved = save_easy_crm_case_with_child_records
    rescue ActiveRecord::StaleObjectError
      @conflict = true
      if params[:last_journal_id]
        @conflict_journals = @easy_crm_case.journals_after(params[:last_journal_id]).to_a
      else
        @conflict_journals = [@easy_crm_case.journals.last].compact
      end
      @conflict_journals.reject!(&:private_notes?) unless User.current.allowed_to?(:view_private_notes, @easy_crm_case.project)
    end

    if saved
      if !params[:easy_contact_id].blank? && (easy_contact = EasyContact.where(:id => params[:easy_contact_id]).first)
        @easy_crm_case.easy_contacts << easy_contact unless @easy_crm_case.easy_contacts.include?(easy_contact)
      end

      easy_crm_after_save

      render_attachment_warning_if_needed(@easy_crm_case)
      flash[:notice] = l(:notice_successful_update) unless @easy_crm_case.current_journal.new_record?
      send_notification_updated(@easy_crm_case)
      respond_to do |format|
        format.html do
          if params[:easy_crm_case] && params[:easy_crm_case][:send_to_external_mails] == '1'
            redirect_to preview_external_email_easy_crm_case_path(@easy_crm_case, :back_url => back_url)
          else
            redirect_back_or_default easy_crm_case_path(@easy_crm_case)
          end
        end
        format.api do
          response.headers['X-Easy-Lock-Version'] = @easy_crm_case.lock_version.to_s
          response.headers['X-Easy-Last-Journal-Id'] = @easy_crm_case.last_journal_id.to_s
          render_api_ok
        end
      end
    else
      respond_to do |format|
        format.html { render :action => 'edit' }
        format.api do
          if @conflict
            @easy_crm_case.errors.add :base, l(:notice_easy_crm_update_conflict)
          end
          if @conflict_journals.present?
            sanitizer = Rails::Html::FullSanitizer.new
            journal = @conflict_journals.sort_by(&:id).last
            msg = sanitizer.sanitize(l(:label_updated_datetime_by,
                author: journal.user,
                datetime: format_time(journal.created_on)
              ))
            @easy_crm_case.errors.add :base, msg
          end
          render_validation_errors(@easy_crm_case)
        end
      end
    end
  end

  def destroy
    p = @project || (@projects && @projects.first) || @easy_crm_cases.first.project

    @easy_crm_cases.each do |easy_crm_case|
      easy_crm_case.destroy
    end

    respond_to do |format|
      format.html {redirect_back_or_default project_easy_crm_cases_path(p)}
      format.api {render_api_ok}
    end
  end

  def merge_edit
    if !params[:ids].include?(params[:merge_to_id])
       @easy_crm_cases.unshift(@target_crm_case)
       prepare_merge_edit

       respond_to do |format|
         format.html
       end
    else
      flash[:error] = l(:notice_unsuccessful_merge)
      redirect_back_or_default easy_crm_case_path(@easy_crm_cases.first)
    end
  end

  def merge_update
    @easy_crm_cases -= [@target_crm_case]
    crms_in_note = @easy_crm_cases.collect { |crm| "easy_crm_case##{crm.id}" }.join(', ')
    @target_crm_case.init_journal(User.current, l(:label_merged_from, :ids => "#{crms_in_note}"))
    @target_crm_case.safe_attributes = params[:easy_crm_case] if !params[:quick_merge]
    @target_crm_case.created_at = params[:easy_crm_case][:created_at] if params[:easy_crm_case] && !params[:quick_merge]
    @save_and_merged = false
    EasyCrmCase.transaction do
      raise ActiveRecord::Rollback unless @target_crm_case.save
      raise ActiveRecord::Rollback unless EasyCrmCase.easy_merge_and_close_crms(@easy_crm_cases, @target_crm_case)
      @save_and_merged = true
    end

    respond_to do |format|
      if @save_and_merged
        flash[:notice] = l(:notice_successful_update)
        format.html {
          if params[:follow]
            redirect_to easy_crm_case_path(@target_crm_case)
          else
            redirect_back_or_default easy_crm_case_path(@target_crm_case)
          end
        }
        format.api {render_api_ok}
      else
        format.html do
          flash[:error] = l(:error_easy_crm_case_could_not_merge)
          @easy_crm_cases.unshift(EasyCrmCase.find_by(id: @target_crm_case.id)) if @target_crm_case
          prepare_merge_edit
          render 'merge_edit'
        end
        format.api { render_api_errors(l(:error_easy_crm_case_could_not_merge)) }
      end
    end
  end

  def toggle_description
    respond_to do |format|
      format.js
    end
  end

  def context_menu
    if (@easy_crm_cases.size == 1)
      @easy_crm_case = @easy_crm_cases.first
    end
    @easy_crm_case_ids = @easy_crm_cases.map(&:id).sort

    can_edit = @easy_crm_cases.detect{|c| !c.editable?}.nil?
    can_delete = @easy_crm_cases.detect{|c| !c.deletable?}.nil?
    @can = {:edit => can_edit, :delete => can_delete}
    @back = back_url

    @safe_attributes = @easy_crm_cases.map(&:safe_attribute_names).reduce(:&)
    @easy_crm_case_statuses = EasyCrmCaseStatus.sorted

    if @project
      if @easy_crm_case
        @assignables = @easy_crm_case.assignable_users
        @assignables_external = @easy_crm_case.external_assignable_users
      else
        @assignables = @easy_crm_cases.map{|x| x.assignable_users}.reduce(:&).uniq
        @assignables_external = @easy_crm_cases.map{|x| x.external_assignable_users}.reduce(:&).uniq
      end

      if @safe_attributes.include?('author_id')
        @available_authors = @project.users.active.non_system_flag.distinct.sorted.to_a
        @available_authors.push(@easy_crm_case.author) if @easy_crm_case && @easy_crm_case.author && !@available_authors.include?(@easy_crm_case.author)
      end
    else
      @assignables = @easy_crm_cases.map{|x| x.assignable_users}.reduce(:&).uniq
      @assignables_external = @easy_crm_cases.map{|x| x.external_assignable_users}.reduce(:&).uniq
    end

    render :layout => false
  end

  def bulk_edit
    if params[:easy_crm_case] && params[:easy_crm_case][:project_id]
      @target_project = Project.find_by(:id => params[:easy_crm_case][:project_id])
      if @target_project
        available_projects = [@target_project]
      end
    end
    available_projects ||= Project.preload(:members => [:roles]).where(:id => @easy_crm_cases.map(&:project_id))

    #@assignables = available_projects.map(&:assignable_users).reduce(:&)
    @available_watchers = available_projects.map(&:users).reduce(:&)

    @easy_crm_case_params = params[:easy_crm_case] || {}
    @easy_crm_case_params.delete_if {|_, v| v.blank?}
    @easy_crm_case_params[:custom_field_values] ||= {}

    @safe_attributes = @easy_crm_cases.map(&:safe_attribute_names).reduce(:&)
    @custom_fields = @easy_crm_cases.map { |c| c.editable_custom_fields }.reduce(:&).uniq
  end

  def bulk_update
    @easy_crm_cases.sort!
    attributes = parse_params_for_bulk_crm_case_attributes

    unsaved_easy_crm_cases = []
    saved_easy_crm_cases = []

    @easy_crm_cases.each do |easy_crm_case|
      journal = easy_crm_case.init_journal(User.current, params[:notes])
      safe_attributes = attributes.dup

      restricted_attrs = safe_attributes.keys - easy_crm_case.safe_attribute_names
      if restricted_attrs.present?
        restricted_attrs.each do |attr|
          easy_crm_case.errors.add(attr, l(:error_not_a_safe_attribute))
        end
        unsaved_easy_crm_cases << easy_crm_case
        next
      end

      if easy_crm_case.contract_date && attributes['contract_date'].is_a?(Numeric)
        easy_crm_case.contract_date = easy_crm_case.contract_date + safe_attributes.delete('contract_date').days
      end
      if easy_crm_case.next_action && attributes['next_action'].is_a?(Numeric)
        easy_crm_case.next_action = easy_crm_case.next_action + safe_attributes.delete('next_action').days
      end
      easy_crm_case.safe_attributes = safe_attributes
      saved = false
      begin
        saved = easy_crm_case.save
      rescue ActiveRecord::StaleObjectError
        easy_crm_case.reload
        easy_crm_case.safe_attributes = attributes.dup
        saved = easy_crm_case.save
      end
      if saved
        send_notification_updated(easy_crm_case)
        saved_easy_crm_cases << easy_crm_case
      else
        # Keep unsaved issue ids to display them in flash error
        unsaved_easy_crm_cases << easy_crm_case
      end
    end

    if unsaved_easy_crm_cases.empty?
      flash[:notice] = l(:notice_successful_update) unless saved_easy_crm_cases.empty?
      if params[:follow]
        if @easy_crm_cases.size == 1 && saved_easy_crm_cases.size == 1
          redirect_to easy_crm_case_path(saved_easy_crm_cases.first)
        elsif saved_easy_crm_cases.map(&:project).uniq.size == 1
          redirect_to project_easy_crm_cases_path(saved_easy_crm_cases.first.project)
        end
      else
        redirect_back_or_default project_easy_crm_cases_path(saved_easy_crm_cases.first.project)
      end
    else
      @saved_easy_crm_cases = @easy_crm_cases
      @unsaved_easy_crm_cases = unsaved_easy_crm_cases
      @easy_crm_cases = EasyCrmCase.visible.where(:id => @unsaved_easy_crm_cases.map(&:id)).to_a
      bulk_edit
      render :action => 'bulk_edit'
    end
  end

  def find_by_worker
    scope = User.active.non_system_flag.easy_type_internal.sorted
    scope = scope.like(params[:q]) unless params[:q].blank?
    @users = scope.to_a

    respond_to do |format|
      format.html {render :partial => 'find_by_worker_list', :locals => {:users => @users}}
      format.js
    end
  end

  def remove_related_invoice
    @easy_invoice_ids  = params[:invoice_ids]
    User.current.allowed_to?(:edit_easy_crm_cases, @project) && @easy_crm_case.easy_invoices.delete(EasyInvoice.find(params[:invoice_ids]))
    respond_to do |format|
      format.js
    end
  end

  def render_tab
    case params[:tab]
    when 'spent_time'
      l_table = TimeEntry.table_name

      @query = EasyTimeEntryQuery.new
      @query.filters = {}
      @query.column_names = [:user, :spent_on, :activity, :hours]
      @query.add_additional_statement("#{l_table}.entity_type='EasyCrmCase' AND #{l_table}.entity_id = #{@easy_crm_case.id}")

      render partial: 'easy_crm_cases/tabs/spent_time'
    when 'easy_entity_activity'
      @easy_entity_activities = @easy_crm_case.easy_entity_activities.includes(:category, easy_entity_activity_attendees: :entity).sorted
      @new_easy_entity_activity = @easy_crm_case.easy_entity_activities.build(author: @easy_crm_case.assigned_to).to_decorate
      render partial: 'common/tabs/entity_activities'
    else
      render_404
    end
  end

  def sales_activities
    index_for_easy_query EasyEntityActivityCrmCaseQuery, [['start_time', 'desc']]
  end

  def render_assignments_form_on_issue
    @issue = Issue.find_by(id: params[:issue_id])
    respond_to do |format|
      format.js {render partial: 'issues/easy_crm_case_render_assignments_form'}
    end
  end

  def description_edit

  end

  private

  def mark_as_read
    @easy_crm_case&.mark_as_read
  end

  def find_easy_crm_case
    @easy_crm_case = EasyCrmCase.find(params[:id])
    render_403 unless @easy_crm_case.visible?
  rescue ActiveRecord::RecordNotFound
    render_404
  end

  def find_easy_crm_cases
    @easy_crm_cases = EasyCrmCase.visible.where(:id => (params[:id] || params[:ids])).to_a
    raise ActiveRecord::RecordNotFound if @easy_crm_cases.empty?
    raise Unauthorized unless @easy_crm_cases.all?(&:visible?)
    @projects = @easy_crm_cases.collect(&:project).compact.uniq
    @project = @projects.first if @projects.size == 1
  rescue ActiveRecord::RecordNotFound
    render_404
  end

  def find_project(project_id = params[:project_id])
    @project = @easy_crm_case.project unless @easy_crm_case.nil?
    @project ||= (Project.find(project_id) unless project_id.blank?)
  rescue ActiveRecord::RecordNotFound
    render_404
  end

  def update_easy_crm_case_from_params
    @time_entry = TimeEntry.new(:project => @project, :entity => @easy_crm_case)
    @time_entry.safe_attributes = params[:time_entry]

    @easy_crm_case.init_journal(User.current)

    easy_crm_case_attributes = params[:easy_crm_case]
    if easy_crm_case_attributes && params[:conflict_resolution]
      case params[:conflict_resolution]
      when 'overwrite'
        easy_crm_case_attributes = easy_crm_case_attributes.dup
        easy_crm_case_attributes.delete(:lock_version)
      when 'add_notes'
        easy_crm_case_attributes = easy_crm_case_attributes.slice(:notes)
      when 'cancel'
        redirect_to easy_crm_case_path(@easy_crm_case)
        return false
      end
    end

    @easy_crm_case.safe_attributes = easy_crm_case_attributes
    @easy_crm_case.project = @project if @easy_crm_case.project.nil?

    true
  end

  def easy_crm_after_save
  end

  def save_easy_crm_case_with_child_records
    saved = false
    EasyCrmCase.transaction do
      if time_entry_params? && User.current.allowed_to?(:log_time, @easy_crm_case.project)
        time_entry = @time_entry || TimeEntry.new
        time_entry.project = @easy_crm_case.project
        time_entry.entity = @easy_crm_case
        time_entry.user = User.current
        time_entry.spent_on = User.current.today
        time_entry.safe_attributes = params[:time_entry]

        @easy_crm_case.time_entries << time_entry
      end

      saved = @easy_crm_case.save
      raise ActiveRecord::Rollback unless saved
    end

    saved
  end
  
  def time_entry_params?
    params[:time_entry] &&
      (
      params[:time_entry][:hours].present? ||
        params[:time_entry][:comments].present? ||
        params[:time_entry][:hours_hour].present? ||
        params[:time_entry][:hours_minute].present? ||
        params[:time_entry][:easy_time_entry_range] && (
          params[:time_entry][:easy_time_entry_range][:from].present? ||
          params[:time_entry][:easy_time_entry_range][:to].present?
        )
    )
  end

  def parse_params_for_bulk_crm_case_attributes
    %w(contract_date next_action).each do |attr_name|
      type = params[:easy_crm_case].delete("#{attr_name}_type")
      if type == 'unchanged'
        params[:easy_crm_case].delete(attr_name)
      elsif type == 'change_by' && params[:easy_crm_case][attr_name].present?
        if (offset = params[:easy_crm_case][attr_name].to_i) && offset.nonzero?
          params[:easy_crm_case][attr_name] = offset
        else
          params[:easy_crm_case][attr_name] = 'none'
        end
      elsif type && params[:easy_crm_case][attr_name].blank?
        params[:easy_crm_case][attr_name] = 'none'
      end
    end
    params[:easy_crm_case][:watcher_group_ids] = [nil] if params[:easy_crm_case][:watcher_user_ids].present?

    parse_params_for_bulk_update(params[:easy_crm_case])
  end

  def build_easy_crm_case
    @easy_crm_case = EasyCrmCase.new
    @easy_crm_case.safe_attributes = params[:easy_crm_case]
    @easy_crm_case.easy_crm_case_status ||= EasyCrmCaseStatus.default || EasyCrmCaseStatus.all.first
    @easy_crm_case.project ||= @project
    @project ||= @easy_crm_case.project
    @easy_crm_case.currency ||= @project.try(:easy_currency_code)
    @easy_crm_case.author ||= User.current
  end

  def send_notification_updated(easy_crm_case)
    if Setting.notified_events.include?('easy_crm_case_updated') && easy_crm_case.current_journal && !easy_crm_case.current_journal.new_record?
      EasyCrmMailer.deliver_easy_crm_case_updated(easy_crm_case.current_journal)
    end
  end

  def prepare_merge_edit
    custom_fields_distribution
    crm_case_map_for_merge
    @available_projects = @easy_crm_cases.map(&:project).uniq.sort_by(&:lft)
    @assignables = @easy_crm_cases.map{ |c| c.assignable_users }.reduce(:&).uniq
    @assignables_external = @easy_crm_cases.map{ |c| c.external_assignable_users }.reduce(:&).uniq
  end

  def custom_fields_distribution
    @easy_format_custom_fields = []
    @advanced_format_custom_fields = []

    custom_fields = @easy_crm_cases.map { |c| c.available_custom_fields }.reduce(:&).uniq
    custom_fields.each do |custom_field|
      if ADVANCED_LIST_FORMAT_CUSTOM_FIELDS.include?(custom_field.field_format)
        @advanced_format_custom_fields << custom_field
      else
        @easy_format_custom_fields << custom_field
      end
    end
  end

  def merge_date_time_format(dt)
    if dt
      datetime = User.current.user_time_in_zone(dt.to_datetime)
      [datetime.to_date, datetime.strftime('%H'), datetime.strftime('%M')]
    else
      ['', '00', '00']
    end
  end

  def find_target_crm_case
    @target_crm_case = EasyCrmCase.find(params[:merge_to_id])
  rescue ActiveRecord::RecordNotFound
    render_404
  end

  def crm_case_map_for_merge
    @crm_cases_map = Hash.new do |hash,key|
      hash[key] = Hash.new
    end

    @easy_crm_cases.each do |c|
      @crm_cases_map[c.id][:project] = c.project.id
      @crm_cases_map[c.id][:email] = c.email.to_s
      @crm_cases_map[c.id][:telephone] = c.telephone.to_s
      @crm_cases_map[c.id][:easy_crm_case_status] = c.easy_crm_case_status_id.to_i
      @crm_cases_map[c.id][:assigned_to] = c.assigned_to_id.to_i
      @crm_cases_map[c.id][:external_assigned_to] = c.external_assigned_to_id.to_i
      @crm_cases_map[c.id][:created_at] = c.created_at ? c.created_at.to_date : ''
      @crm_cases_map[c.id][:contract_date] = c.contract_date ? c.contract_date.to_date : ''
      @crm_cases_map[c.id][:next_action] = merge_date_time_format(c.next_action_in_zone)
      @crm_cases_map[c.id][:price] = c.price.to_s
      @crm_cases_map[c.id][:currency] = c.currency
      @crm_cases_map[c.id][:is_canceled] = c.is_canceled
      @crm_cases_map[c.id][:is_finished] = c.is_finished
      c.custom_field_values.each do |custom_field_value|
        if custom_field_value.custom_field.field_format == 'datetime'
          @crm_cases_map[c.id]["custom_field_#{custom_field_value.custom_field.id}"] = merge_date_time_format(custom_field_value.value)
        else
          @crm_cases_map[c.id]["custom_field_#{custom_field_value.custom_field.id}"] = custom_field_value.value
        end
      end
    end
  end

end

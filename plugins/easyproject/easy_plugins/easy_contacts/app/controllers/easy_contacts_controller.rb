class EasyContactsController < ApplicationController

  menu_item :project_easy_contacts
  menu_item :easy_contacts

  accept_api_auth :index, :show, :create, :update, :destroy, :remove_from_entity, :assign_entities, :destroy_items

  default_search_scope :easy_contacts

  before_action :authorize_global, :except => [:find_exist_contact, :toggle_issue_contacts_display, :update_form, :overview, :layout]

  before_action :find_contact, :only => [:show, :edit, :update, :destroy, :change_avatar, :toggle_author_note, :render_tab, :anonymize]
  before_action :find_contacts, :only => [:assign_entities, :remove_from_entity, :bulk_edit, :bulk_update, :update_bulk_form, :merge, :destroy_items, :bulk_anonymize]
  before_action :find_project_by_project_id, :if => Proc.new { params[:project_id].present? }
  before_action :find_journals, :only => [:show]
  before_action :permissions_for_editable, only: [:new, :create, :edit, :update, :bulk_edit, :bulk_update]
  before_action :permissions_for_deletable, only: [:destroy, :destroy_items]

  #before_action :authorize, :if => Proc.new{ @project}, :except => [:update_form, :find_exist_contact]

  helper :sort
  include SortHelper
  helper :easy_query
  include EasyQueryHelper
  helper :custom_fields
  include CustomFieldsHelper
  helper :easy_contacts
  include EasyContactsHelper

  helper :search
  helper :attachments
  helper :easy_bulk_edit
  helper :easy_journal

  EasyExtensions::EasyPageHandler.register_for(self, {
    page_name: 'easy-contacts-overview',
    path: proc { easy_contacts_overview_path(t: params[:t]) },
    show_action: :overview,
    edit_action: :layout
  })

  # GET /easy_contacts
  def index
    retrieve_query(EasyContactQuery)
    if @query.project
      @project = @query.project
    end

    sort_init(@query.sort_criteria_init)
    sort_update(@query.sortable_columns)

    if @project
      session.delete(:contacts_filter)
      @query.available_filters.delete_if { |k, v| k == 'project_groups' }
      @query.entity_scope = EasyContact.visible.joins("INNER JOIN easy_contact_entity_assignments ecea ON easy_contacts.id = ecea.easy_contact_id AND ecea.entity_id = #{@project.id} AND ecea.entity_type = 'Project'")
    else
      session[:contacts_filter] = params[:filter] if params[:filter]
      if session[:contacts_filter] == '2' && !User.current.admin?
        @query.entity_scope = EasyContact.joins("INNER JOIN easy_contact_entity_assignments ecea ON easy_contacts.id = ecea.easy_contact_id AND ecea.entity_id = #{User.current.id} AND ecea.entity_type = 'Principal'")
      end
    end

    @easy_contacts = prepare_easy_query_render

    if request.xhr? && !@entities
      render_404
      return false
    end

    respond_to do |format|
      format.html { render_easy_query_html }
      format.api
      format.csv { send_data(export_to_csv(@entities, @query), :filename => get_export_filename(:csv, @query)) }
      format.pdf { render_easy_query_pdf }
      format.xlsx { render_easy_query_xlsx }
      format.vcf {
        if EasyEntityAttributeMap.where(:entity_from_type => EasyContact, :entity_to_type => EasyExtensions::Export::EasyVcard).any?
          vcards = @entities.collect do |contact|
            vcard_generator = EasyExtensions::EasyEntityAttributeMappings::VcardMapper.new(contact, EasyExtensions::Export::EasyVcard).map_entity
            vcard_generator.to_vcard
          end
          encoding = params[:encoding] || 'UTF-8'
          send_data(Redmine::CodesetUtil.safe_from_utf8(vcards.join("\n"), encoding.upcase), :filename => get_export_filename(:vcf, @query))
        else
          flash[:error] = l(:error_easy_entity_attribute_map_invalid)
          return render_404
        end
      }
      format.atom { render_feed(@entities, :title => l(:label_easy_contacts)) }
    end
  end

  # GET /easy_contacts/:id
  # GET /easy_contacts/:id/show
  def show
    @contacts_tree = @easy_contact.hierarchy.visible.preload(:custom_values, :easy_contact_type, :easy_contact_entity_assignments).order(:lft)
    respond_to do |format|
      format.js
      format.html
      format.vcf {
        vcard_generator = EasyExtensions::EasyEntityAttributeMappings::VcardMapper.new(@easy_contact, EasyExtensions::Export::EasyVcard).map_entity
        if vcard_generator
          encoding = params[:encoding] || 'UTF-8'
          send_data(Redmine::CodesetUtil.safe_from_utf8(vcard_generator.to_vcard, encoding.upcase), :filename => "#{@easy_contact.name}.vcf")
        else
          flash[:error] = l(:error_easy_entity_attribute_map_invalid)
          return render_404
        end
      }
      format.qr {
        encoding = params[:encoding] || 'UTF-8'
        vcard_generator = EasyExtensions::EasyEntityAttributeMappings::VcardMapper.new(@easy_contact, EasyExtensions::Export::EasyVcard, :allow_avatar => false)
        if x = vcard_generator.map_entity
          qr_text = Redmine::CodesetUtil.safe_from_utf8(x.to_vcard, encoding.upcase)

          @easy_qr = EasyQr.generate_qr(qr_text.force_encoding('iso-8859-2'))
          if request.xhr?
            render :template => 'easy_qr/show', :formats => [:js], :locals => { :modal => true }
          else
            render :template => 'easy_qr/show', :formats => [:html], :content_type => 'text/html'
          end
        else
          flash[:error] = l(:error_easy_entity_attribute_map_invalid)
          return render_404
        end
      }
      format.api
    end
  end

  # GET /easy_contacts/new
  def new
    @easy_contact = EasyContact.new
    @easy_contact.easy_contact_type = EasyContactType.default
    @assign_to = params[:assign_to]
    @easy_contact.parent_id = params[:parent_id] if params[:parent_id]

    if params[:easy_contact_group_id]
      easy_contact_group = EasyContactGroup.find_by(id: params[:easy_contact_group_id])
      @easy_contact.easy_contact_groups << easy_contact_group if easy_contact_group
    end

    respond_to do |format|
      format.html { render layout: !request.xhr? }
      format.js { @modal = true }
    end
  end

  # POST /easy_contacts
  def create
    @easy_contact = EasyContact.new
    build_easy_contact_from_params

    respond_to do |format|
      if @easy_contact.save
        if params[:assign_to_me].to_s.to_boolean
          User.current.easy_contacts << @easy_contact
        end
        if !@project.nil? && (params[:assign_to_project] || !@easy_contact.is_global?)
          @project.easy_contacts << @easy_contact
        end
        Attachment.attach_files(@easy_contact, params[:attachments] || (params[:easy_contact] && params[:easy_contact][:uploads]))

        call_hook(:controller_easy_contacts_after_save, {:params => params, :easy_contact => @easy_contact})

        if params[:add_new_subcontact]
          next_contact_reference = EasyContact.find_by(:id => params[:easy_contact][:next_contact_reference_id]) if params[:easy_contact]
          @easy_contact_reference = next_contact_reference || @easy_contact
          @easy_contact = EasyContact.new
          @easy_contact.references_by += [@easy_contact_reference]
          @easy_contact.easy_contact_type = EasyContactType.default
          @easy_contact.next_contact_reference_id = @easy_contact_reference.id

          format.html { render :action => 'new', :project_id => @project }
          format.js { @modal = true }
        else
          format.html { redirect_back_or_default(easy_contact_path(@easy_contact, :project_id => @project)) }
          format.js { @modal = true }
          format.api { find_journals; render :action => 'show', :status => :created, :location => easy_contact_url(@easy_contact) }
        end
      else
        format.html { render :action => 'new', :project_id => @project }
        format.js { @modal = true }
        format.api { render_validation_errors(@easy_contact) }
      end
    end
  end

  # GET /easy_contacts/:id/edit
  def edit
    # @easy_contact = EasyContact.find(params[:id])
  end

  def bulk_edit
    prepare_attributes_for_bulk_edit
  end

  # PUT /easy_contacts/:id
  def update
    @easy_contact.add_non_primary_custom_fields(params[:easy_contact][:custom_field_values]) if params[:easy_contact] && !params[:easy_contact][:custom_field_values].blank?
    set_references
    @easy_contact.init_journal(User.current, params[:easy_contact][:notes]) if params[:easy_contact]
    @easy_contact.safe_attributes = params[:easy_contact]
    if @easy_contact.save
      if params[:assign_to_me].present?
        if params[:assign_to_me].to_boolean
          unless User.current.easy_contacts.where(:easy_contact_entity_assignments => {:easy_contact_id => @easy_contact}).exists?
            User.current.easy_contacts << @easy_contact
          end
        else
          User.current.easy_contacts.delete(@easy_contact)
        end
      end

      Attachment.attach_files(@easy_contact, params[:attachments] || (params[:easy_contact] && params[:easy_contact][:uploads]))
      respond_to do |format|
        format.html { redirect_to(easy_contact_path(@easy_contact)) }
        format.api { render_api_ok }
      end
    else
      @easy_contact_types = EasyContactType.all
      respond_to do |format|
        format.html { render :action => 'edit', :project_id => @project }
        format.api { render_validation_errors(@easy_contact) }
      end
    end
  end

  def bulk_update
    attributes = parse_params_for_bulk_user_attributes(params)

    unsaved_contacts = []
    saved_contacts = []

    referenced_by = EasyContact.where(:id => attributes[:easy_contact_references]) if attributes[:easy_contact_references].present?

    errors = []
    @easy_contacts.each do |easy_contact|
      easy_contact.safe_attributes = attributes
      easy_contact.skip_name_validation = true

      easy_contact.references_by = referenced_by if referenced_by

      if easy_contact.save
        saved_contacts << easy_contact
      else
        unsaved_contacts << easy_contact
        errors << easy_contact.errors.full_messages
      end
    end

    respond_to do |format|
      format.js {

        if errors.any?
          flash[:error] = errors.join(', ')
        else
          flash[:notice] = l(:notice_successful_update)
        end

        @flash_message = flash[:error] || flash[:notice]
      }
      format.html {

        if errors.any?
          @unsaved_contacts = unsaved_contacts
          @saved_contacts = saved_contacts
          bulk_edit
          render :action => 'bulk_edit'
        else
          flash[:notice] = l(:notice_successful_update)
          redirect_back_or_default(easy_contacts_path)
        end

      }
    end
  end

  def anonymize
    if @easy_contact.anonymize!
      flash[:notice] = l(:notice_successful_anonymized)
    else
      flash[:error] = @easy_contact.errors.full_messages.join(', ')
    end

    redirect_back_or_default(easy_contact_path(@easy_contact))
  end

  def bulk_anonymize
    unsaved_contacts, saved_contacts, errors = [], [], []

    @easy_contacts.each do |easy_contact|
      if easy_contact.anonymize!
        saved_contacts << easy_contact
      else
        unsaved_contacts << easy_contact
        errors << easy_contact.errors.full_messages
      end
    end

    if unsaved_contacts.empty?
      flash[:notice] = l(:notice_successful_anonymized)
    else
      flash[:error] = errors.join(', ')
    end

    redirect_back_or_default(easy_contacts_path)
  end

  def toggle_author_note
    respond_to do |format|
      format.js
    end
  end

  def merge
    merge_to = EasyContact.find(params[:easy_contact][:merge_to_id])
    merged = EasyContact.easy_merge_easy_contacts(@easy_contacts, merge_to)

    respond_to do |format|
      if merged
        flash[:notice] = l(:notice_successful_update)
        format.html { redirect_back_or_default easy_contact_path(merge_to) }
        format.api { render_api_ok }
      else
        flash[:error] = l(:error_easy_contact_could_not_merge)
        format.html { redirect_back_or_default easy_contact_path(merge_to) }
        format.api { render_api_errors(l(:error_easy_contact_could_not_merge)) }
      end
    end
  rescue ActiveRecord::RecordNotFound
    render_404
  end

  def reg_no_query
    render json: EasyContacts::AresQuery.new(params[:reg_no]).query
  rescue OpenURI::HTTPError => e
    render_error status: 503, message: e.message
  end

  def render_tab
    case params[:tab]
      when 'easy_entity_activity'
        @easy_entity_activities = @easy_contact.sales_activities.includes(:category, easy_entity_activity_attendees: :entity).sorted
        @new_easy_entity_activity = @easy_contact.easy_entity_activities.build.to_decorate
        render partial: 'common/tabs/entity_activities'
      else
        render_404
    end
  end

  def validate_eu_vat_no
    render json: EasyContacts::EuVatNoValidator.new(params[:vat_no]).validate
  end

  def destroy
    @easy_contact.destroy

    respond_to do |format|
      format.api { render_api_ok }
    end
  end

  def destroy_items
    unless params[:ids].blank?
      EasyContact.where(:id => params[:ids]).destroy_all
    else
      flash[:error] = l(:error_no_contacts_select)
    end

    respond_to do |format|
      format.html { redirect_back_or_default :action => 'index', :project_id => @project }
      format.api { render_api_ok }
    end
  end

  def change_avatar
    params[:back_url] = easy_contact_path(@easy_contact)
    respond_to do |format|
      format.js
    end
  end

  def add_custom_field
    custom_field = EasyContactCustomField.find(params[:custom_field_id])
    @custom_value = CustomValue.new(:customized_type => 'EasyContact', :custom_field_id => custom_field.id, :custom_field => custom_field)
  end

  def remove_custom_field
    custom_field_id, entity_id, entity_type = params[:custom_field_id], params[:entity_id], params[:entity_type]
    unless entity_id.blank? || entity_type.blank? || custom_field_id.blank?
      entity = entity_type.constantize.find(entity_id)
      entity.custom_values.each do |custom_value|
        custom_value.destroy if custom_value.custom_field_id == custom_field_id.to_i
      end
    end
  end

  def update_form
    if params[:id].blank?
      @easy_contact = EasyContact.new
    else
      @easy_contact = EasyContact.includes(:custom_values).find(params[:id])
    end

    build_easy_contact_from_params

    respond_to do |format|
      format.js
    end
  end

  def update_bulk_form
    if params[:easy_contact] && params[:easy_contact][:type_id]
      selected_contact_type = EasyContactType.find(params[:easy_contact][:type_id])

      @easy_contacts.each do |easy_contact|
        easy_contact.easy_contact_type = selected_contact_type
      end
    end

    prepare_attributes_for_bulk_edit

    respond_to do |format|
      format.js
    end
  end

  def change_contact_type
    @type = EasyContactType.find(params[:type_id])
  end

  def send_contact_by_mail
    if !params[:ids].blank?
      if params[:recipients]
        contacts = EasyContact.includes(:custom_values).find(params[:ids])
        recipients = User.find(params[:recipients])
        EasyContactMailer.send_contacts(contacts, recipients).deliver
        flash[:notice] = l(:notice_successfully_send_by_mail, :count => contacts.size)
      else
        flash[:error] = l(:error_no_recipients_select)
      end
    else
      flash[:error] = l(:error_no_contacts_select)
    end
    respond_to do |format|
      format.html { redirect_to :back, :project_id => @project }
      format.json {
        render(:json => {:error => flash[:error], :notice => flash[:notice]})
      }
    end
  end

  def assign_entities
    if params[:entity_type] == 'EasyContact' && !params[:not_remove_related_contacts]
      @easy_contacts.each do |contact|
        contact.easy_contacts = []
      end
    end
    if params[:entity_type]
      @entities = params[:entity_type].classify.constantize.where(:id => params[:entity_ids])
      @entities.each do |e|
        e.easy_contacts = (e.easy_contacts + Array(@easy_contacts)).uniq
      end
    end
    respond_to do |format|
      format.html {
        flash[:notice] = l(:notice_successful_update)
        redirect_to params[:back_url] || (@easy_contacts.count > 1 ? polymorphic_path([@project, :easy_contacts]) : polymorphic_path([@project, @easy_contacts.first]))
      }
      format.json {render(json: {notice: l(:notice_successfully_assignable_easy_contacts, count: @easy_contacts.size)})}
      format.api { render_api_ok }
    end
  end

  def remove_from_entity
    if params[:entity_type]
      @entity = params[:entity_type].classify.constantize.find(params[:entity_id])
      @entity.easy_contacts = (@entity.easy_contacts - Array(@easy_contacts))
    end

    respond_to do |format|
      format.html {
        flash[:notice] = l(:notice_successful_update)
        redirect_to params[:back_url] || (@easy_contacts.count > 1 ? easy_contacts_path(:project_id => @project) : easy_contact_path(@easy_contacts.first, :project_id => @project))
      }
      format.js
      format.api { render_api_ok }
    end
  end

  def find_exist_contact
    tokens = Array.new
    easy_contacts = EasyContact.visible
    firstname = params.dig(:easy_contact, :firstname)
    lastname = params.dig(:easy_contact, :lastname)

    if firstname.present?
      tokens << firstname
      easy_contacts = easy_contacts.where [Redmine::Database.like("#{EasyContact.table_name}.firstname", '?'), "%#{firstname}%"]
    end
    if lastname.present?
      tokens << lastname
      easy_contacts = easy_contacts.where [Redmine::Database.like("#{EasyContact.table_name}.lastname", '?'), "%#{lastname}%"]
    end

    if easy_contacts.blank?
      render :plain => ''
    else
      render :partial => 'find_exist_contact', :locals => {:easy_contacts => easy_contacts || '', :tokens => tokens}
    end
  end

  def ctx
    head :ok
  end

  def toggle_display
    @entity = params[:entity_type].classify.constantize.find(params[:entity_id])
    return render(:partial => 'easy_contacts/entity_contacts', :locals => {:entity => @entity, :project => @entity.try(:project), :display => params[:display] && params[:display].to_sym, :back_url => params[:back_url]})
  end

  def import_preview
    @importer = EasyContactImporter.new
    if params[:commit]
      @uploaded_io = params[:import_file]

      if @uploaded_io.nil?
        @errors = [:error_import_file_missing]
        return
      end

      @saved_filename = @uploaded_io.original_filename
      @saved_filepath = import_file_path(@saved_filename)
      File.open(@saved_filepath, 'wb') do |file|
        file.write(@uploaded_io.read)
      end

      import_data_from_file(@saved_filepath)

    end
  end

  def import
    @saved_filename = params[:filename]
    @saved_filepath = import_file_path(@saved_filename)
    import_data_from_file(@saved_filepath)

    if !@import_errors.any?
      @import_data.each { |contact| contact.save }
      flash[:notice] = l(:notice_successfull_contacts_import)
      redirect_to :action => 'import_preview'
    else
      render 'import_preview'
    end
  end

  private

  def find_contact
    @easy_contact = EasyContact.find(params[:id])
    render_403 unless @easy_contact.visible?
  rescue ActiveRecord::RecordNotFound
    render_404
  end

  def find_contacts
    @easy_contacts = EasyContact.find(Array(params[:ids] || params[:id]))
  rescue ActiveRecord::RecordNotFound
    render_404
  end

  def find_journals
    @journals = @easy_contact.journals.preload(:journalized, :user, :details).reorder("#{Journal.table_name}.id ASC").to_a
    @journals.each_with_index { |j, i| j.indice = i+1 }
    Journal.preload_journals_details_custom_fields(@journals)
    @journals.reverse! if User.current.wants_comments_in_reverse_order?
  end

  def save_custom_fields
    @project.custom_field_values = params[:project][:custom_field_values]
    @project.save
    redirect_to :action => 'settings', :id => @project, :tab => 'customfields'
  end

  def set_references
    reference_ids = params.delete(:easy_contact_references) || (params[:easy_contact] && params[:easy_contact].delete(:easy_contact_references))
    @easy_contact.references_by = EasyContact.where(:id => reference_ids) if reference_ids.present?
  end

  def import_file_path(filename)
    directory_name = Rails.root.join('files', 'tmp')
    Dir.mkdir(directory_name) unless File.exists?(directory_name)

    Rails.root.join('files', 'tmp', filename)
  end

  # sets the @import_data
  def import_data_from_file(filepath, options={})
    @encoding = params[:encoding]
    @csv_has_headers = params[:csv_has_headers]
    options[:encoding] = @encoding
    options[:keep_headers] = !@csv_has_headers
    @errors ||= []
    @importer = EasyContactImporter.new
    begin
      @import_data = @importer.import_csv(filepath, options)
      @import_errors = @importer.last_import_errors
      @errors << l(:error_import_data_integrity, :count => @import_errors.count) if @import_errors.any?
    rescue ArgumentError, Encoding::UndefinedConversionError
      @saved_filename = nil
      @errors << :error_import_file_encoding
    rescue StandardError => e
      @saved_filename = nil
      if e.class.to_s.include?('MalformedCSVError')
        @errors << :error_import_file_malformed
      else
        @errors << e.message.to_s
      end
    end
  end

  def build_easy_contact_from_params
    @easy_contact.easy_contact_type = EasyContactType.default
    @easy_contact.add_non_primary_custom_fields(params[:easy_contact][:custom_field_values]) if params[:easy_contact] && !params[:easy_contact][:custom_field_values].blank?
    set_references
    @easy_contact.init_journal(User.current, params[:easy_contact][:notes]) if params[:easy_contact]
    @easy_contact.safe_attributes = params[:easy_contact]
  end

  def parse_params_for_bulk_user_attributes(params)
    attributes = (params[:easy_contact] || {}).reject { |k, v| v.blank? }

    if (easy_contact_references = params[:easy_contact_references]).present? && easy_contact_references.join != '__no_change__'
      attributes[:easy_contact_references] = easy_contact_references
    end

    if (easy_contact_groups = attributes[:easy_contact_group_ids]).present? && easy_contact_groups.join != '__no_change__'
      attributes[:easy_contact_group_ids] = easy_contact_groups
    else
      attributes.delete(:easy_contact_group_ids)
    end

    if custom = attributes[:custom_field_values]
      custom.reject! { |k, v| v.blank? }
      custom.each do |k, v|
        if custom[k].is_a?(Array)
          custom[k] << '' if custom[k].delete('__none__')
        else
          custom[k] = '' if custom[k] == '__none__'
        end
      end
    end
    attributes
  end

  def prepare_attributes_for_bulk_edit
    @easy_contact = EasyContact.new

    @custom_fields = @easy_contacts.map { |c| c.available_custom_fields }.reduce(:&).uniq

    @safe_attributes = @easy_contacts.map(&:safe_attribute_names).reduce(:&)

    @easy_contact_params = params[:easy_contact] || {}
    @easy_contact_params.each { |k, v| @easy_contact_params.delete(k) if v.blank? }
    @easy_contact_params[:custom_field_values] ||= {}
    @easy_contact_params[:easy_contact_references] = params[:easy_contact_references] || {}
    if @easy_contact_params[:easy_contact_group_ids] && @easy_contact_params[:easy_contact_group_ids].join == '__no_change__'
      @easy_contact_params.delete(:easy_contact_group_ids)
    end
    @easy_contact.safe_attributes = @easy_contact_params
  end

  %w(editable deletable).each do |action|
    define_method "permissions_for_#{action}" do
      render_403 if Array(@easy_contact || @easy_contacts).detect { |contact| !contact.send(action + '?') }
    end
  end

end

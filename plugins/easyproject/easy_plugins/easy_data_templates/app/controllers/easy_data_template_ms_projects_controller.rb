require 'easy_data_templates/ms_project/ms_project_2010_xml_parser'

class EasyDataTemplateMsProjectsController < ApplicationController
  layout 'admin'

  before_action :require_admin
  before_action :find_data_template, :only => [:edit, :update, :destroy, :import_settings, :import_data]
  before_action :prepare_import_variables, :only => [:import_settings, :import_data]

  helper :custom_fields
  include CustomFieldsHelper
  helper :projects
  include ProjectsHelper
  helper :attachments
  include AttachmentsHelper
  helper :easy_data_templates
  include EasyDataTemplatesHelper

  def show
  end

  # GET /easy_data_template_ms_projects/new
  # GET /easy_data_template_ms_projects/new.xml
  def new
    @datatemplate = EasyDataTemplateMsProject.new
    @datatemplate.safe_attributes = params[:easy_data_template]

    respond_to do |format|
      format.html # new.html.erb
    end
  end

  # GET /easy_data_template_ms_projects/1/edit
  def edit
    respond_to do |format|
      format.html # new.html.erb
    end
  end

  # POST /easy_data_template_ms_projects
  # POST /easy_data_template_ms_projects.xml
  def create
    @datatemplate = EasyDataTemplateMsProject.new
    @datatemplate.safe_attributes = params[:easy_data_template]
    @datatemplate.save_attachments(params[:attachments])

    respond_to do |format|
      if @datatemplate.save
        flash[:notice] = l(:notice_successful_create)
        format.html { redirect_to({:controller => 'easy_data_template_ms_projects', :action => 'import_settings', :id => @datatemplate}) }
      else
        format.html { render :action => 'new' }
      end
    end
  end

  # PUT /easy_data_template_ms_projects/1
  # PUT /easy_data_template_ms_projects/1.xml
  def update
    @datatemplate.safe_attributes = params[:easy_data_template]
    @datatemplate.save_attachments(params[:attachments]) if params[:attachments]

    respond_to do |format|
      if @datatemplate.save
        flash[:notice] = l(:notice_successful_update)
        format.html { redirect_to({:controller => 'easy_data_templates', :action => 'index'}) }
      else
        format.html { render :action => 'edit' }
      end
    end
  end

  # DELETE /easy_data_template_ms_projects/1
  # DELETE /easy_data_template_ms_projects/1.xml
  def destroy
    @datatemplate.destroy

    respond_to do |format|
      format.html { redirect_to({:controller => 'easy_data_templates', :action => 'index'}) }
    end
  end

  def import_settings
    if @datatemplate.attachments.size <= 0
      redirect_to :action => 'edit', :id => @datatemplate.id
      return
    end

    parser = nil
    begin
      parser = EasyDataTemplates::MsProject::MsProject2010XmlParser.new(@datatemplate.attachments[0].diskfile)
    rescue
      parser = nil
    end

    unless parser
      flash[:error] = l(:error_easy_data_template_ms_project_not_valid_xml)
      @datatemplate.attachments.destroy_all
      redirect_to :action => 'edit', :id => @datatemplate.id
      return
    end

    @xml_project = parser.project

    render :action => 'import_settings'
  end

  def import_data
    if params[:project].blank? || params[:issue].blank?
      redirect_to :action => 'import_settings', :id => @datatemplate.id
      return
    end

    if params[:project] && params[:project][:id]
      new_project = Project.find(params[:project][:id])
    else
      new_project = Project.new
      new_project.enabled_module_names = ['issue_tracking', 'gantt', 'time_tracking']
    end

    new_project.safe_attributes = params[:project]

    if new_project.save
      new_project.set_parent!(nil)
      @valid_objects[:project] = new_project
    else
      @invalid_objects[:project] = new_project
    end

    # We're going to keep track of new issue ID's to make dependencies work later
    uid_to_issue_id = {}
    # keep track of new Version ID's
    uid_to_version_id = {}
    # keep track of the outlineNumbers to set the parent_id
    outlinenumber_to_issue_id = {}
    outlinenumber_to_version_id = {}

    project_users = []

    if @invalid_objects[:project].nil?
      Rails.logger.info("[PROCESS VERSIONS]")

      if params[:version]
        params[:version].each do |version_uuid, version_params|
          next if version_params['allow_import'] == 'no'

          version_options = version_params.dup
          version_options.delete('allow_import')
          version_options.delete('id')

          if version_params['id']
            new_version = new_project.versions.find(version_params['id'])
          else
            new_version = new_project.versions.build
          end

          new_version.safe_attributes = version_options

          if new_version.save
            @valid_objects[:version][version_uuid.to_i] = new_version
            # Store the version_record.id to assign the issues to the version later
            uid_to_version_id[version_params[:uid]] = new_version.id
            outlinenumber_to_version_id[version_params[:outlinenumber]] = new_version.id
            puts ("Uid verision id #{version_params[:outlinenumber]} name => #{new_version.name}")
          else
            @invalid_objects[:version][version_uuid.to_i] = new_version
          end

        end

      end

      Rails.logger.info("[PROCESS ISSUES]")

      if params[:issue]

        params[:issue].each do |issue_uuid, issue_params|
          next if issue_params['allow_import'] == 'no'

          issue_options = issue_params.dup
          issue_options.delete('allow_import')
          issue_options.delete('id')

          unless new_project.trackers.where(id: issue_options['tracker_id'].to_i).exists?
            tracker = Tracker.find_by(id: issue_options['tracker_id'])
            new_project.trackers << tracker if tracker
          end

          if issue_params['id']
            new_issue = new_project.issues.find(issue_params['id'])
          else
            new_issue = new_project.issues.build
          end

          new_issue.safe_attributes = issue_options
          new_issue.author = User.current if new_issue.author.nil?

          project_users << new_issue.assigned_to unless project_users.include?(new_issue.assigned_to)

          Mailer.with_deliveries(false) do
            if new_issue.save
              @valid_objects[:issue][issue_uuid.to_i] = new_issue

              # Now that we know this issue's Redmine issue ID, save it off for later
              uid_to_issue_id[issue_params[:uid]] = new_issue.id

              puts ("Uid issue id #{issue_params[:uid]} subject => #{new_issue.subject}")

              #Save the Issue's ID with the outlineNumber as an index, to set the parent_id later
              outlinenumber_to_issue_id[issue_params[:outlinenumber]] = new_issue.id
            else
              @invalid_objects[:issue][issue_uuid.to_i] = new_issue
            end
          end
        end

        Rails.logger.info("[PROCESS RELATIONS]")

        params[:issue_relations]&.each do |issue_uuid, issue_params|
          Rails.logger.info("[PROCESS RELATION START] #{issue_uuid.to_i}")
          next if (issue_from = @valid_objects[:issue][issue_uuid.to_i]).nil?

          issue_params[:relations]&.each do |issue_to_uuid, relations_params|
            next if (issue_to = @valid_objects[:issue][issue_to_uuid.to_i]).nil?

            begin
              delay = (issue_from.start_date - issue_to.due_date).to_i - 1
              IssueRelation.create(relation_type: relations_params['relation_type'],
                                   delay: delay,
                                   issue_from: issue_from,
                                   issue_to: issue_to)
            rescue ActiveRecord::RecordNotUnique, ActiveRecord::StatementInvalid => e
              Rails.logger.info("[WARNING] #{e}")
            end
          end
        end

      end

      project_users = project_users.compact.uniq

      mapped_users = {}
      if params[:resource]

        params[:resource].each do |resource_uuid, resource_params|
          mapped_users[resource_params['assigned_to_id']] = resource_uuid unless resource_params['assigned_to_id'].blank?
        end

        project_users.each do |user|
          resource_uuid = mapped_users[user.id.to_s]
          next if resource_uuid.blank?

          if params[:resource][resource_uuid]['role_id'].blank?
            @invalid_objects[:user][resource_uuid.to_i] ||= []
            @invalid_objects[:user][resource_uuid.to_i] << "#{l(:field_role)} #{l(:'activerecord.errors.messages.blank')}"
          else
            if m = new_project.members.detect{|x| x.user_id == user.id}
              m.destroy
            end
            new_project.members.create(:user_id => user.id, :role_ids => [params[:resource][resource_uuid]['role_id'].to_i])
          end
        end

      end

      Rails.logger.info("[MAP FUNCTIONS EXEC]")

      issues_info = params[:issue].to_unsafe_hash.map do |issue|
        result = {}
        result[:uid] = issue[1]['uid']
        result[:predecessors] = issue[1]['predecessors']
        result[:outlinenumber] = issue[1]['outlinenumber']

        result
      end

      map_subtasks_and_parents(issues_info, new_project.id, nil, uid_to_issue_id, outlinenumber_to_issue_id)
      map_versions(issues_info, new_project.id, nil, uid_to_issue_id, outlinenumber_to_version_id)

      Rails.logger.info("[COMPLETED IMPORT]")

    end

    if errors?
      flash[:error] = l(:error_during_import) + ' ' + error_message
      import_settings
      return
    else
      flash[:notice] = l(:notice_easy_data_templates_import_ok)

      redirect_to :controller => 'projects', :action => 'settings', :id => @valid_objects[:project]
      return
    end

  end

  def map_subtasks_and_parents(tasks, project_id, hashed_name=nil, uid_to_issue_id=nil, outlinenumber_to_issue_id=nil)
    Rails.logger.info "DEBUG: #{__method__.to_s} started"
    Rails.logger.info "tasks: #{tasks.try(:size)}, hashed_name: #{hashed_name}, project: #{project_id}"

    Issue.transaction do
      tasks.each do |source_issue|
        parent_outlinenumber = source_issue[:outlinenumber].split('.')[0...-1].join('.')
        Rails.logger.info "[MAP SUBTASK] Issue uid #{source_issue} outline -> #{parent_outlinenumber}"
        if parent_outlinenumber.present?
          if destination_issue = Issue.find_by_id_and_project_id(uid_to_issue_id[source_issue[:uid]], project_id)
            Rails.logger.info "[MAP SUBTASK] Issue uid #{source_issue} outline -> #{parent_outlinenumber}"
            unless outlinenumber_to_issue_id[parent_outlinenumber].nil?
              Rails.logger.info "DEBUG: SET Parent id to #{destination_issue.id} -> #{outlinenumber_to_issue_id[parent_outlinenumber]}"
              # Rails.logger.info "[MAP SUBTASK] Parent ID #{outlinenumber_to_issue_id[parent_outlinenumber]} : #{Issue.find(outlinenumber_to_issue_id[parent_outlinenumber])} outline -> #{parent_outlinenumber}"
              destination_issue.update_attributes(parent_issue_id: outlinenumber_to_issue_id[parent_outlinenumber])
            end
          end
        end
      end
    end
  end

  def map_versions(tasks, project_id, hashed_name=nil, uid_to_issue_id=nil, outlinenumber_to_version_id=nil)
    Rails.logger.info "DEBUG: #{__method__.to_s} started"
    Rails.logger.info "tasks: #{tasks.try(:size)}, hashed_name: #{hashed_name}, project: #{project_id}"

    Issue.transaction do
      tasks.each do |source_issue|
        parent_outlinenumber = source_issue[:outlinenumber].split('.')[0...-1].join('.')
        Rails.logger.info "[MAP SUBTASK] Issue uid #{source_issue} outline -> #{parent_outlinenumber}"
        if parent_outlinenumber.present?
          if destination_issue = Issue.find_by_id_and_project_id(uid_to_issue_id[source_issue[:uid]], project_id)
            Rails.logger.info "[MAP SUBTASK] Issue uid #{source_issue} outline -> #{parent_outlinenumber}"
            unless outlinenumber_to_version_id[parent_outlinenumber].nil?
              Rails.logger.info "DEBUG: SET Version id to #{destination_issue.id} -> #{outlinenumber_to_version_id[parent_outlinenumber]}"
              # Rails.logger.info "[MAP SUBTASK] Version ID #{outlinenumber_to_version_id[parent_outlinenumber]} : #{Version.find(outlinenumber_to_version_id[parent_outlinenumber])} outline -> #{parent_outlinenumber}"
              destination_issue.update_attributes(fixed_version_id: outlinenumber_to_version_id[parent_outlinenumber])
            end
          end
        end
      end
    end
  end

  def errors?
    !@invalid_objects[:project].blank? || !@invalid_objects[:issue].blank? || !@invalid_objects[:user].blank? || !@invalid_objects[:version].blank?
  end

  private

  def error_message
    return "#{I18n.t('field_project')}: " + @invalid_objects[:project].errors.full_messages.join(', ') if @invalid_objects[:project].present?
    return "#{I18n.t('field_user')}: " + @invalid_objects[:user].values.first.join(', ') if @invalid_objects[:user].present?
    [:issue, :version].each do |type|
      if @invalid_objects[type].present? && (invalid_object = @invalid_objects[type].values.first)
        return "#{I18n.t("field_#{type}")}: " + invalid_object.errors.full_messages.join(', ')
      end
    end
  end

  def find_data_template
    @datatemplate = EasyDataTemplate.find(params[:id])
  rescue
    render_404
  end

  def prepare_import_variables
    @invalid_objects = {:project => nil, :issue => {}, :user => {}, :version => {}}
    @valid_objects = {:project => nil, :issue => {}, :user => {}, :version => {}}
  end

end

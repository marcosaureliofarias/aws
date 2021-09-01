require 'easy_extensions/easy_mail_template'

class EasyExternalEmailsController < ApplicationController

  before_action :find_entity
  before_action :find_project
  before_action :easy_authorize

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

  helper :issues

  def preview_external_email
    @mail_template = get_easy_mail_template
    respond_to do |format|
      format.html
      format.js
    end
  end

  def send_external_email
    @mail_template = get_easy_mail_template
    @journal       ||= @entity.journals.last

    all_attachments = []
    if !@entity.attachments_delegable?
      uploaded_files = @entity.save_attachments(params[:attachments] || (params[:issue] && params[:issue][:uploads]))
      @entity.attach_saved_attachments
      all_attachments.concat(uploaded_files[:files]) unless uploaded_files.blank? || uploaded_files[:files].blank?
      all_attachments.concat(Attachment.where(id: params[:ids]).to_a) unless params[:ids].blank?
    end

    EasyExtensions::ExternalMailSender.call(@entity, @mail_template, journal: @journal, attachments: all_attachments)

    call_hook :controller_easy_external_emails_after_save, params: params, entity: @entity

    respond_to do |format|
      format.html {
        if @entity.errors.any?
          flash[:error] = @entity.errors.full_messages.join('<br>'.html_safe)
        else
          flash[:notice] = l(:notice_email_sent, value: @mail_template.mail_recepient)
        end
        redirect_back_or_default @entity
      }
    end
  end

  private

  def find_entity
    entity_type = params[:entity_type]&.safe_constantize
    if entity_type
      @entity = entity_type.find(params[:id] || params[:entity_id])
      true
    else
      render_404
    end
  rescue ActiveRecord::RecordNotFound
    render_404
  end

  def easy_authorize
    if (@entity && @entity.respond_to?(:visible?) && !@entity.visible?) || !User.current.internal_client?
      return render_403
    end
  end

  def find_project
    @project = Project.find(params[:project_id]) unless params[:project_id].blank?
    @project ||= @entity.project if @entity.respond_to?(:project)
  rescue ActiveRecord::RecordNotFound
    render_404
  end

  def set_easy_extensions_easy_mail_template_issue(easy_mail_template, issue, journal = nil)
    @issue ||= issue

    if journal
      @issue_url = issue_url(@issue, :anchor => "change-#{@journal.id}")
      type       = 'edit'
    else
      @issue_url = issue_url(@issue)
      type       = 'add'
    end

    easy_mail_template.entity_url      = @issue_url
    easy_mail_template.mail_subject    = l(:"mail.subject.issue_#{type}", :issuestatus => issue.status.name, :issuesubject => (EasySetting.value('show_issue_id', issue.project) ? "##{issue.id} - #{issue.subject}" : issue.subject), :projectname => issue.project.family_name(:separator => ' > '), :issueid => issue.id)
    easy_mail_template.mail_body_plain = render_to_string(:template => "mailer/issue_#{type}", :formats => [:text], :layout => false)

    if Setting.text_formatting == 'HTML'
      easy_mail_template.mail_body_html = render_to_string(:template => "mailer/issue_#{type}", :formats => [:html], :layout => false)
    else
      easy_mail_template.mail_body_html = easy_mail_template.mail_body_plain
    end
    easy_mail_template.mail_reply_to ||= Setting.mail_from

    easy_mail_template
  end

  def get_easy_mail_template
    if request.post? && !request.xhr?
      easy_mail_template = @entity.get_easy_mail_template.from_params(params)
    else
      easy_mail_template = @entity.get_easy_mail_template.from_entity(@entity)

      if request.xhr?
        easy_mail_template.mail_cc        = params[:mail_cc]
        easy_mail_template.mail_sender    = params[:mail_sender]
        easy_mail_template.mail_recepient = params[:mail_recepient]
      end

      if @entity.respond_to?(:journals) && @journal = @entity.journals.last
        send("set_#{easy_mail_template.class.name.underscore.tr('/', '_')}".to_sym, easy_mail_template, @entity, @journal)
      else
        send("set_#{easy_mail_template.class.name.underscore.tr('/', '_')}".to_sym, easy_mail_template, @entity)
      end

    end
    easy_mail_template
  end

end

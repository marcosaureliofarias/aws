module EasyApiDecorators
  class Issue < EasyApiEntity

    include CustomFieldsHelper
    include IssuesHelper
    include AttachmentsHelper

    def build_api!(api)
      @issue      = @entity
      @relations  ||= @issue.relations.select { |r| r.other_issue(@issue) && r.other_issue(@issue).visible? } if include_in_api_response?('relations')
      @changesets ||= @issue.changesets.visible.preload(:user) if include_in_api_response?('changesets')
      @journals   ||= @issue.prepare_journals(false, true)[0] if include_in_api_response?('journals')

      api.issue do
        api.id @issue.id
        api.easy_external_id @issue.easy_external_id if @issue.easy_external_id.present?
        api.project(:id => @issue.project_id, :name => @issue.project.name) unless @issue.project.nil?
        api.tracker(:id => @issue.tracker_id, :name => @issue.tracker.name) unless @issue.tracker.nil?
        api.status(:id => @issue.status_id, :name => @issue.status.name) unless @issue.status.nil?
        api.css_classes @issue.css_classes
        api.priority(:id => @issue.priority_id, :name => @issue.priority.name) unless @issue.priority.nil?
        api.activity(:id => @issue.activity_id, :name => @issue.activity.name) if !@issue.activity.nil? && (@issue.project && @issue.project.fixed_activity?)
        api.author(:id => @issue.author_id, :name => @issue.author.name) unless @issue.author.nil?
        if @issue.assigned_to.present?
          assigned_to_hash = { :id => @issue.assigned_to_id, :name => @issue.assigned_to.name }
          if @issue.assigned_to.respond_to?(:easy_avatar) && @issue.assigned_to.easy_avatar.present?
            assigned_to_hash[:avatar_urls] = Hash[EasyAvatar::IMAGE_STYLES.keys.map do |style|
              [style, @issue.assigned_to.easy_avatar.image.url(style)]
            end]
          end
          api.assigned_to(assigned_to_hash)
        end
        api.category(:id => @issue.category_id, :name => @issue.category.name) unless @issue.category.nil?
        api.fixed_version(:id => @issue.fixed_version_id, :name => @issue.fixed_version.name) unless @issue.fixed_version.nil?
        api.parent(:id => @issue.parent_id) unless @issue.parent.nil?

        api.subject @issue.subject
        api.description @issue.description
        api.start_date @issue.start_date
        api.due_date @issue.due_date
        api.done_ratio @issue.done_ratio
        api.is_private @issue.is_private
        api.is_favorited @issue.is_favorited?
        api.estimated_hours @issue.estimated_hours
        api.easy_email_to @issue.easy_email_to if @issue.easy_email_to.present?
        api.easy_email_cc @issue.easy_email_cc if @issue.easy_email_cc.present?

        if User.current.allowed_to?(:view_time_entries, @project)
          api.spent_hours(@issue.spent_hours)
          api.total_spent_hours(@issue.total_spent_hours)
        end

        render_api_custom_values @issue.visible_custom_field_values, api

        api.created_on @issue.created_on
        api.updated_on @issue.updated_on
        api.closed_on @issue.closed_on

        api.last_journal id: @issue.current_journal.id do
          render_api_journal_body(@issue.current_journal, api)
        end if @issue.current_journal

        render_api_issue_children(@issue, api) if include_in_api_response?('children')

        api.array :attachments do
          @issue.attachments.each do |attachment|
            render_api_attachment(attachment, api)
          end
        end if include_in_api_response?('attachments')

        api.array :relations do
          @relations.each do |relation|
            api.relation(:id => relation.id, :issue_id => relation.issue_from_id, :issue_to_id => relation.issue_to_id, :relation_type => relation.relation_type, :delay => relation.delay)
          end
        end if include_in_api_response?('relations') && @relations.present?

        api.array :changesets do
          @changesets.each do |changeset|
            api.changeset :revision => changeset.revision do
              api.user(:id => changeset.user_id, :name => changeset.user.name) unless changeset.user.nil?
              api.comments changeset.comments
              api.committed_on changeset.committed_on
            end
          end
        end if include_in_api_response?('changesets')

        api.array :journals do
          @journals.each do |journal|
            render_api_journal(journal, api)
          end
        end if include_in_api_response?('journals')

        api.array :watchers do
          @issue.watcher_users.each do |user|
            api.user :id => user.id, :name => user.name
          end
        end if include_in_api_response?('watchers') && User.current.allowed_to?(:view_issue_watchers, @issue.project)

        call_hook(:decorator_issues_show_api_bottom, { :api => api, :issue => @issue })
      end
      api
    end

    def self.entity_class
      ::Issue
    end
  end
end

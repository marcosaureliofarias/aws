# frozen_string_literal: true

module EasyGraphql
  module Types
    class Issue < Base
      description 'Task'

      self.entity_class = 'Issue'

      has_custom_values

      field :id, ID, null: false
      field :subject, String, null: true
      field :author, Types::User, null: true
      field :assigned_to, Types::User, null: true
      field :project, Types::Project, null: true
      field :easy_external_id, String, null: true
      field :css_classes, String, null: true
      field :tracker, Types::Tracker, null: true
      field :start_date, Types::Scalars::Date, null: true
      field :due_date, Types::Scalars::Date, null: true
      field :created_on, GraphQL::Types::ISO8601DateTime, null: true
      field :updated_on, GraphQL::Types::ISO8601DateTime, null: true
      field :done_ratio, Int, null: true
      field :estimated_hours, Float, null: true
      field :spent_hours, Float, null: true
      field :attachments, [Types::Attachment], null: true
      field :tags, [Types::Tag], null: true
      field :time_entries, [Types::TimeEntry], null: true
      field :watchers, [Types::User], null: true
      field :priority, Types::Enumeration, null: true
      field :version, Types::Version, null: true
      field :status, Types::IssueStatus, null: true
      field :is_favorite, Boolean, null: true, method: :is_favorited?
      field :is_private, Boolean, null: true, method: :is_private
      field :descendants, [Types::Issue], null: true
      field :ancestors, [Types::Issue], null: true
      field :relations, [Types::IssueRelation], null: true
      field :parent, Types::Issue, null: true
      field :easy_level, Int, null: false
      field :time_entries_custom_values, [Types::CustomValue], null: true do
        argument :activity_id, Int,
                 'Visible custom values by activity',
                 default_value: nil,
                 required: false
      end
      field :time_entries_comment_required, ::GraphQL::Types::Boolean, null: true
      field :safe_attribute_names, [String], null: true
      field :required_attribute_names, [String], null: true
      field :category, String, null: true

      # TODO: move it {have_journals}
      field :journals, [Types::Journal], null: true do
        argument :all, Boolean, required: false
      end
      field :journals_count, Int, null: true

      field :description, String, null: true do
        argument :formatted, Boolean,
                 'Format description based on configured text editor',
                 default_value: false,
                 required: false
      end

      field :new_available_watchers, [Types::User], null: true do
        argument :q, String,
                 'Search available watchers by name or return everybody (limited by autocomplete limit)',
                 default_value: nil,
                 required: false
      end

      field :add_issues, Boolean, null: false
      field :move_issues, Boolean, null: false
      field :copy_issues, Boolean, null: false
      field :editable, Boolean, null: false
      field :deletable, Boolean, null: false, method: :deletable?
      field :addable_notes, Boolean, null: false
      field :addable_time_entries, Boolean, null: false
      field :addable_watchers, Boolean, null: false
      field :deletable_watchers, Boolean, null: false
      field :private_notes_enabled, Boolean, null: false
      field :set_is_private, Boolean, null: false
      field :manage_subtasks, Boolean, null: false

      field :all_available_parents, [Types::Issue], null: false do
        description "Get available parent's issues (without pagination)"
        argument :term, String, required: false
      end

      field :all_available_relations, [Types::Issue], null: false do
        description "Get available issues for relations (without pagination)"
        argument :term, String, required: false
      end

      field :all_issue_relation_types, [Types::IssueRelationCategory], null: false

      def all_available_parents(term: '')
        limit = EasySetting.value('easy_select_limit').to_i

        ::Issue.cross_project_scope(object.project, ::Setting.cross_project_subtasks).
                visible.
                like(term).
                order(:subject).
                limit(limit)
      end

      def all_available_relations(term: '')
        limit = ::EasySetting.value('easy_select_limit').to_i
        project_scope =
          if ::Setting.cross_project_issue_relations?
            'all'
          else
            'project'
          end

        ::Issue.cross_project_scope(object.project, project_scope).
                visible.
                like(term).
                order(:subject).
                limit(limit)

      end

      def all_issue_relation_types
        values = ::IssueRelation::TYPES
        values.keys.sort_by { |k| values[k][:order] }.map do |key|
          { 'name' => I18n.t(values[key][:name]), 'key' => key }
        end
      end

      def required_attribute_names
        required_names = object.required_attribute_names
        object.visible_custom_field_values.each do |cfv|
          next unless cfv.custom_field.is_required?

          required_names << cfv.custom_field.id.to_s
        end
        required_names.uniq
      end

      def time_entries_custom_values(activity_id: nil)
        time_entry = ::TimeEntry.new(issue: object, project: object.project)
        time_entry.activity_id = activity_id if activity_id
        time_entry.visible_custom_field_values
      end

      def description(formatted:)
        if formatted
          cleared_issues_helpers.textilizable(object, :description)
        else
          object.description
        end
      end

      def journals(all: false)
        journals, count = object.prepare_journals(::User.current.wants_comments_in_reverse_order?, all)
        journals
      end

      def journals_count
        prepared_journals = object.journals.where(easy_type: nil).preload(:details)
        prepared_journals = prepared_journals.where(private_notes: false) unless ::User.current.allowed_to?(:view_private_notes, object.project)
        prepared_journals = prepared_journals.to_a

        ::Journal.preload_journals_details_custom_fields(prepared_journals)

        prepared_journals.select! {|journal| journal.notes? || journal.visible_details.any? }
        prepared_journals.count
      end

      def ancestors
        object.ancestors.visible
      end

      def descendants
        object.descendants.visible
      end

      def parent
        parent = object.parent
        parent if parent&.visible?
      end

      def time_entries
        object.time_entries.visible
      end

      def watchers
        object.watcher_users
      end

      def version
        object.fixed_version
      end

      def new_available_watchers(q:)
        current_watchers = object.watcher_users
        available_watchers = object.project.
                                    users.
                                    active.
                                    visible.
                                    sorted.
                                    where.not(id: current_watchers).
                                    limit(EasySetting.value('easy_select_limit').to_i)

        if q
          available_watchers = available_watchers.like(q)
        end

        available_watchers
      end

      def add_issues
        ::User.current.allowed_to?(:add_issues, object.project)
      end

      def move_issues
        ::User.current.allowed_to?(:move_issues, object.project)
      end

      def copy_issues
        ::User.current.allowed_to?(:copy_issues, object.project)
      end

      def editable
        object.attributes_editable?
      end

      def addable_notes
        object.notes_addable?
      end

      def addable_time_entries
        ::User.current.allowed_to?(:log_time, object.project)
      end

      def addable_watchers
        ::User.current.allowed_to?(:add_issue_watchers, object.project)
      end

      def deletable_watchers
        ::User.current.allowed_to?(:delete_issue_watchers, object.project)
      end

      def is_private
        ::EasySetting.value(:enable_private_issues) ? object.is_private : nil
      end

      def set_is_private
        ::User.current.allowed_to?(:set_issues_private, object.project) ||
            (object.author_id == ::User.current.id && ::User.current.allowed_to?(:set_own_issues_private, object.project))
      end

      def manage_subtasks
        ::User.current.allowed_to?(:manage_subtasks, object.project)
      end

      def private_notes_enabled
        ::User.current.allowed_to?(:set_notes_private, object.project)
      end

      def time_entries_comment_required
        roles = ::User.current.roles_for_project(object.project)
        ::EasyGlobalTimeEntrySetting.value(:required_time_entry_comments, roles)
      end

    end
  end
end

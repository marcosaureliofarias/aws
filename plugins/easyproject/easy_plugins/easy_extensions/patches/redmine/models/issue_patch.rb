require 'easy_extensions/easy_mail_template_issue'

module EasyPatch
  module IssuePatch

    def self.included(base)
      base.extend(ClassMethods)
      base.include(InstanceMethods)
      base.include(ActionView::Helpers::DateHelper)
      base.include(ActionView::Helpers::TagHelper)

      base.class_eval do

        belongs_to :activity, :class_name => 'TimeEntryActivity'
        belongs_to :easy_closed_by, :class_name => 'User'
        belongs_to :easy_last_updated_by, :class_name => 'User'
        has_many :easy_issue_timers, :dependent => :destroy
        has_many :easy_favorites, :as => :entity
        has_many :favorited_by, lambda { distinct }, :through => :easy_favorites, :source => :user, :dependent => :destroy
        has_many :easy_entity_activities, :as => :entity, :dependent => :destroy
        # it is reordered by class method
        has_many :used_in_repositories, lambda { distinct }, :through => :changesets, :source => :repository
        has_many :related_easy_entity_assignments, as: :entity_to, class_name: 'EasyEntityAssignment'

        has_one :easy_report_issue_status, :dependent => :destroy

        scope :non_templates, lambda { joins(:project).where(:projects => { :easy_is_easy_template => false }) }
        scope :templates, lambda { joins(:project).where(:projects => { :easy_is_easy_template => true }) }

        scope :opened, lambda { joins(:status).where({ IssueStatus.table_name => { :is_closed => false } }) }
        scope :closed, lambda { joins(:status).where({ IssueStatus.table_name => { :is_closed => true } }) }
        scope :overdue, lambda { where("(#{self.table_name}.easy_due_date_time IS NOT NULL AND #{self.table_name}.easy_due_date_time < ?) OR (#{self.table_name}.due_date IS NOT NULL AND #{self.table_name}.due_date < ?)", Time.now, Date.today) }

        scope :like, lambda { |*args| where(Issue.send(:search_tokens_condition, [:subject, :id].map { |n| "#{self.table_name}.#{n}" }, Array(args).reject(&:blank?), false)) }

        html_fragment :description, :scrub => :strip

        searchable_options[:columns] << "#{table_name}.easy_email_to" << "#{table_name}.easy_email_cc"
        searchable_options[:scope]         = lambda { |options| options[:open_issues] ? self.non_templates.open : self.non_templates.all }
        searchable_options[:title_columns] = ['subject', "#{table_name}.id"]
        searchable_options[:preload] << :attachments << :journals << { tracker: :custom_fields } << { custom_values: :custom_field }

        event_options[:title] = Proc.new do |issue|
          s = ''
          s << "##{issue.id}: " if EasySetting.value('show_issue_id')
          s + "#{issue.tracker}: #{issue.subject}"
        end

        acts_as_taggable_on :tags

        acts_as_easy_journalized :non_journalized_columns          => %w(root_id easy_level easy_external_id easy_last_updated_by_id
                                 easy_repeat_settings easy_next_start easy_status_updated_on easy_reopen_at easy_closed_by_id closed_on easy_due_date_time),
                                 :format_detail_boolean_columns    => ['easy_is_repeating'],
                                 :format_detail_time_columns       => [],
                                 :format_detail_reflection_columns => [],
                                 :important_columns                => ['assigned_to_id', 'priority_id', 'status_id']

        include EasyPatch::Acts::Repeatable
        acts_as_easy_repeatable

        acts_as_easy_entity_replacable_tokens :easy_query_class => EasyIssueQuery, :token_prefix => 'task'

        acts_as_user_readable

        set_associated_query_class EasyIssueQuery

        # set scope default activities(sidebar)
        # easy_activity_options[:type][:user_scope] => Proc.new { |user, scope| scope.where ... }
        # :type => 'issues' .. determines for which type the options is, Journal is for multiple types
        self.activity_provider_options[:easy_activity_options] = {
            easy_event_type_name => {
                :user_scope => Proc.new { |user, scope| scope.joins("LEFT JOIN #{Watcher.table_name} ON #{Watcher.table_name}.watchable_type='Issue' AND #{Watcher.table_name}.watchable_id=#{Issue.table_name}.id").where("#{Watcher.table_name}.user_id = ? OR #{Issue.table_name}.author_id = ? OR #{Issue.table_name}.assigned_to_id = ?", user.id, user.id, user.id) }
            }
        }
        self.activity_provider_options[:update_timestamp]      = "#{table_name}.updated_on"

        include EasyExtensions::EasyInlineFragmentStripper
        strip_inline_images :description

        delegate :easy_type, :easy_type=, :private_easy_type, :private_easy_type=, :to => :current_journal, :allow_nil => true

        attr_reader :issue_move_to_project_errors, :copied_from, :copied_issue_ids
        attr_accessor :relation, :mass_operations_in_progress, :send_to_external_mails, :attributes_for_descendants, :update_repeat_entity_attributes, :copy_notes_to_parent, :without_notifications, :notification_sent, :skip_workflow, :assignee_is_not_project_member
        attr_reader :should_send_invitation_update

        delete_safe_attribute 'custom_field_values'
        safe_attributes 'author_id', 'custom_field_values',
                        :if => lambda { |issue, user| issue.new_record? || issue.attributes_editable?(user) }
        safe_attributes 'activity_id',
                        :if => lambda { |issue, user| issue.project && issue.project.fixed_activity? }

        delete_safe_attribute 'watcher_user_ids'
        safe_attributes 'watcher_user_ids', 'watcher_group_ids',
                        :if => lambda { |issue, user| user.allowed_to?(:add_issue_watchers, issue.project) }

        delete_safe_attribute 'estimated_hours'
        safe_attributes 'estimated_hours', :if => lambda { |issue, user| issue.attributes_editable?(user) && user.allowed_to?(:view_estimated_hours, issue.project) }

        safe_attributes 'parent_issue_id',
                        :if => lambda { |issue, user| issue.attributes_editable?(user) && user.allowed_to?(:manage_subtasks, issue.project) }

        safe_attributes 'easy_type', 'easy_distributed_tasks'

        safe_attributes 'easy_due_date_time', 'easy_start_date_time', 'send_to_external_mails', 'update_repeat_entity_attributes', 'copy_notes_to_parent', 'without_notifications'

        safe_attributes 'relation', if: lambda { |issue, user| user.allowed_to?(:manage_issue_relations, issue.project) }

        safe_attributes 'project_id', 'tracker_id', 'status_id', 'category_id', 'assigned_to_id',
                        'priority_id', 'fixed_version_id', 'subject', 'description', 'start_date', 'due_date', 'done_ratio',
                        'custom_field_values', 'custom_fields', 'lock_version', 'notes', 'tag_list', :if => lambda { |issue, user| issue.attributes_editable?(user) }

        safe_attributes 'easy_email_to', 'easy_email_cc'

        accepts_nested_attributes_for :easy_entity_activities, reject_if: :all_blank, allow_destroy: true

        before_validation :create_issue_relations
        before_validation :set_default_fixed_activity, :if => Proc.new { |issue| !issue.activity_id && issue.project&.fixed_activity? }

        validates_length_of :easy_email_to, :easy_email_cc, :maximum => 2048
        validates :easy_email_to, presence: true, if: -> { send_to_external_mails == '1' }, on: :update
        validates :easy_email_to, multiple_email_addresses: true, if: proc { |issue| issue.new_record? || issue.easy_email_to_changed? }
        validates :easy_email_cc, multiple_email_addresses: true, if: proc { |issue| issue.new_record? || issue.easy_email_cc_changed? }
        validates :activity_id, :presence => true, :if => Proc.new { |issue| issue.project && issue.project.fixed_activity? }
        validates :is_private, :inclusion => { :in => [true, false] }
        validate :validate_do_not_allow_close_if_subtasks_opened
        validate :validate_do_not_allow_close_if_no_attachments
        validate :validate_easy_distributed_task, if: proc { |issue| issue.tracker&.easy_distributed_tasks? }
        validate :validate_easy_distributed_tasks_attributes, if: proc { |issue| issue.tracker&.easy_distributed_tasks? && !issue.copied_from }, on: :create
        validate :validate_assignee
        validates :due_date, after_date: :start_date
        validates :start_date, after_date: :soonest_start

        before_save :set_percent_done, :update_easy_closed_by
        before_save :update_easy_status_updated_on, :if => Proc.new { |issue| issue.status_id_changed? || issue.new_record? }
        before_save :set_easy_last_updated_by_id

        after_update :remove_watchers, :if => Proc.new { |issue| issue.saved_change_to_project_id? }
        after_save :move_fixed_version_effective_date_if_needed
        after_save :close_children, :if => Proc.new { |issue| EasySetting.value(:close_subtask_after_parent) }
        after_save :save_easy_distributed_tasks
        after_save :copy_notes_to_parent_task, :if => Proc.new { |issue| issue.copy_notes_to_parent && EasySetting.value(:issue_copy_notes_to_parent, issue.project_id) }
        after_save :journal_to_parent_task_if_child_changed, :if => Proc.new { |issue| issue.saved_change_to_parent_id? }
        after_save :set_notify_descendants, :if => Proc.new { |issue| issue.root? && EasySetting.value(:issue_copy_notes_to_parent, issue.project_id) }

        alias_method_chain :validate_required_fields, :easy_extensions
        alias_method_chain :tracker=, :easy_extensions
        alias_method_chain :status=, :easy_extensions
        alias_method_chain :after_create_from_copy, :easy_extensions
        alias_method_chain :assignable_users, :easy_extensions
        alias_method_chain :cache_key, :easy_extensions
        alias_method_chain :css_classes, :easy_extensions
        alias_method_chain :copy_from, :easy_extensions
        alias_method_chain :editable?, :easy_extensions
        alias_method_chain :deletable?, :easy_extensions
        alias_method_chain :attributes_editable?, :easy_extensions
        alias_method_chain :journalized_attribute_names, :easy_extensions
        alias_method_chain :new_statuses_allowed_to, :easy_extensions
        alias_method_chain :notified_users, :easy_extensions
        alias_method_chain :overdue?, :easy_extensions
        alias_method_chain :read_only_attribute_names, :easy_extensions
        alias_method_chain :recalculate_attributes_for, :easy_extensions
        alias_method_chain :required_attribute_names, :easy_extensions
        alias_method_chain :relations, :easy_extensions
        alias_method_chain :safe_attributes=, :easy_extensions
        alias_method_chain :send_notification, :easy_extensions
        alias_method_chain :to_s, :easy_extensions
        alias_method_chain :validate_issue, :easy_extensions
        alias_method_chain :after_project_change, :easy_extensions
        alias_method_chain :visible?, :easy_extensions
        alias_method_chain :workflow_rule_by_attribute, :easy_extensions
        alias_method_chain :available_custom_fields, :easy_extensions
        alias_method_chain :reload, :easy_extensions
        alias_method_chain :allowed_target_trackers, :easy_extensions

        class << self

          alias_method_chain :count_and_group_by, :easy_extensions
          alias_method_chain :cross_project_scope, :easy_extensions
          alias_method_chain :self_and_descendants, :easy_extensions
          alias_method_chain :visible_condition, :easy_extensions
          alias_method_chain :allowed_target_trackers, :easy_extensions

          def by_custom_field(cf, project)
            count_and_group_by_custom_field(cf, { :project => project })
          end

          def by_custom_fields(project)
            reported_cf = Hash.new

            cfs = IssueCustomField.where(:is_for_all => true, :field_format => EasyExtensions.reportable_issue_cfs)
            cfs += project.issue_custom_fields.where(:field_format => EasyExtensions.reportable_issue_cfs)
            cfs.uniq!

            cfs.each_with_index do |i, index|
              data                      = {
                  :reports => by_custom_field(i, project),
                  :name    => i.name
              }
              reported_cf["cf_#{i.id}"] = data
            end

            return reported_cf
          end

          def by_unassigned_to(project)
            Issue.connection.select_all("SELECT
           s.id AS status_id,
           s.is_closed AS closed,
           NULL AS assigned_to_id,
           count(issues.id)AS total
           FROM
           #{Issue.table_name},
           #{Project.table_name},
           #{IssueStatus.table_name} s
           WHERE
           #{Issue.table_name}.status_id = s.id
           AND #{Issue.table_name}.assigned_to_id IS NULL
           AND #{Issue.table_name}.project_id = #{Project.table_name}.id
           and #{visible_condition(User.current, :project => project)}
           GROUP BY
           s.id,
           s.is_closed")
          end

          def update_from_gantt(data)
            unsaved_issues           = []
            unsaved_versions         = []
            possible_unsaved_issue   = nil
            possible_unsaved_version = nil
            (data['projects']['project']['task'].kind_of?(Array) ? data['projects']['project']['task'] : [data['projects']['project']['task']]).each do |gantt_data|
              if gantt_data['childtasks']
                # milestone
                possible_unsaved_version = Version.update_version_from_gantt_data(gantt_data)
                unsaved_versions << possible_unsaved_version if possible_unsaved_version
                (gantt_data['childtasks']['task'].kind_of?(Array) ? gantt_data['childtasks']['task'] : [gantt_data['childtasks']['task']]).each do |child_data|
                  possible_unsaved_issue = self.update_issue_from_gantt_data(child_data)
                  unsaved_issues << possible_unsaved_issue if possible_unsaved_issue
                end
              else
                possible_unsaved_issue = self.update_issue_from_gantt_data(gantt_data)
                unsaved_issues << possible_unsaved_issue if possible_unsaved_issue
              end
            end
            { :unsaved_issues => unsaved_issues, :unsaved_versions => unsaved_versions }
          end

          def parse_gantt_date(date_string)
            if date_string.match('\d{4},\d{1,2},\d{1,2}')
              Date.strptime(date_string, '%Y,%m,%d')
            end
          end

          def count_and_group_by_custom_field(cf, options)
            project = options.delete(:project)
            ActiveRecord::Base.connection.select_all("
              SELECT s.id as status_id, s.is_closed as closed, j.value as cf_#{cf.id}, count(#{Issue.table_name}.id) as total
              FROM #{Issue.table_name}
              JOIN #{CustomValue.table_name} j ON j.customized_id = #{Issue.table_name}.id AND j.customized_type = 'Issue'
              JOIN #{Project.table_name} ON #{Project.table_name}.id = #{Issue.table_name}.project_id
              JOIN #{IssueStatus.table_name} s ON s.id = #{Issue.table_name}.status_id
              WHERE
              j.custom_field_id = #{cf.id}
              AND #{Issue.visible_condition(User.current, :project => project)}
              GROUP BY s.id, s.is_closed, j.value
              ")
          end


          # used in workflow_rule_by_attribute as cache of fields_with_roles
          def non_visible_custom_field_with_roles
            RequestStore.store['issue_custom_fields_by_role'] ||=
                IssueCustomField.where(:visible => false).joins(:roles).pluck(:id, 'role_id').inject({}) do |memo, (cf_id, role_id)|
                  memo[cf_id] ||= []
                  memo[cf_id] << role_id
                  memo
                end
          end

          def css_icon
            'icon icon-tracker'
          end

          # loads available custom field ids to cache
          # it needs two sql queries.
          # first query load custom_fields for all projects
          # second query load custom_fields, wich are not for all projects, if project_ids is given, than this query is limited only for those projects
          # both queries are categorized by tracker_id
          # the result in format {<project_id1> => {<tracker_id1>=>[<cf_id1>, <cf_id2>]}} is saved to request store
          # then all issue custom fields are retrieved to array.
          # if available custom_fields are requested for projec and tracker, only we need to do is retrieve result[project.id][tracker.id] ids and map them to custom fields.
          # TODO: wouldn't be bit faster first query per tracker second for projects and than & on retrieve?
          def load_available_custom_fields_cache(project_ids = nil)
            RequestStore.store['issue_available_custom_fields_loaded_for'] ||= []
            return if project_ids && project_ids.empty?
            return if project_ids && (project_ids_to_load = ((project_ids || []) - RequestStore.store['issue_available_custom_fields_loaded_for'])).empty?
            if project_ids.nil? || RequestStore.store['issue_available_custom_fields'].nil?
              q = "SELECT cft.tracker_id, #{CustomField.quoted_table_name}.id "
              q << "FROM #{CustomField.quoted_table_name} "
              q << "  INNER JOIN #{table_name_prefix}custom_fields_trackers#{table_name_suffix} cft ON cft.custom_field_id = #{CustomField.quoted_table_name}.id "
              q << "WHERE #{CustomField.quoted_table_name}.type IN ('IssueCustomField') AND #{CustomField.quoted_table_name}.disabled = #{CustomField.connection.quoted_false}"
              q << "  AND #{CustomField.quoted_table_name}.is_for_all = #{CustomField.connection.quoted_true}"
              for_all                                             = CustomField.connection.select_rows(q).each_with_object({}) do |row, res|
                res[row.first.to_i] ||= []
                res[row.first.to_i] << row.second.to_i
              end
              RequestStore.store['issue_available_custom_fields'] = Hash.new { |h, k| h[k] = for_all.deep_dup }
            end

            q = "SELECT cfp.project_id, cft.tracker_id, #{CustomField.quoted_table_name}.id "
            q << "FROM #{CustomField.quoted_table_name} "
            q << "  INNER JOIN #{table_name_prefix}custom_fields_projects#{table_name_suffix} cfp ON cfp.custom_field_id = #{CustomField.quoted_table_name}.id "
            q << "  INNER JOIN #{table_name_prefix}custom_fields_trackers#{table_name_suffix} cft ON cft.custom_field_id = #{CustomField.quoted_table_name}.id "
            q << "WHERE #{CustomField.quoted_table_name}.type IN ('IssueCustomField') AND #{CustomField.quoted_table_name}.disabled = #{CustomField.connection.quoted_false} "
            q << "  AND #{CustomField.quoted_table_name}.is_for_all = #{CustomField.connection.quoted_false} "
            q << "  AND cfp.project_id IN (#{(project_ids_to_load).join(', ')})" if project_ids_to_load
            CustomField.connection.select_rows(q).each_with_object(RequestStore.store['issue_available_custom_fields']) do |row, cache|
              cache[row.first.to_i][row.second.to_i] ||= []
              cache[row.first.to_i][row.second.to_i] << row.last.to_i
            end

            RequestStore.store['all_issue_custom_fields_by_id']            ||= IssueCustomField.with_group.sorted.to_a
            RequestStore.store['issue_available_custom_fields_loaded_for'] |= project_ids ? project_ids : Project.all.pluck(:id)
          end

          def available_custom_fields_cache
            RequestStore.store['issue_available_custom_fields']
          end

          def load_workflow_rules(issues)
            return if RequestStore.store["#{WorkflowPermission.name}_workflow_loaded"]
            RequestStore.store["#{WorkflowPermission.name}_workflow_loaded"] = true
            workflow_permissions                                             = WorkflowPermission.where(:tracker_id => issues.map(&:tracker_id).uniq, :old_status_id => issues.map(&:status_id).uniq).to_a

            result              = {}
            role_ids_by_project = {}
            issues.map(&:project).uniq.each do |project|
              role_ids_by_project[project.id] = project.roles_for_workflow(User.current).map(&:id)
              result[project.id]              = workflow_permissions.inject({}) do |h, wp|
                h[wp.old_status_id]                ||= {}
                h[wp.old_status_id][wp.tracker_id] ||= {}
                if role_ids_by_project[project.id].include?(wp.role_id)
                  h[wp.old_status_id][wp.tracker_id][wp.field_name]             ||= {}
                  h[wp.old_status_id][wp.tracker_id][wp.field_name][wp.role_id] = wp.rule
                end
                h
              end
            end
            result.each do |project_id, by_status|
              by_status.each do |status_id, by_tracker|
                by_tracker.each do |tracker_id, rules_by_role|
                  store_key                     = "#{WorkflowPermission.name}_rules_by_status_id_s#{status_id}_t#{tracker_id}_r#{role_ids_by_project[project_id].join('-')}"
                  RequestStore.store[store_key] ||= rules_by_role
                end
              end
            end
          end

          def available_custom_fields_from_cache(project_id, tracker_id)
            if RequestStore.store['issue_available_custom_fields'] && (!RequestStore.store['issue_available_custom_fields_loaded_for'] || RequestStore.store['issue_available_custom_fields_loaded_for'].include?(project_id))
              ids = RequestStore.store['issue_available_custom_fields'][project_id][tracker_id]
              ids && RequestStore.store['all_issue_custom_fields_by_id'].select { |cf| ids.include?(cf.id) } || []
            end
          end

          def load_visible_total_estimated_hours(issues, user = User.current)
            if issues.any?
              hours_by_issue_id = Project.by_permission(user, :view_estimated_hours).joins(:issues).
                  joins("JOIN #{Issue.table_name} parent ON parent.root_id = #{Issue.table_name}.root_id" +
                            " AND parent.lft <= #{Issue.table_name}.lft AND parent.rgt >= #{Issue.table_name}.rgt").
                  where("parent.id IN (?)", issues.map(&:id)).group("parent.id").sum('issues.estimated_hours')
              issues.each do |issue|
                issue.instance_variable_set "@total_estimated_hours", (hours_by_issue_id[issue.id] || 0.0)
              end
            end
          end

        end

        def validate_change_assignee(new_assigned_to_id)
          new_assigned_to_id = new_assigned_to_id.to_i
          return unless new_assigned_to_id.positive? # assignee is unassigned

          if !assignable_users.any? { |user| user.id == new_assigned_to_id }
            self.assignee_is_not_project_member = true
          end
        end

        def validate_assignee
          if assignee_is_not_project_member
            errors.add :assigned_to_id, l(:error_user_is_not_project_member)
          end
          if !new_record? && assigned_to_id_changed? && User.current.limit_assignable_users_for_project?(project) && [author_id, User.current.id].exclude?(assigned_to_id)
            errors.add :assigned_to_id, l(:error_user_is_not_allowed)
          end
        end

        # reorders association
        def used_in_repositories
          super.reorder(nil)
        end

        def parent_issue
          @parent_issue
        end

        def parent_project
          @parent_project ||= self.project.parent_project if self.project
        end

        def parent_category
          @parent_category ||= self.category.parent if self.category
        end

        def root_category
          @root_category ||= self.category.root if self.category
        end

        def main_project
          @main_project ||= self.project.main_project if self.project
        end

        def remaining_timeentries
          @remaining_timeentries ||= ((self.estimated_hours || 0.0) - self.spent_hours)
        end

        def total_remaining_timeentries
          @total_remaining_timeentries ||= ((self.total_estimated_hours || 0.0) - self.total_spent_hours)
        end

        def spent_estimated_timeentries
          @spent_estimated_timeentries ||= begin
            if self.estimated_hours && self.estimated_hours > 0
              ((self.spent_hours / self.estimated_hours) * 100).to_i
            else
              0.0
            end
          end
        end

        def total_spent_estimated_timeentries
          @total_spent_estimated_timeentries ||= begin
            if self.total_estimated_hours && self.total_estimated_hours > 0
              ((self.total_spent_hours / self.total_estimated_hours) * 100).to_i
            else
              0.0
            end
          end
        end

        def open_duration_in_hours
          self.closed_on - self.created_on if self.closed_on
        end

        def status_time_current
          (Time.now - self.easy_status_updated_on) / 1.minute if self.easy_status_updated_on
        end

        def last_user_assigned_to
          return @last_user_assigned_to unless @last_user_assigned_to.nil?

          t               = Journal.arel_table
          journals_detail = JournalDetail.joins(:journal).where(t[:journalized_type].eq(self.class.base_class.name).and(t[:journalized_id].eq(self.id))).where(:prop_key => 'assigned_to_id').order(Arel.sql(t[:created_on].desc.to_sql)).first

          if journals_detail
            last_assigned_to = Principal.where(:id => journals_detail.old_value).last if journals_detail.old_value
          else
            last_assigned_to = self.assigned_to
          end
          @last_user_assigned_to = last_assigned_to
        end

        def second_to_last_user_assigned_to
          return @second_to_last_user_assigned_to unless @second_to_last_user_assigned_to.nil?

          t               = Journal.arel_table
          journals_detail = JournalDetail.joins(:journal).where(t[:journalized_type].eq(self.class.base_class.name).and(t[:journalized_id].eq(self.id))).where(:prop_key => 'assigned_to_id').order(Arel.sql(t[:created_on].desc.to_sql)).second

          if journals_detail
            last_assigned_to = Principal.where(:id => journals_detail.old_value).last if journals_detail.old_value
          else
            last_assigned_to = self.assigned_to
          end
          @second_to_last_user_assigned_to = last_assigned_to
        end

        def build_issue_relations_from_params(params)
          if params && params['issue_to_id']
            Issue.where(:id => params['issue_to_id']).each do |issue_to|
              relations_from.build(:relation_type => params['relation_type'], :delay => params['relation_delay'], :issue_from => self, :issue_to => issue_to)
            end
          end
        end

        def to_s_with_id
          suffix = self.easy_is_repeating? ? (' ' << l(:label_easy_issue_subject_reccuring_suffix)) : ''
          "##{self.id} - #{self.subject}#{suffix}"
        end

        def to_s_without_id
          suffix = self.easy_is_repeating? ? (' ' << l(:label_easy_issue_subject_reccuring_suffix)) : ''
          "#{self.subject}#{suffix}"
        end

        def has_relations_to_copy?(with_descendants = false)
          issues = with_descendants ? self.self_and_descendants.visible.reorder(nil) : [self]
          Issue.load_relations(issues)
          issues.each do |issue|
            issue.relations.each do |relation|
              unless IssueRelation::NOT_COPIED_RELATIONS.include?(relation.relation_type)
                return true
              end
            end
          end
          false
        end

        def get_notified_users_for_issue_new(journal = current_journal)
          user_from_journal = journal&.notified_users || []

          notified_users | notified_watchers | user_from_journal # | watchers_from_journal
        end

        def get_notified_users_for_issue_edit(journal = current_journal)
          users = get_notified_users_for_issue_new(journal)
          users.select! do |user|
            (journal.notes? || journal.notify_visible_details(user).any?) && (!journal.private_notes? || (journal.private_notes? && user.allowed_to?(:view_private_notes, project)))
          end
          users
        end

        def get_easy_mail_template
          EasyExtensions::EasyMailTemplateIssue
        end

        def get_status_time(id)
          self.easy_report_issue_status.get_status_time(self.easy_report_issue_status.get_idx(id)) if id && self.easy_report_issue_status
        end

        def get_status_count(id)
          self.easy_report_issue_status.get_status_count(self.easy_report_issue_status.get_idx(id)) if id && self.easy_report_issue_status
        end

        def easy_distributed_tasks
          @easy_distributed_tasks.blank? ? [{}] : @easy_distributed_tasks
        end

        def easy_distributed_tasks=(tasks)
          return if !self.new_record? || self.tracker.nil? || !self.tracker.easy_distributed_tasks?
          if tasks.is_a?(Hash) && tasks.has_key?(:assigned_to_ids)
            @easy_distributed_tasks = []
            tasks[:assigned_to_ids].each_with_index do |assigned_to_id, i|
              @easy_distributed_tasks << {
                  :assigned_to_id => assigned_to_id,
                  :est            => tasks[:ests].try(:at, i),
              }
            end
          else
            @easy_distributed_tasks = nil
          end
          self.build_easy_distributed_tasks
        end

        def easy_due_date_time_remaining
          if time_value = easy_due_date_time.try(:to_time)
            (time_value - Time.now) / 1.hour.to_f
          end
          time_value
        end

        def easy_merge_to(issue_to_merge, status)
          #
          # selected entities to copy
          # for example: related entities is not necessary to copy
          #
          entities_types_to_copy = { 'Journal' => 1, 'Attachment' => 1 }

          issue_to_merge.reload
          # merge custom values
          custom_values.each do |v|
            easy_merge_custom_value(issue_to_merge, v)
          end
          Mailer.with_deliveries(false) do
            issue_to_merge.save
          end

          associations_to_merge = [:attachments, :relations_from, :relations_to, :journals, :watchers]

          associations_to_merge.each do |association|
            assoc      = association.to_s
            reflection = Issue.reflections[assoc]

            case reflection.macro
            when :has_and_belongs_to_many, :has_many
              entities = self.send(assoc)
              next if entities.blank?

              entities.each do |r|
                duplicate = easy_duplicate_entity_for_merge(r, entities_types_to_copy)
                begin
                  Mailer.with_deliveries(false) do
                    issue_to_merge.send("#{assoc}").send('<<', duplicate)
                  end
                rescue StandardError => e
                  # association already contains duplicate object
                  # read only associations
                end
              end
            end
          end

          self.reload
          self.status = status
          Mailer.with_deliveries(false) do
            self.save
          end
        end

        def easy_duplicate_entity_for_merge(original, entities_types_to_copy)
          duplicate = original
          if entities_types_to_copy[original.class.name]
            begin
              duplicate = original.dup
              duplicate.created_on = original.created_on
            rescue StandardError => e
              # cannot duplicate object, use original instead
            end
          end
          duplicate
        end

        def easy_merge_custom_value(original_issue, custom_value_to_merge)
          case custom_value_to_merge.custom_field.format
          when EasyExtensions::FieldFormats::Email, Redmine::FieldFormat::StringFormat, Redmine::FieldFormat::TextFormat
            easy_merge_text_custom_value(original_issue, custom_value_to_merge, ',')
          end
        end

        def easy_merge_text_custom_value(original_issue, custom_value_to_merge, separator = nil)
          original_cv = original_issue.custom_value_for(custom_value_to_merge.custom_field_id)
          if (original_cv)
            if separator
              new_value = (original_cv.value.to_s.split(separator) + custom_value_to_merge.value.to_s.split(separator)).uniq.join(separator)
            else
              new_value = original_cv.value.to_s + custom_value_to_merge.value.to_s
            end

            original_issue.custom_field_values = { custom_value_to_merge.custom_field.id.to_s => new_value.to_s }
          else
            original_issue.custom_field_values = { custom_value_to_merge.custom_field.id.to_s => custom_value_to_merge.value.to_s }
          end
        end

        def build_easy_distributed_tasks
          @easy_distributed_tasks_to_save = []
          self.easy_distributed_tasks.each do |data|
            self.build_easy_distributed_task(data) if data[:assigned_to_id].present? && data[:est].present?
          end
        end

        def build_easy_distributed_task(data)
          task                 = Issue.new
          task.attributes      = self.attributes.dup.slice('project_id',
                                                           'author_id', 'activity_id', 'priority_id', 'description', 'status_id', 'start_date', 'due_date')

          task.tracker         = distributed_tracker if self.project
          assigned_to          = User.find_by_id(data[:assigned_to_id])
          task.subject         = self.subject.dup << (assigned_to ? (' ' << assigned_to.login) : '')
          task.estimated_hours = data[:est]
          task.assigned_to_id  = data[:assigned_to_id]
          @easy_distributed_tasks_to_save << task
        end

        def is_favorited?(user = nil)
          user ||= User.current

          self.easy_favorites.where(:user_id => user.id).exists?
        end

        def save_easy_distributed_tasks
          if @easy_distributed_tasks_to_save
            @easy_distributed_tasks_to_save.each do |st|
              st.custom_values   = self.custom_values.map { |v| cloned_v = v.dup; cloned_v.customized = st; cloned_v }
              st.parent_issue_id = self.id
              st.save
            end
            @easy_distributed_tasks_to_save = nil
          end
        end

        def close_children
          if self.closed? && self.children.any?
            new_attributes                           = { status_id: self.status_id, easy_closed_by_id: User.current.id, easy_status_updated_on: Time.now, closed_on: Time.now }
            new_attributes[:easy_last_updated_by_id] = current_journal.try(:user_id) || User.current.id
            new_attributes[:done_ratio]              = 100 if EasySetting.value('issue_set_done_after_close')
            self.descendants.update_all(new_attributes)
          end
        end

        def update_easy_closed_by
          if closing? || (new_record? && closed?)
            self.easy_closed_by = User.current
          end
        end

        def update_easy_status_updated_on
          self.easy_status_updated_on = Time.now
        end

        def validate_do_not_allow_close_if_subtasks_opened
          validate_issue_when_close
          if parent_issue_id
            validate_issue_when_add_to_parent
          end
        end

        def validate_issue_when_close
          if closed? && !leaf? && tracker&.easy_do_not_allow_close_if_subtasks_opened?
            if (unclosed = descendants
                            .joins(:status)
                            .where(IssueStatus.arel_table[:is_closed].eq(false))).exists?
              errors.add :base, l(:error_cannot_close_issue_due_to_subtasks, issues: ('\n' + unclosed.to_a.collect { |i| i.to_s }.join('\n'))).html_safe
            end
          end
        end

        def validate_issue_when_add_to_parent
          if !closed? && parent_issue&.closed? && parent_issue&.tracker&.easy_do_not_allow_close_if_subtasks_opened?
            errors.add :base, l(:error_cannot_add_subtask_to_parent_due_to_settings)
          end
        end

        private :validate_do_not_allow_close_if_subtasks_opened, :validate_issue_when_close, :validate_issue_when_add_to_parent

        def create_issue_relations
          build_issue_relations_from_params(relation) if new_record?
        end

        def validate_do_not_allow_close_if_no_attachments
          return if !self.tracker || !self.tracker.respond_to?(:easy_do_not_allow_close_if_no_attachments)
          return if !self.status || !self.status.is_closed?
          return unless self.tracker.easy_do_not_allow_close_if_no_attachments?
          return if self.has_attachments? || self.saved_attachments.any?

          errors.add :base, l(:error_cannot_close_issue_due_to_no_attachments)
        end

        def validate_easy_distributed_task
          if distributed_tracker
            errors.add :base, l(:error_parent_issue_id_is_disabled) if distributed_tracker.disabled_core_fields.include?('parent_issue_id')
          else
            errors.add :base, l(:error_cannot_create_distributed_tasks_without_tracker)
          end
        end

        def validate_easy_distributed_tasks_attributes
          errors.add :base, l(:error_distributed_tasks_blank_attributes) if easy_distributed_tasks.any? { |attr_hash| attr_hash.empty? || attr_hash.values.any?(&:blank?) }
        end

        def distributed_tracker
          @distributed_tracker ||= self.project.trackers.where(:easy_distributed_tasks => false).first if self.project
        end

        def remove_watchers #removes watchers if user is not a member of new project
          self.watcher_users = (self.project.users & self.watcher_users)
        end

        def move_fixed_version_effective_date_if_needed
          if EasySetting.value('milestone_effective_date_from_issue_due_date') && self.fixed_version && self.fixed_version.effective_date && self.due_date
            if self.fixed_version.effective_date < self.due_date
              journal = self.fixed_version.init_system_journal(User.current, l(:text_milestone_effective_date_from_issue, :issue => self.id))
              self.fixed_version.update_attributes(:effective_date => self.due_date)
            end
          end
        end

        def set_percent_done
          return if !EasySetting.value('issue_set_done_after_close')
          return if self.done_ratio == 100

          if self.status_id_changed? && self.status && self.status.is_closed?
            self.done_ratio = 100
          end
        end

        def visible_to_user?(user)
          self.author_id == user.id || self.author_id_was == user.id || user.is_or_belongs_to?(assigned_to) || user.is_or_belongs_to?(previous_assignee)
        end

        private :visible_to_user?

        def easy_journal_option(option, journal)
          case option
          when :title
            new_status = journal.new_status
            "#{journal.issue.tracker} ##{journal.issue.id}#{new_status ? " (#{new_status})" : nil}: #{journal.issue.subject}"
          when :type
            new_status = journal.new_status
            if new_status
              new_status.is_closed? ? 'issue-closed' : 'issue-edit'
            else
              'issue-note'
            end
          when :url
            { :controller => 'issues', :action => 'show', :id => journal.issue.id, :anchor => "change-#{journal.id}" }
          end
        end

        def copy_notes_to_parent_task
          if @current_journal && @current_journal.notes.present? && (parent = self.parent)
            parent.init_journal(@current_journal.user, @current_journal.notes)
            parent.current_journal.private_notes   = @current_journal.private_notes
            parent.current_journal.is_system = @current_journal.is_system
            parent.current_journal.notify_children = true
            if parent.save
              @current_journal.notify = false
            else
              self.errors.messages.merge!(parent.errors.messages)
              self.errors.add(:base, l(:error_copy_notes_to_parent))
            end
          end
        end

        def journal_to_parent_task_if_child_changed
          if self.parent_id_before_last_save && (old_parent = Issue.find_by(id: self.parent_id_before_last_save))
            journal = old_parent.init_journal(User.current)
            journal.details << JournalDetail.new(property: 'relation', prop_key: 'subtask', old_value: self.id, value: nil)
            journal.save
          end
          if (new_parent = self.parent)
            journal = new_parent.init_journal(User.current)
            journal.details << JournalDetail.new(property: 'relation', prop_key: 'subtask', old_value: nil, value: self.id)
            journal.save
          end
        end

        def set_easy_last_updated_by_id
          self.easy_last_updated_by_id = current_journal.try(:user_id) || User.current.id
        end

        def set_default_fixed_activity
          self.activity = TimeEntryActivity.default
        end

        def easy_divided_hours
          @easy_divided_hours ||= time_entries.sum(:easy_divided_hours) || 0
        end

        def set_notify_descendants
          @current_journal.notify_children = true if @current_journal
        end

      end
    end

    module ClassMethods

      def self_and_descendants_with_easy_extensions(issues = nil)
        scope = Issue.joins("JOIN #{Issue.table_name} ancestors" +
                                " ON ancestors.root_id = #{Issue.table_name}.root_id" +
                                " AND ancestors.lft <= #{Issue.table_name}.lft AND ancestors.rgt >= #{Issue.table_name}.rgt"
        )
        scope = scope.where(:ancestors => { :id => issues.map(&:id) }) if issues.is_a?(Array)
        scope
      end

      def cross_project_scope_with_easy_extensions(project, scope = nil)
        issues_scope = cross_project_scope_without_easy_extensions(project, scope)

        if project && project.easy_is_easy_template?
          issues_scope.templates
        else
          issues_scope.non_templates
        end
      end

      def visible_condition_with_easy_extensions(user, options = {})
        Project.allowed_to_condition(user, :view_issues, options) do |role, user|
          sql = if user.id && user.logged?
                  case role.issues_visibility
                  when 'all'
                    '1=1'
                  when 'default'
                    user_ids = [user.id] + user.groups.map(&:id).compact
                    "(#{table_name}.is_private = #{connection.quoted_false} OR #{table_name}.author_id = #{user.id} OR #{table_name}.assigned_to_id IN (#{user_ids.join(',')}))"
                  when 'own'
                    user_ids = [user.id] + user.groups.map(&:id).compact
                    "(#{table_name}.author_id = #{user.id} OR #{table_name}.assigned_to_id IN (#{user_ids.join(',')}) OR EXISTS (SELECT w.id FROM #{Watcher.table_name} w WHERE w.watchable_type = 'Issue' AND w.watchable_id = #{Issue.table_name}.id AND w.user_id = #{user.id}))"
                  else
                    '1=0'
                  end
                else
                  "(#{table_name}.is_private = #{connection.quoted_false})"
                end
          unless role.permissions_all_trackers?(:view_issues)
            tracker_ids = role.permissions_tracker_ids(:view_issues)
            if tracker_ids.any?
              sql = "(#{sql} AND #{table_name}.tracker_id IN (#{tracker_ids.join(',')}))"
            else
              sql = '1=0'
            end
          end
          sql
        end
      end

      def easy_merge_and_close_issues(issues, merge_to)
        return false if issues.count == 1 && issues.first == merge_to

        issues = issues - [merge_to]
        merged = true

        close_status = IssueStatus.sorted.where(:is_closed => true).first

        merge_to_attrs               = OpenStruct.new
        merge_to_attrs.description   = merge_to.description.to_s.dup
        merge_to_attrs.easy_email_to = parse_emails(merge_to.easy_email_to)
        merge_to_attrs.easy_email_cc = parse_emails(merge_to.easy_email_cc)

        issues.each do |issue|
          merged = false if !issue.easy_merge_to(merge_to, close_status)
          Mailer.with_deliveries(false) do
            issue.init_system_journal(User.current, I18n.t(:label_merged_into, id: "##{merge_to.id}")).save
          end
          merge_to_attrs.description << easy_merge_entity_description(issue)
          merge_to_attrs.easy_email_to = parse_emails(issue.easy_email_to) unless merge_to_attrs.easy_email_to.any?
          merge_to_attrs.easy_email_cc.concat(parse_emails(issue.easy_email_to))
          merge_to_attrs.easy_email_cc.concat(parse_emails(issue.easy_email_cc))
        end

        merge_to_attrs.easy_email_cc.uniq!
        merge_to_attrs.easy_email_cc -= merge_to_attrs.easy_email_to if merge_to_attrs.easy_email_to.any?
        merge_to_attrs.easy_email_to = merge_to_attrs.easy_email_to.uniq.join(', ')
        merge_to_attrs.easy_email_cc = merge_to_attrs.easy_email_cc.join(', ')
        updated_attributes           = merge_to_attrs.to_h

        begin
          merge_to.safe_attributes = updated_attributes
          Mailer.with_deliveries(false) do
            merge_to.save
          end
        rescue ActiveRecord::StaleObjectError
          # if it is parent, it is changed during merging
          merge_to.reload
          merge_to.safe_attributes = updated_attributes
          merge_to.save
        end

        issues_in_note = issues.collect { |issue| "##{issue.id}" }.join(', ')
        merge_to.init_system_journal(User.current, I18n.t(:label_merged_from, :ids => "#{issues_in_note}")).save

        merged
      end

      def easy_merge_entity_description(merging_issue)
        "\r\n" << '-' * 60 << ' ' << I18n.t(:label_merged_from, :ids => "##{merging_issue.id}") << "\r\n" << merging_issue.description.to_s
      end

      def parse_emails(easy_emails = '')
        easy_emails&.scan(EasyExtensions::Mailer::EMAIL_REGEXP) || []
      end

      def count_and_group_by_with_easy_extensions(options)
        assoc        = reflect_on_association(options[:association])
        select_field = assoc.foreign_key

        Issue.
            visible(User.current, :project => options[:project], :with_subprojects => options[:with_subprojects]).
            joins(:status, assoc.name).
            group(:status_id, :is_closed, "#{Issue.table_name}.#{select_field}").
            count.
            map do |columns, total|
          status_id, is_closed, field_value = columns
          is_closed                         = ['t', 'true', '1'].include?(is_closed.to_s)
          {
              'status_id'  => status_id.to_s,
              'closed'     => is_closed,
              select_field => field_value.to_s,
              'total'      => total.to_s
          }
        end
      end

      def allowed_target_trackers_with_easy_extensions(project, user = User.current, current_tracker = nil)
        scope = allowed_target_trackers_without_easy_extensions(project, user, current_tracker)
        scope.where(easy_distributed_tasks: false)
      end

    end

    module InstanceMethods

      # Validates the issue against additional workflow requirements
      def validate_required_fields_with_easy_extensions
        return true if skip_workflow || (User.current.admin? && EasySetting.value('skip_workflow_for_admin', project))

        user = new_record? ? author : current_journal.try(:user)

        required_attribute_names(user).each do |attribute|
          if /^\d+$/.match?(attribute)
            attribute = attribute.to_i
            v = custom_field_values.detect {|v| v.custom_field_id == attribute }
            if v && Array(v.value).detect(&:present?).nil?
              errors.add :base, v.custom_field.name + ' ' + l('activerecord.errors.messages.blank'), attributes: ["cf_#{attribute}"]
            end
          else
            if respond_to?(attribute) && send(attribute).blank? && !disabled_core_fields.include?(attribute)
              next if attribute == 'category_id' && project.try(:issue_categories).blank?
              next if attribute == 'fixed_version_id' && assignable_versions.blank?
              errors.add attribute, :blank
            end
          end
        end
      end

      def tracker_with_easy_extensions=(tracker)
        tracker_was = self.tracker
        send :tracker_without_easy_extensions=, tracker
        if tracker != tracker_was
          @read_only_attribute_names[User.current.id] = nil if @read_only_attribute_names
          @required_attribute_names[User.current.id]  = nil if @required_attribute_names
        end
      end

      def status_with_easy_extensions=(status)
        if status != self.status
          # reassign custom field values to ensure compliance with workflow
          reassign_custom_field_values
          @read_only_attribute_names[User.current.id] = nil if @read_only_attribute_names
          @required_attribute_names[User.current.id]  = nil if @required_attribute_names
        end
        send :status_without_easy_extensions=, status
      end

      def available_custom_fields_with_easy_extensions
        self.class.available_custom_fields_from_cache(project_id, tracker_id) ||
            ((project && tracker) ? (project.all_issue_custom_fields.with_group & tracker.custom_fields.with_group) : [])
      end

      def cache_key_with_easy_extensions
        if new_record?
          'issues/new'
        else
          "issues/#{id}-#{updated_on.strftime('%Y%m%d%H%M%S')}"
        end
      end

      def after_create_from_copy_with_easy_extensions
        return unless copy? && !@after_create_from_copy_handled

        if (@copied_from.project_id == project_id || Setting.cross_project_issue_relations?) && @copy_options[:link] != false
          if @current_journal
            @copied_from.init_journal(@current_journal.user)
          end
          relation = IssueRelation.new(:issue_from => @copied_from, :issue_to => self, :relation_type => IssueRelation::TYPE_COPIED_TO)
          unless relation.save
            logger.error "Could not create relation while copying ##{@copied_from.id} to ##{id} due to validation errors: #{relation.errors.full_messages.join(', ')}" if logger
          end
        end

        @copied_issue_ids ||= { @copied_from.id => self.id }
        if !@copied_from.leaf? && @copy_options[:subtasks] != false
          copy_options = (@copy_options || {}).merge(:subtasks => false)
          attrs        = self.attributes_for_descendants
          descendants  = @copied_from.reload.descendants.reorder("#{Issue.table_name}.lft").to_a

          # moving dates
          if attrs
            attrs              = attrs.dup
            move_start_date_by = attrs.delete('start_date').days if attrs['start_date'].is_a?(Numeric)
            move_due_date_by   = attrs.delete('due_date').days if attrs['due_date'].is_a?(Numeric)
          end

          descendants.each do |child|
            # Do not copy self when copying an issue as a descendant of the copied issue
            next if child == self
            # Do not copy subtasks of issues that were not copied
            next unless @copied_issue_ids[child.parent_id]
            # Do not copy subtasks that are not visible to avoid potential disclosure of private data
            unless child.visible?
              logger.error "Subtask ##{child.id} was not copied during ##{@copied_from.id} copy because it is not visible to the current user" if logger
              next
            end
            if @copied_from.easy_is_repeating
              attributes_to_copy = (child.easy_repeat_settings['entity_attributes'] || {}).merge({ :easy_is_repeating => false, :easy_repeat_settings => nil })
              copy               = child.copy(attributes_to_copy, copy_options)
            else
              copy = Issue.new.copy_from(child, copy_options)
            end
            if @current_journal
              copy.init_journal(@current_journal.user)
            end
            # moving dates
            copy.start_date      = copy.start_date + move_start_date_by if copy.start_date && move_start_date_by
            copy.due_date        = copy.due_date + move_due_date_by if copy.due_date && move_due_date_by

            copy.safe_attributes = attrs.dup if attrs

            custom_field_values = child.custom_field_values.inject({}) { |h, v| h[v.custom_field_id.to_s] = v.value; h }
            if attrs && attrs['custom_field_values']
              cfv_from_params = attrs['custom_field_values']
              if cfv_from_params.respond_to?(:to_unsafe_h)
                cfv_from_params = cfv_from_params.to_unsafe_h
              end
              if cfv_from_params.is_a?(Hash)
                custom_field_values = custom_field_values.merge(cfv_from_params)
              end
            end
            copy.custom_field_values = custom_field_values

            copy.mass_operations_in_progress = true
            copy.author                      = author
            copy.project                     = project
            copy.parent_issue_id             = @copied_issue_ids[child.parent_id]
            copy.fixed_version_id            = nil unless child.fixed_version&.status == 'open'
            copy.assigned_to                 = nil unless child.assigned_to&.status == User::STATUS_ACTIVE
            unless copy.save
              logger.error "Could not copy subtask ##{child.id} while copying ##{@copied_from.id} to ##{id} due to validation errors: #{copy.errors.full_messages.join(', ')}" if logger
              next
            end
            @copied_issue_ids[child.id] = copy.id
          end
        end
        @after_create_from_copy_handled = true
      end

      def assignable_users_with_easy_extensions
        return @assignable_users unless @assignable_users.nil?
        user_ids = []
        user_ids << author_id if author && author.active?
        user_ids << assigned_to_id if assigned_to && (assigned_to.is_a?(User) || Setting.issue_group_assignment?)

        if project && !User.current.limit_assignable_users_for_project?(project)
          project_scope = project.assignable_users(tracker)
          if user_ids.empty?
            @assignable_users = project_scope.to_a
            return @assignable_users
          end
          user_ids.concat project_scope.reorder(nil).pluck(:id)
        end

        @assignable_users = user_ids.empty? ? [] : Principal.where(:id => user_ids).sorted.to_a
      end

      def reload_with_easy_extensions(*args)
        @assignable_users                                        = nil
        @last_user_assigned_to, @second_to_last_user_assigned_to = nil, nil
        reload_without_easy_extensions(*args)
      end

      def journalized_attribute_names_with_easy_extensions
        attrs = journalized_attribute_names_without_easy_extensions - self.class.journalized_options[:non_journalized_columns]
        attrs -= ['estimated_hours'] unless User.current.allowed_to?(:view_estimated_hours, self.project)
        attrs
      end

      def editable_with_easy_extensions?(user = User.current)
        @editable = project && project.active? && editable_without_easy_extensions?(user) if @editable.nil?
        @editable
      end

      def attributes_editable_with_easy_extensions?(user = User.current)
        return false unless project && project.active?
        if @attributes_editable.nil?
          @attributes_editable = attributes_editable_without_easy_extensions?(user) ||
              ((self.author_id == user.id) && user_tracker_permission?(user, :edit_own_issues)) ||
              ((user.is_or_belongs_to? self.assigned_to) && user_tracker_permission?(user, :edit_assigned_issue))
        end
        @attributes_editable
      end

      def safe_attributes_with_easy_extensions=(attrs, user = User.current)
        attrs                          = attrs.to_unsafe_hash if attrs.respond_to?(:to_unsafe_hash)
        @should_send_invitation_update = !!attrs.delete(:should_send_invitation_update) if attrs.is_a?(Hash)

        return unless attrs.is_a?(Hash)

        if attrs
          if !attrs['fixed_version_id'].blank? && (current_version = Version.find_by_id(attrs['fixed_version_id'])) # the version is changing
            if attrs.key?('due_date')
              attrs_due_date = begin
                attrs['due_date'].to_date;
              rescue;
                nil;
              end
            else
              attrs_due_date = self.due_date
            end
            attrs_due_date ||= current_version.due_date

            attrs['due_date'] = attrs_due_date
          end

          if self.current_journal && attrs[:without_notifications] && User.current.allowed_to?(:edit_without_notifications, self.project)
            self.current_journal.notify = false
          end
        end

        # User can change issue attributes only if he has :edit permission or if a workflow transition is allowed

        send :safe_attributes_without_easy_extensions=, attrs, user
        Redmine::Hook.call_hook(:after_safe_attributes_assigned_issue, :attrs => attrs, :user => user, :issue => self)

        @read_only_attribute_names[(user || User.current).id] = nil if @read_only_attribute_names
        @required_attribute_names[(user || User.current).id]  = nil if @required_attribute_names
      end

      def deletable_with_easy_extensions?(user = User.current)
        return false unless project && project.active?
        deletable_without_easy_extensions?(user)
      end

      def after_project_change_with_easy_extensions
        after_project_change_without_easy_extensions
      rescue ActiveRecord::Rollback
        errors.add :base, l(:error_invalid_subtasks)
        raise
      end

      def validate_issue_with_easy_extensions
        if project
          if fixed_version
            if !assignable_versions.include?(fixed_version)
              errors.add :fixed_version_id, :inclusion
            elsif reopening? && fixed_version.closed?
              errors.add :base, I18n.t(:error_can_not_reopen_issue_on_closed_version)
            end
          end

          # Checks that the issue can not be added/moved to a disabled tracker
          if project && (tracker_id_changed? || project_id_changed?)
            if tracker && !project.trackers.include?(tracker)
              errors.add :base, l(:error_no_tracker_in_project)
            end
          end
        end

        # Checks parent issue assignment
        if @invalid_parent_issue_id.present?
          errors.add :parent_issue_id, :invalid
        elsif @parent_issue
          if !valid_parent_project?(@parent_issue)
            errors.add :parent_issue_id, :invalid
          elsif (@parent_issue != parent) && (
          self.would_reschedule?(@parent_issue) ||
              @parent_issue.self_and_ancestors.any? { |a| a.relations_from.any? { |r| r.relation_type == IssueRelation::TYPE_PRECEDES && r.issue_to.would_reschedule?(self) } }
          )
            errors.add :parent_issue_id, :invalid
          elsif !new_record?
            # moving an existing issue
            if move_possible?(@parent_issue)
              # move accepted
            else
              errors.add :parent_issue_id, :invalid
            end
          end
        end

        if self.fixed_version && self.fixed_version.effective_date && self.due_date
          if self.fixed_version.effective_date < self.due_date && !EasySetting.value('milestone_effective_date_from_issue_due_date')
            ef_date = self.fixed_version.effective_date
            errors.add :base, l(:before_milestone_human_error, distance: distance_of_time_in_words(self.due_date, ef_date), effective_date: format_date(ef_date)), attributes: %w(due_date)
          end
        end

        if !EasySetting.value('project_calculate_due_date') && self.project && !self.project.due_date.blank?
          if self.due_date && self.due_date > self.project.due_date
            errors.add :base, l(:before_project_end_human_error, distance: distance_of_time_in_words(self.due_date, self.project.due_date), project_due_date: format_date(self.project.due_date)), attributes: %w(due_date)
          end
        end

        if !EasySetting.value('project_calculate_start_date') && self.project && !self.project.start_date.blank?
          if self.start_date && self.start_date < self.project.start_date
            errors.add :base, l(:after_project_start_human_error, distance: distance_of_time_in_words(self.start_date, self.project.start_date), project_start_date: format_date(self.project.start_date)), attributes: %w(start_date)
          end
        end
      end

      def visible_with_easy_extensions?(usr = nil)
        (usr || User.current).allowed_to?(:view_issues, self.project) do |role, user|
          visible = if user.logged?
                      case role.issues_visibility
                      when 'all'
                        true
                      when 'default'
                        !self.is_private? || visible_to_user?(user)
                      when 'own'
                        # `watcher_user_ids` doesn't contains watchers during creation process
                        visible_to_user?(user) || watchers.find{|w| w.user_id == user.id }
                      else
                        false
                      end
                    else
                      !self.is_private?
                    end
          unless role.permissions_all_trackers?(:view_issues)
            visible &&= role.permissions_tracker_ids?(:view_issues, tracker_id)
          end
          visible
        end
      end

      def going_invisible?(user = User.current)
        user.roles.map(&:issues_visibility).uniq == ["own"] &&
            !(self.author == user || user.is_or_belongs_to?(self.assigned_to) || self.watcher_user_ids.include?(user.id))
      end

      def css_classes_with_easy_extensions(user = User.current, lvl = nil, options = {})
        inline_editable = options[:inline_editable] != false
        css             = css_classes_without_easy_extensions(user)
        if lvl && lvl > 0
          css << ' idnt'
          css << " idnt-#{lvl}"
        end
        css << ' multieditable-container' if inline_editable

        scheme = css_scheme
        css << " scheme #{scheme}" if scheme.present?

        css
      end

      def css_scheme
        case EasySetting.value('issue_color_scheme_for')
        when 'issue_priority'
          priority.try(:easy_color_scheme)
        when 'issue_status'
          status.try(:easy_color_scheme)
        when 'tracker'
          tracker.try(:easy_color_scheme)
        end
      end

      def to_s_with_easy_extensions
        if EasySetting.value('show_issue_id', self.project_id)
          to_s_with_id
        else
          to_s_without_id
        end
      end

      def recalculate_attributes_for_with_easy_extensions(issue_id)
        if issue_id && p = Issue.find_by_id(issue_id)
          text = "#{l(:label_issue_automatic_recalculate_attributes, :issue_id => "##{self.id}")}"
          if Setting.text_formatting == 'HTML'
            text = "<p>#{text}</p>"
          end
          journal           = p.init_system_journal(User.current, text)
          something_changed = false

          if p.priority_derived?
            # priority = highest priority of open children
            # priority is left unchanged if all children are closed and there's no default priority defined
            if priority_position = p.children.open.joins(:priority).maximum("#{IssuePriority.table_name}.position")
              parent_new_priority = IssuePriority.find_by_position(priority_position)
            elsif default_priority = IssuePriority.default
              parent_new_priority = default_priority
            end
            if p.priority != parent_new_priority && parent_new_priority
              p.priority        = parent_new_priority
              something_changed = true
            end
          end

          if p.dates_derived?
            # start/due dates = lowest/highest dates of children
            parent_new_start_date = p.children.minimum(:start_date)
            parent_new_due_date   = p.children.maximum(:due_date)

            if parent_new_start_date && parent_new_due_date && parent_new_due_date < parent_new_start_date
              parent_new_start_date, parent_new_due_date = parent_new_due_date, parent_new_start_date
            end

            if parent_new_start_date != p.start_date || parent_new_due_date != p.due_date
              p.start_date      = parent_new_start_date
              p.due_date        = parent_new_due_date
              something_changed = true
            end
          end

          if p.done_ratio_derived?
            # done ratio = weighted average ratio of leaves
            unless Issue.use_status_for_done_ratio? && p.status && p.status.default_done_ratio
              child_count = p.children.count
              if child_count > 0
                average = p.children.where('estimated_hours > 0').average(:estimated_hours).to_f
                if average == 0
                  average = 1
                end
                done                  = p.children.joins(:status).
                    sum(Arel.sql("COALESCE(CASE WHEN estimated_hours > 0 THEN estimated_hours ELSE NULL END, #{average}) " +
                                     "* (CASE WHEN is_closed = #{self.class.connection.quoted_true} THEN 100 ELSE COALESCE(done_ratio, 0) END)")).to_f
                progress              = done / (average * child_count)
                parent_new_done_ratio = progress.round

                if parent_new_done_ratio != p.done_ratio
                  p.done_ratio      = parent_new_done_ratio
                  something_changed = true
                end
              end
            end
          end

          if something_changed
            # ancestors will be recursively updated
            Redmine::Hook.call_hook(:model_issue_before_automatic_change_from_subtask, { issue: p, journal: journal, subtask: self })
            p.mass_operations_in_progress    = true
            self.mass_operations_in_progress = true
            p.save(:validate => false)
          end
        end
      end

      def overdue_with_easy_extensions?
        if due_date.nil?
          false
        elsif due_date.is_a?(Date)
          overdue_without_easy_extensions?
        else
          (due_date < Time.now) && !closed?
        end
      end

      # Returns an array of statuses that user is able to apply
      def new_statuses_allowed_to_with_easy_extensions(user = User.current, include_default = false)
        if new_record?
          # nop
        elsif tracker_id_changed?
          if Tracker.where(:id => tracker_id_was, :default_status_id => status_id_was).any?
            initial_status = default_status
          elsif tracker && tracker.issue_status_ids.include?(status_id_was)
            initial_status = IssueStatus.find_by_id(status_id_was)
          else
            initial_status = default_status
          end
        else
          initial_status = status_was
        end

        initial_assigned_to_id       = assigned_to_id_changed? ? assigned_to_id_was : assigned_to_id
        assignee_transitions_allowed = initial_assigned_to_id.present? &&
            (user.id == initial_assigned_to_id || user.group_ids.include?(initial_assigned_to_id))

        if skip_workflow || (user.admin? && EasySetting.value('skip_workflow_for_admin', project))
          statuses = IssueStatus.sorted.to_a
        else
          if project
            if user.admin?
              user_roles = project.user_roles(user)
              user_roles = project.all_members_roles if user_roles.empty?
            else
              user_roles = user.roles_for_project(project)
            end
          else
            user_roles = []
          end

          statuses = []
          statuses += IssueStatus.new_statuses_allowed(
              initial_status,
              user_roles,
              tracker,
              author == user,
              assignee_transitions_allowed
          )
          statuses << initial_status unless statuses.empty?
          statuses << default_status if include_default || (new_record? && statuses.empty?)
          statuses = statuses.compact.uniq.sort
        end

        if blocked?
          statuses.reject!(&:is_closed?)
        end
        statuses
      end

      def notified_users_with_easy_extensions
        n_users = notified_users_without_easy_extensions

        # filter out previous assignees if needed
        n_users = n_users - (previous_assignee.is_a?(Group) ? previous_assignee.users : Array.wrap(previous_assignee)).compact.select{|user| self.assigned_to != user && user.pref.no_notified_as_previous_assignee}

        # notify previous assignee
        last_assigned_to = last_user_assigned_to.is_a?(Group) ? last_user_assigned_to.users : Array.wrap(last_user_assigned_to)
        last_assigned_to.each do |user|
          n_users << user if user &&
                             user.active? &&
                             !n_users.include?(user) &&
                             (user.mail_notification == 'all' || user.mail_notification == 'only_my_events') &&
                             !(self.assigned_to != user && user.pref.no_notified_as_previous_assignee)
        end

        # if issue is closed notify second previous assignee
        if status && status.is_closed?
          second_to_last_assigned_to = second_to_last_user_assigned_to.is_a?(Group) ? second_to_last_user_assigned_to.users : Array.wrap(second_to_last_user_assigned_to)
          second_to_last_assigned_to.each do |user|
            n_users << user if user &&
                               user.active? &&
                               !n_users.include?(user) &&
                               (user.mail_notification == 'all' || user.mail_notification == 'only_my_events') &&
                               !(self.assigned_to != user && user.pref.no_notified_as_previous_assignee)
          end
        end

        if closed? && !closing?
          n_users.reject! { |u| u.pref.no_notified_if_issue_closing }
        end

        n_users
      end

      def relations_with_easy_extensions
        @relations ||= IssueRelation::Relations.new(self, (relations_from.preload(:issue_to => [:project, :assigned_to, :tracker, :priority, :status]).to_a + relations_to.preload(:issue_from => [:project, :assigned_to, :tracker, :priority, :status]).to_a).sort)
      end

      # Adds a cache even if user is User.current wich should be same as user.nil?
      # TODO: too many if statements. user_roles != roles_for_project? than delete project
      def workflow_rule_by_attribute_with_easy_extensions(user = nil)
        user_real = user || User.current
        user      = nil if user_real.id == User.current.id
        return @workflow_rule_by_attribute if @workflow_rule_by_attribute && user.nil?

        if project
          if skip_workflow || (user_real.admin? && EasySetting.value('skip_workflow_for_admin', project))
            roles = (RequestStore.store['all_roles_for_admin'] ||= Role.all.to_a)
          elsif user_real.admin?
            roles = user_real.roles_for_project(project)
            roles = project.all_members_roles.to_a if roles.empty?
          else
            roles = user_real.roles_for_project(project)
          end
        else
          roles = []
        end
        roles = roles.select(&:consider_workflow?)
        return {} if roles.empty?

        result = {}
        roles  = project ? project.roles_for_workflow(user_real) : []
        if roles.empty?
          @workflow_rule_by_attribute = {}
          return result
        end

        workflow_rules = WorkflowPermission.easy_rules_by_role_id(status_id, tracker_id, roles.map(&:id))
        if workflow_rules.present?
          roles.each do |role|
            # fields with roles are in method - there are cached - performance for editable on index
            fields_with_roles = Issue.non_visible_custom_field_with_roles
            fields_with_roles.each do |field_id, role_ids|
              unless role_ids.include?(role.id)
                field_name                          = field_id.to_s
                workflow_rules[field_name]          ||= {}
                workflow_rules[field_name][role.id] = 'readonly'
              end
            end
          end
          roles_size = roles.size
          workflow_rules.each do |attr, rules|
            next if rules.size < roles_size
            uniq_rules = rules.values.uniq
            if uniq_rules.size == 1
              result[attr] = uniq_rules.first
            else
              result[attr] = 'required'
            end
          end
        end
        @workflow_rule_by_attribute = result
        result
      end

      def read_only_attribute_names_with_easy_extensions(user = nil)
        @read_only_attribute_names                            ||= {}
        @read_only_attribute_names[(user || User.current).id] ||= read_only_attribute_names_without_easy_extensions(user)
      end

      def required_attribute_names_with_easy_extensions(user = nil)
        @required_attribute_names                            ||= {}
        @required_attribute_names[(user || User.current).id] ||= required_attribute_names_without_easy_extensions(user)
      end

      def send_notification_with_easy_extensions
        return if self.author && self.author.pref.no_notification_ever

        if notify? && Setting.notified_events.include?('issue_added')
          send_notification_without_easy_extensions
          self.notification_sent = true
        end
      end

      def copy_from_with_easy_extensions(arg, options = {})
        copy = copy_from_without_easy_extensions(arg, options)

        copy.custom_field_values = @copied_from.custom_field_values.inject({}) { |h, v| h[v.custom_field_id] = v.value_for_params; h }
        copy.author              = @copied_from.author if options[:copy_author] && @copied_from.author
        copy.easy_external_id    = nil
        copy.easy_closed_by_id   = nil
        copy.parent_id           = @copied_from.parent_id if options[:copy_parent_issue_id]
        copy.tag_list            = @copied_from.tag_list

        Redmine::Hook.call_hook(:model_issue_copy_from, { hook_caller: self, copy: copy, copied_from: @copied_from })

        copy
      end

      def replace_history_token(text)
        text.gsub!(/%\s?task_history\s?%/) do |token|
          journals_with_notes = journals.visible.where(:private_notes => false).with_notes.order(:created_on => :desc)
          history             = ''

          if journals_with_notes.exists?
            history = '<div>'
            history << content_tag(:h4, I18n.t(:label_history))

            journals_with_notes.each do |journal|
              history << format_journal_for_mail_template(journal)
            end
            history << '</div>'
          end

          history
        end
        text
      end

      def replace_last_non_private_comment(text, last_journal = nil)
        last_non_private_journal = nil
        text.gsub!(/%\s?task_last_journal\s?%/) do |token|
          if last_non_private_journal.nil?
            last_journal_scope       = journals.visible.where(:private_notes => false).
                with_notes.order(:created_on => :desc)
            last_journal_scope       = last_journal_scope.where.not(:id => last_journal.id) unless last_journal.nil?
            last_non_private_journal = last_journal_scope.first
          end

          format_journal_for_mail_template(last_non_private_journal)
        end
        text
      end

      def format_journal_for_mail_template(journal)
        return '' if journal.nil?

        authoring    = content_tag(:strong, l(:label_updated_datetime_by, :author => journal.user, :datetime => format_time(journal.created_on)))
        parsed_notes = journal.notes.html_safe
        parsed_notes = content_tag(:p, parsed_notes) unless /^\s?<p>.*<\/p>\s?$/.match?(parsed_notes)

        authoring << parsed_notes
      end

      def prepare_journals(reversed_comments = false, all = false, limit = nil)
        limit             ||= EasySetting.value('easy_extensions_journal_history_limit')
        prepared_journals = journals.where(easy_type: nil).preload([{ user: (Setting.gravatar_enabled? ? :email_address : :easy_avatar) }, :details]).order(created_on: :desc)
        prepared_journals = prepared_journals.where(private_notes: false) unless User.current.allowed_to?(:view_private_notes, project)
        prepared_journals = prepared_journals.to_a
        Journal.preload_journals_details_custom_fields(prepared_journals)
        prepared_journals.select! { |journal| journal.notes? || journal.visible_details.any? }
        prepared_journals_count = prepared_journals.count
        limit                   = prepared_journals.count if all
        comments_count          = 0
        prepared_journals.select! { |journal| res = comments_count < limit; comments_count += 1 if journal.notes?; res }
        prepared_journals.reverse! unless reversed_comments
        [prepared_journals, prepared_journals_count]
      end

      def allowed_target_trackers_with_easy_extensions(user = User.current)
        scope = allowed_target_trackers_without_easy_extensions(user)
        scope = scope.unscope(where: :easy_distributed_tasks) if new_record? || tracker&.easy_distributed_tasks?

        scope
      end

    end

  end
end
EasyExtensions::PatchManager.register_model_patch 'Issue', 'EasyPatch::IssuePatch'

module EasyPatch
  module ProjectPatch

    def self.included(base)
      base.extend(ClassMethods)
      base.include(InstanceMethods)

      base.class_eval do

        const_set(:STATUS_PLANNED, 15)
        const_set(:STATUS_DELETED, 19)
        const_set(:EASY_INDICATOR_OK, 20)
        const_set(:EASY_INDICATOR_WARNING, 21)
        const_set(:EASY_INDICATOR_ALERT, 22)
        const_set(:COMPLETION_FORMULAS, [:normal, :weighted, :time_spending])
        const_set(:EASY_INDICATOR_COLORS, { 20 => '#4EBF67', 21 => '#FAC444', 22 => '#E50026' })

        belongs_to :author, :class_name => 'User', :foreign_key => 'author_id'
        belongs_to :easy_currency, primary_key: :iso_code, foreign_key: :easy_currency_code, inverse_of: :projects
        belongs_to :priority, class_name: 'EasyProjectPriority', foreign_key: 'easy_priority_id'
        has_and_belongs_to_many :project_custom_fields,
                                :class_name              => 'ProjectCustomField',
                                :order                   => "#{CustomField.table_name}.position",
                                :join_table              => "#{table_name_prefix}custom_fields_projects#{table_name_suffix}",
                                :association_foreign_key => 'custom_field_id'

        has_many :easy_favorites, :as => :entity
        has_many :favorited_by, lambda { distinct }, :through => :easy_favorites, :source => :user, :dependent => :destroy

        has_many :easy_queries, :dependent => :destroy
        has_many :project_activity_roles, lambda { preload(:role_activity, :role) }, :dependent => :delete_all
        has_many :roles, :through => :project_activity_roles
        has_many :role_activities, :through => :project_activity_roles
        has_many :issue_categories, lambda { order("#{IssueCategory.table_name}.lft") }, :dependent => :delete_all
        has_many :easy_custom_pages, :as => :entity, :class_name => 'EasyPage', :dependent => :destroy
        has_many :easy_custom_project_menus, :dependent => :destroy

        has_and_belongs_to_many :project_time_entry_activities,
                                :join_table              => 'projects_activities',
                                :foreign_key             => 'project_id',
                                :association_foreign_key => 'activity_id',
                                :class_name              => 'TimeEntryActivity'

        scope :templates, lambda { where(easy_is_easy_template: true) }
        scope :non_templates, lambda { where(easy_is_easy_template: false) }
        scope :by_permission, lambda { |*args| where(Project.by_permission_condition(*args)) }
        scope :archived, lambda { where(:status => Project::STATUS_ARCHIVED) }
        scope :deleted, lambda { where(:status => Project::STATUS_DELETED) }
        scope :active_and_planned, lambda { where(:status => [Project::STATUS_ACTIVE, Project::STATUS_PLANNED]) }
        scope :sorted, lambda { order("#{Project.table_name}.lft") }
        scope :scheduled_for_destroy, lambda { where.not(destroy_at: nil) }

        scope :like, lambda { |arg|
          if arg.blank?
            where(nil)
          else
            pattern = "%#{arg.to_s.strip.downcase}%"

            if EasySetting.value('project_display_identifiers')
              where(arel_table[:name].lower.matches(pattern).or(arel_table[:identifier].lower.matches(pattern)))
            else
              where(arel_table[:name].lower.matches(pattern))
            end
          end
        }

        remove_validation :identifier

        validates :identifier, :presence => true, :if => Proc.new { |p| p.identifier_changed? && EasySetting.value('project_display_identifiers') }
        validates_uniqueness_of :identifier, :if => Proc.new { |p| p.identifier_changed? && EasySetting.value('project_display_identifiers') }
        validates_length_of :identifier, :in => 1..Project::IDENTIFIER_MAX_LENGTH, :if => Proc.new { |p| p.identifier_changed? && EasySetting.value('project_display_identifiers') }
        validates_format_of :identifier, :with => /\A(?!\d+$)[a-z0-9\-_]*\z/, :if => Proc.new { |p| p.identifier_changed? && EasySetting.value('project_display_identifiers') }
        validates_exclusion_of :identifier, :in => %w( new ), :if => Proc.new { |p| p.identifier_changed? && EasySetting.value('project_display_identifiers') }
        validate :start_date_is_before_due_date, :if => Proc.new { |p| !EasySetting.value('project_calculate_start_date') && !EasySetting.value('project_calculate_due_date') }
        validate :validate_related_custom_fields
        validate :validate_easy_license, :on => :create, :if => Proc.new { |p| !(p.easy_is_easy_template) }

        html_fragment :description, :scrub => :strip

        acts_as_taggable_on :tags
        acts_as_easy_journalized

        searchable_options[:scope]         = -> (options)  { options[:open_projects] ? self.non_templates.active_and_planned : self.non_templates }
        searchable_options[:title_columns] = ["#{table_name}.name", "#{table_name}.identifier", "#{table_name}.id"]

        safe_attributes 'inherit_time_entry_activities',
                        :if => lambda { |project, user| project.new_record? }
        safe_attributes 'easy_start_date', 'easy_due_date', 'project_custom_field_ids', 'easy_is_easy_template', 'easy_currency_code', 'tag_list',
                        'author_id', 'is_planned', 'send_all_planned_emails'
        safe_attributes 'easy_priority_id', 'easy_has_custom_menu'

        delete_safe_attribute 'identifier'
        safe_attributes 'identifier', if: proc { EasySetting.value('project_display_identifiers') }

        after_initialize :default_values, :if => Proc.new { |p| p.new_record? }
        before_validation :default_values
        before_save :set_planned_status
        after_save :guess_identifier
        after_save :create_journal
        after_create :add_all_active_time_entry_activities
        # after_move :update_members_notifications
        after_destroy :delete_time_entry_activities
        after_commit :deliver_all_planned_emails

        attr_accessor :nofilter, :mass_operations_in_progress, :send_all_planned_emails, :inherit_time_entry_activities, :has_visible_children, :is_from_template
        attr_writer :is_planned
        attr_reader :favorited

        alias_method_chain :initialize, :easy_extensions
        alias_method_chain :active?, :easy_extensions
        # alias_method_chain :after_parent_changed, :easy_extensions
        alias_method_chain :add_default_member, :easy_extensions
        alias_method_chain :allowed_parents, :easy_extensions
        alias_method_chain :assignable_users, :easy_extensions
        alias_method_chain :children, :easy_extensions
        alias_method_chain :close, :easy_extensions
        alias_method_chain :reopen, :easy_extensions
        alias_method_chain :completed_percent, :easy_extensions
        alias_method_chain :copy, :easy_extensions
        alias_method_chain :copy_issues, :easy_extensions
        alias_method_chain :copy_issue_categories, :easy_extensions
        alias_method_chain :copy_members, :easy_extensions
        alias_method_chain :copy_versions, :easy_extensions
        alias_method_chain :css_classes, :easy_extensions
        alias_method_chain :due_date, :easy_extensions
        alias_method_chain :enabled_module_names=, :easy_extensions
        alias_method_chain :notified_users, :easy_extensions
        alias_method_chain :safe_attributes=, :easy_extensions
        alias_method_chain :siblings, :easy_extensions
        alias_method_chain :shared_versions, :easy_extensions
        alias_method_chain :start_date, :easy_extensions
        alias_method_chain :unarchive, :easy_extensions
        alias_method_chain :archive!, :easy_extensions
        alias_method_chain :users, :easy_extensions

        alias_method_chain :activities, :easy_extensions
        alias_method_chain :create_time_entry_activity_if_needed, :easy_extensions
        alias_method_chain :update_or_create_time_entry_activity, :easy_extensions


        class << self

          alias_method_chain :allowed_to_condition, :easy_extensions
          alias_method_chain :copy_from, :easy_extensions

          def delete_easy_page_modules(project_id)
            EasyPage.where(:page_scope => 'project').pluck(:id).each do |page_id|
              EasyPageZoneModule.where(:easy_pages_id => page_id, :entity_id => project_id).delete_all
            end
          end

          def by_permission_condition(*args)
            user, permission, options = nil, nil, nil

            first_arg = args.shift
            if first_arg.is_a?(User)
              user = first_arg
            elsif first_arg.is_a?(Symbol)
              permission = first_arg
            elsif first_arg.is_a?(Hash)
              options = first_arg
            end

            second_arg = args.shift
            if second_arg.is_a?(Symbol)
              permission = second_arg
            elsif second_arg.is_a?(Hash)
              options = second_arg
            end

            third_arg = args.shift
            if third_arg.is_a?(Hash)
              options = third_arg
            end

            user       ||= User.current
            permission ||= :view_project
            options    ||= {}

            allowed_to_condition(user, permission, options)
          end

          def update_project_entity_dates(entities, properties, date_delta)
            entities   ||= []
            properties ||= []
            date_delta ||= 0

            return if date_delta == 0 || entities.blank? || properties.blank?

            ActiveRecord::Base.transaction do
              entities.each do |entity|
                columns_to_update = properties.inject({}) do |properties, property|
                  properties ||= {}
                  if !entity[property].nil?
                    if property.in?(['created_on', 'updated_on'])
                      properties[property] = Time.now
                    else
                      properties[property] = entity[property] + date_delta.to_i.days
                    end
                  end
                  properties
                end
                entity.update_columns(columns_to_update) unless columns_to_update.empty?
              end
            end
          end

          def allowed_to_create_project_from_template?(user = nil)
            return false unless EasyLicenseManager.has_license_limit?(:active_project_limit)
            user ||= User.current
            user.easy_lesser_admin_for?(:templates) ||
                user.allowed_to_globally?(:create_project_from_template, {}) ||
                user.allowed_to_globally?(:create_subproject_from_template, {})
          end

          def css_icon
            'icon icon-project'
          end

        end
        # WARNING: Caching for current users to be careful
        def available_trackers
          return @available_trackers unless @available_trackers.nil?
          user  = User.current
          scope = self.trackers.sorted
          unless user.admin?
            roles = user.roles_for_project(self).select { |r| r.has_permission?(:add_issues) }
            unless roles.any? { |r| r.permissions_all_trackers?(:add_issues) }
              tracker_ids = roles.flat_map { |r| r.permissions_tracker_ids(:add_issues) }.uniq
              scope       = scope.where(id: tracker_ids)
            end
          end
          @available_trackers = scope
        end

        def allowed_to_create_subproject_from_template?(user = nil)
          user ||= User.current
          user.easy_lesser_admin_for?(:templates) ||
              user.allowed_to_globally?(:create_project_from_template, {}) ||
              user.allowed_to?(:create_subproject_from_template, self)
        end

        def copy_time_entry_activities_from_parent
          if inherit_time_entry_activities && parent
            copy_fixed_activity(parent)
            copy_activity(parent)
          end
        end

        def parent_project
          @parent_project ||= self.parent
        end

        def main_project
          @main_project ||= self.root
        end

        def delete_easy_page_modules
          Project.delete_easy_page_modules(self.id) unless self.new_record?
        end

        def duration
          (start_date && due_date) ? due_date - start_date : 0
        end

        def reschedule_after(date)
          return if date.nil? || self.mass_operations_in_progress
          if leaf?
            if start_date.nil? || start_date != date
              self.start_date, self.due_date = date, date + duration
              save
              reschedule_following_versions(date + duration)
            end
          else
            leaves.each do |leaf|
              leaf.reschedule_after(date)
            end
          end
        end

        def reschedule_following_versions(new_effective_date)
          return if self.mass_operations_in_progress
          self.versions.each do |version|
            version.effective_date = new_effective_date
            version.save
          end
        end

        def reschedule_following_issues(new_due_date)
          return if self.mass_operations_in_progress
          self.issues.each do |issue|
            journal          = issue.init_journal(User.current) if issue.start_date || issue.due_date
            issue.start_date = (new_due_date - issue.duration) if issue.start_date
            issue.due_date   = new_due_date if issue.due_date
            issue.save
          end
        end

        def default_values
          self.author_id ||= User.current.id
        end

        def all_members_roles
          @all_members_roles ||= Role.joins(:members).where(:members => { :project_id => self.id }).distinct.order(:position)
        end

        def members_roles_with_non_member
          @members_roles_with_non_member ||= all_members_roles.to_a.push(Role.non_member)
        end

        def roles_for_workflow(user)
          if user.admin? && EasySetting.value('skip_workflow_for_admin', self)
            roles = (RequestStore.store['all_roles_for_admin'] ||= Role.all.to_a)
          elsif user.admin?
            roles = user.roles_for_project(self)
            roles = self.all_members_roles.to_a if roles.empty?
          else
            roles = user.roles_for_project(self)
          end
          roles = roles.select(&:consider_workflow?)
        end

        def user_roles(user = nil)
          user ||= User.current
          all_members_roles.where(:members => { :user_id => user.id })
        end

        def grouped_user_role_names(users = [])
          groups = all_members_roles.where(:members => { :user_id => users.map(&:id) }).
              select('members.user_id, roles.name, roles.position, roles.id').
              group_by { |r| r.user_id }
          groups.transform_values! { |v| v.map { |r| r.name }.join(', ') }
          groups
        end

        def groups
          @groups ||= Group.joins(:members).where(:members => { :project_id => self.id })
        end

        def enabled_role_activity?(role_id, activity_id)
          self.project_activity_roles.where({ :role_id => role_id, :activity_id => activity_id }).exists?
        end

        def activities_per_role(user = nil, role_id = nil)
          role_id ||= 'xAll'
          user    ||= User.current
          return self.activities.sorted if !EasySetting.value('enable_activity_roles') || (user.admin? && self.all_members_roles.empty?) || (user.admin? && role_id == 'xAll')

          role_id = user.roles_for_project(self).pluck(:id) if role_id == 'xAll'

          TimeEntryActivity.where(id: project_activity_roles.where(role_id: role_id).select(:activity_id)).order(:position)
        end

        def reinitialize_values(i = 0)
          self.custom_field_values.each { |cv| cv.reinitialize_value(i) }
        end

        def reorder_subprojects!
          self.descendants.each do |subproject|
            subproject.set_parent!(subproject.parent_id)
          end
        end

        def easy_indicator
          return if self.closed?

          project_due_date = self.easy_due_date

          if Setting.display_subprojects_issues?
            projects_due_date_overflow = self.self_and_descendants.active_and_planned.exists?(["#{Project.table_name}.easy_due_date IS NOT NULL AND #{Project.table_name}.easy_due_date < ? ", Date.today])
          else
            projects_due_date_overflow = project_due_date && project_due_date < Date.today
          end

          if projects_due_date_overflow
            return Project::EASY_INDICATOR_ALERT
          else
            if Setting.display_subprojects_issues?
              project_ids              = self.self_and_descendants.active_and_planned.pluck(:id)
              issues_due_date_overflow = Issue.where(:project_id => project_ids).joins(:status).where("#{Issue.table_name}.due_date IS NOT NULL AND #{Issue.table_name}.due_date < ? AND #{IssueStatus.table_name}.is_closed = ?", Date.today, false).exists?
            else
              issues_due_date_overflow = self.issues.joins(:status).where("#{Issue.table_name}.due_date IS NOT NULL AND #{Issue.table_name}.due_date < ? AND #{IssueStatus.table_name}.is_closed = ?", Date.today, false).exists?
            end
            return Project::EASY_INDICATOR_WARNING if issues_due_date_overflow
          end

          if project_due_date
            Project::EASY_INDICATOR_OK
          else
            EasySetting.value(:default_project_indicator).to_i
          end
        end

        # Returns true if current project has any childrens
        def has_childrens?
          return false if self.children.nil?

          self.easy_is_easy_template ? self.children.templates.length > 0 : self.children.non_templates.length > 0
        end

        def has_visible_children?
          self.has_visible_children || (self.attributes['visible_children'] && self.attributes['visible_children'] > 0)
        end

        def css_project_classes(uniq_prefix = nil, options = {})
          inline_editable = options[:inline_editable] && editable?
          display_tree    = options[:display_tree].nil? ? true : options[:display_tree]
          uniq_prefix     ||= ''
          s               = ['project']
          s << 'root' if root? && display_tree
          s << 'child' if child? && display_tree
          s << (leaf? ? 'leaf' : 'parent')
          s << 'archived' if archived?
          s << 'closed' if closed?
          s << 'deleted' if deleted?
          s << "idnt-#{options[:level] || project.easy_level}" if display_tree
          s << nofilter if nofilter
          if project.child?
            s << "subproject #{uniq_prefix}parentproject_#{project.parent_id}"
          end
          s << 'multieditable-container' if inline_editable
          s.join(' ')
        end

        # CREATES a TEMPLATE from project and subprojects
        def create_project_templates(options = {})
          result                          = { :saved => [], :unsaved => [] }
          options[:copy_with_subprojects] = true
          old_projects                    = self.self_and_descendants.non_templates.active_and_planned
          ids_map                         = {}

          Project.transaction do
            old_projects.each do |old_project|
              options[:parent_id] = ids_map[old_project.parent_id]
              new_project         = old_project.create_project_template(options)
              if new_project.valid?
                result[:saved] << new_project
                ids_map[old_project.id] = new_project.id
              else
                result[:saved] = []
                result[:unsaved] << new_project
                raise ActiveRecord::Rollback
              end
            end
          end

          return result if result[:unsaved].any?

          # change issue relations according to newly created issues
          if options[:issues_map]
            old_projects.each do |old_project|
              set_issue_relations_according_to_issues_map(old_project, options[:issues_map])
            end
          end

          return result
        end

        # CREATES a TEMPLATE from project
        def create_project_template(options = {})
          new_project                       = Project.copy_from(self)
          new_project.name                  = self.name
          new_project.easy_is_easy_template = true
          new_project.parent_id             = options[:parent_id]
          if EasySetting.value('project_display_identifiers') && new_project.identifier.blank?
            # Template cannot have blank identifier
            # User does not have a chance to enter new
            new_project.identifier = next_template_identifier
          end
          new_project.custom_field_values.each do |cfv|
            cfv.value = '' if cfv.custom_field.field_format == 'autoincrement'
          end
          new_project.send(:copy_members, self)
          return new_project unless new_project.valid?
          new_project.save!
          new_project.copy(self, options)
          return new_project
        end

        def to_projects!
          prepare_projects = self.self_and_descendants.templates
          prepare_projects.each do |template|
            template.easy_is_easy_template = false
            template.save!
          end
        end

        # CREATES a PROJECT from template and subprojects. Also used during copying project!
        def project_with_subprojects_from_template(parent_project_id, projects_attributes = nil, options = {})
          return nil if (!projects_attributes.is_a?(Array) || !projects_attributes.is_a?(Hash)) && projects_attributes.blank?
          subprojects = self.descendants.to_a
          if projects_attributes.is_a?(Hash)
            projects_attributes = [projects_attributes]
          end

          options[:copy_with_subprojects] = true
          new_project                     = self.project_from_template(parent_project_id, projects_attributes.detect { |a| a['id'] == self.id.to_s }, options)

          return new_project, [], [new_project] if new_project.nil? || !new_project.valid?

          ids            = { self.id => new_project.id }
          unsaved, saved = [], [new_project]
          subprojects.each do |subproject|
            parent_id      = ids.has_key?(subproject.parent_id) ? ids[subproject.parent_id] : 0
            new_subproject = subproject.project_from_template(parent_id, projects_attributes.detect { |a| a['id'] == subproject.id.to_s }, options)

            if new_subproject.nil? || !new_subproject.valid?
              unsaved << new_subproject
            elsif !new_subproject.nil? && new_subproject.valid?
              saved << new_subproject
              ids[subproject.id] = new_subproject.id
            end
          end

          # change issue relations according to newly created issues
          if options[:issues_map]
            ([self].concat(subprojects)).each do |project|
              set_issue_relations_according_to_issues_map(project, options[:issues_map])
            end
          end

          return new_project, saved.map(&:reload), unsaved
        end

        # CREATES a PROJECT from template. Also used during copying project!
        def project_from_template(parent_project_id, project_attributes = {}, options = {})
          project_attributes = project_attributes.to_unsafe_hash if project_attributes.respond_to?(:to_unsafe_hash)
          return nil unless project_attributes.is_a?(Hash)
          User.current.reload # refresh caches #easy_project_ids_by_role

          logger.info "Creating project from #{self.id}-#{self.name}." if EasyExtensions.debug_mode? && logger
          t = Time.now

          new_project = Project.copy_from(self)

          logger.info('Setting new project...') if EasyExtensions.debug_mode? && logger
          project_attributes.stringify_keys!

          if self.easy_is_easy_template
            project_attributes['easy_is_easy_template'] = false
            project_attributes['author_id']             = User.current.id
          end
          project_attributes['parent_id'] = parent_project_id
          new_project.is_from_template    = true unless options[:copying_action] == :copying_project
          new_project.safe_attributes     = project_attributes

          # assigning new member pool before save
          new_project.send(:copy_members, self) unless options[:copying_action] == :copying_project

          Redmine::Hook.call_hook(:model_project_from_template_before_save, new_project: new_project, options: options)
          temp_easy_start_date, temp_easy_due_date = new_project.easy_start_date, new_project.easy_due_date

          easy_start_date = begin
            options[:easy_start_date].to_date
          rescue
            nil
          end

          new_project.attributes = { :easy_start_date => easy_start_date, :easy_due_date => nil }
          new_project.created_on = current_time_from_proper_timezone

          return new_project unless new_project.valid?

          saved = false
          Project.transaction do
            new_project.save!

            logger.info('Copying project entities...') if EasyExtensions.debug_mode? && logger

            raise ActiveRecord::Rollback unless new_project.copy(self, options)
            saved = true
          end
          return new_project unless saved

          unless Member.exists?(project_id: new_project.id, user_id: User.current.id)
            if EasySetting.value('use_default_user_type_role_for_new_project')
              role_id = User.current.easy_user_type.default_role&.id
            end
            role_id ||= Setting.new_project_user_role_id
            role    = Role.find_by(id: role_id) if role_id.present?
            if role
              m = new_project.members.build(:user => User.current)
              unless m.member_role_ids.include?(role.id)
                m.roles << role
                m.save
              end
              m.save if m.new_record?
            end
          end

          if temp_easy_start_date || temp_easy_due_date
            new_project.update_attributes({ :easy_start_date => temp_easy_start_date, :easy_due_date => temp_easy_due_date })
          end

          logger.info("Project created successfully in #{Time.now - t}s.") if EasyExtensions.debug_mode? && logger

          new_project
        end

        def set_issue_relations_according_to_issues_map(project, issues_map)
          # Relations after in case issues related each other
          project.issues.each do |issue|
            new_issue = issues_map[issue.id]
            unless new_issue
              # Issue was not copied
              next
            end

            issue.mass_operations_in_progress     = true
            new_issue.mass_operations_in_progress = true

            # Relations
            issue.relations_from.each do |source_relation|
              new_issue_relation            = IssueRelation.new
              new_issue_relation.attributes = source_relation.attributes.dup.except("id", "issue_from_id", "issue_to_id")

              new_issue_relation.issue_to = issues_map[source_relation.issue_to_id]
              if new_issue_relation.issue_to.nil? && Setting.cross_project_issue_relations?
                new_issue_relation.issue_to = source_relation.issue_to
                not_in_template_relation    = true
              end
              new_issue_relation.issue_from = issues_map[source_relation.issue_from_id]
              if new_issue_relation.issue_from.nil? && Setting.cross_project_issue_relations?
                new_issue_relation.issue_from = source_relation.issue_from
                not_in_template_relation      = true
              end
              new_issue.relations_from << new_issue_relation
            end

            issue.relations_to.each do |source_relation|
              new_issue_relation            = IssueRelation.new
              new_issue_relation.attributes = source_relation.attributes.dup.except("id", "issue_from_id", "issue_to_id")

              new_issue_relation.issue_to = issues_map[source_relation.issue_to_id]
              if new_issue_relation.issue_to.nil? && Setting.cross_project_issue_relations?
                new_issue_relation.issue_to = source_relation.issue_to
                not_in_template_relation    = true
              end
              new_issue_relation.issue_from = issues_map[source_relation.issue_from_id]
              if new_issue_relation.issue_from.nil? && Setting.cross_project_issue_relations?
                new_issue_relation.issue_from = source_relation.issue_from
                not_in_template_relation      = true
              end
              new_issue.relations_from << new_issue_relation
            end
          end
        end

        def all_project_custom_fields
          @all_project_custom_fields ||= (ProjectCustomField.for_all | project_custom_fields).sort
        end

        def all_project_templates_custom_fields
          EasyProjectTemplateCustomField.all.to_a
        end

        # Overrides Redmine::Acts::Customizable::InstanceMethods#available_custom_fields
        def available_custom_fields
          a = Array.wrap(all_project_custom_fields)
          a.concat(all_project_templates_custom_fields) if self.easy_is_easy_template?
          a
        end

        def inherit_time_entry_activities=(val)
          @inherit_time_entry_activities = val.to_s.to_boolean
        end

        def start_date=(d)
          unless EasySetting.value('project_calculate_start_date')
            self.easy_start_date = d
          end
        end

        def due_date=(d)
          unless EasySetting.value('project_calculate_due_date')
            self.easy_due_date = d
          end
        end

        def fixed_activity?
          if self.module_enabled?(:time_tracking)
            EasySetting.value('project_fixed_activity', self)
          else
            false
          end
        end

        def sum_of_issues_estimated_hours_scope(only_self = false)
          scope = Issue.where("#{Issue.table_name}.estimated_hours IS NOT NULL")
          if Setting.display_subprojects_issues? && !only_self
            scope.where(project_id: self_and_descendants.reorder(nil))
          else
            scope.where(project_id: self.id)
          end
        end

        def sum_of_time_entries_scope(only_self = false)
          if Setting.display_subprojects_issues? && !only_self
            TimeEntry.where(project_id: self_and_descendants.reorder(nil))
          else
            TimeEntry.where(project_id: self.id)
          end
        end

        def sum_of_issues_estimated_hours(only_self = false)
          scope = sum_of_issues_estimated_hours_scope(only_self)
          scope.sum(:estimated_hours) || 0.0
        end

        def sum_estimated_hours
          @sum_estimated_hours ||= self.issues.sum(:estimated_hours)
        end

        def sum_of_timeentries
          self.sum_time_entries
        end

        def sum_time_entries
          @sum_time_entries ||= self.time_entries.sum(:hours)
        end

        def sum_easy_divided_hours
          @sum_easy_divided_hours ||= self.time_entries.sum(:easy_divided_hours) || 0
        end

        def sum_of_visible_timeentries(user = nil)
          user     ||= User.current
          te_scope = TimeEntry.visible(user, :with_subprojects => Setting.display_subprojects_issues?, :project => self, :include_archived => :true)
          if !user.allowed_to_globally_view_all_time_entries?
            te_scope = te_scope.where(:user_id => user.id)
          end
          te_scope.sum(:hours)
        end

        def remaining_timeentries
          self.sum_estimated_hours - self.sum_of_timeentries
        end

        def sum_time_entries_between(date_begin, date_end)
          @sum_time_entries_between ||= self.time_entries.where(["#{TimeEntry.table_name}.spent_on BETWEEN ? AND ?", date_begin, date_end]).sum(:hours)
        end

        # (SUM of time entries' hours / SUM of estimated hours) * 100
        def percentage_of_time_spending(subtree = false)
          p_table      = Project.table_name
          issues_scope = Issue.where("#{Issue.table_name}.estimated_hours IS NOT NULL")

          if Setting.display_subprojects_issues? && subtree
            estimate_scope = issues_scope.joins(:project).where("#{p_table}.lft >= ? AND #{p_table}.rgt <= ?", lft, rgt)
            hours_scope    = TimeEntry.joins(:project).where("#{p_table}.lft >= ? AND #{p_table}.rgt <= ?", lft, rgt)
          else
            estimate_scope = issues_scope.where(project_id: id)
            hours_scope    = TimeEntry.where(project_id: id)
          end

          #estimate_sum = estimate_scope.pluck('SUM(estimated_hours)').first.to_f
          #hours_sum = hours_scope.pluck('SUM(hours)').first.to_f
          estimate_sum = estimate_scope.sum(:estimated_hours).to_f
          hours_sum    = hours_scope.sum(:hours).to_f

          if estimate_sum > 0
            hours_sum / estimate_sum * 100.0
          else
            0.0
          end
        end

        def percentage_of_done_from_task(options = {})
          options[:per_project_without_issues] = 100 unless options[:per_project_without_issues]
          if Setting.display_subprojects_issues? && options.delete(:include_subprojects)
            scope       = self_and_descendants.joins(:issues).group(:id).select("SUM(#{Issue.quoted_table_name}.done_ratio) / COUNT(#{Issue.quoted_table_name}.id) AS result")
            per_project = Project.connection.select_all(scope)

            total = per_project.rows.sum { |r| r[0].to_i }.to_f.round
            total += options[:per_project_without_issues] * (self_and_descendants.count - per_project.count) # 100 for projects without issues

            project_count = options[:per_project_without_issues] == 0 ? per_project.count : self_and_descendants.count # ignore project without issues and with 0 %
            project_count > 0 ? total / project_count : 0
          else
            if issues.count > 0
              total = issues.sum(:done_ratio)

              total / issues.count
            else
              options[:per_project_without_issues]
            end
          end
        end

        def total_spent_hours
          @total_spent_hours ||= self_and_descendants.joins(:time_entries).sum("#{TimeEntry.table_name}.hours").to_f
        end

        def total_easy_divided_hours
          @total_easy_divided_hours ||= self_and_descendants.joins(:time_entries).sum("#{TimeEntry.table_name}.easy_divided_hours").to_f
        end

        def total_sum_estimated_hours
          @total_estimated_hours ||= sum_of_issues_estimated_hours(false)
        end

        def total_remaining_timeentries
          @total_remaining_timeentries ||= (sum_of_issues_estimated_hours(false) - total_spent_hours)
        end

        def display_issue_categories?
          return @display_issue_categories if @display_issue_categories
          @display_issue_categories = !self.trackers.detect { |t| !t.disabled_core_fields.include?('category_id') }.nil?
        end

        # Returns allowed parent depends on project
        # => options:
        # =>    :force => :projects or :templates
        def allowed_parents_scope(user = nil, options = {})
          real_user = user || User.current

          if options[:force] == :projects
            load_projects = true
          elsif options[:force] == :templates
            load_projects = false
          else
            load_projects = !self.easy_is_easy_template?
          end

          scope = Project
          scope = load_projects ? scope.non_templates : scope.templates
          scope = scope.where(Project.allowed_to_condition(real_user, @is_from_template ? :create_subproject_from_template : :add_subprojects))
          scope = scope.where(["#{Project.table_name}.lft < ? OR #{Project.table_name}.rgt > ?", self.lft, self.rgt]) unless self.new_record?
          scope
        end

        # matches consecutive projects according to search terms array
        # @param terms [Array] consecutive search terms
        # @param limit [Integer]
        # @param self_only [Boolean]
        # @param options[Hash] (see #allowed_parents_scope)
        # @return [ActiveRecord::Relation] matched projects
        # @example
        #   Project.first.match_projects_recursive(User.first, %w[budget test], 10, false, {})
        def match_projects_recursive(user, terms, limit, self_only, options)
          last_term = terms.pop
          last_parent_ids = terms.inject(nil) do |parent_ids, term|
            scope_part = match_projects_scope(user, term, parent_ids, limit, self_only, options)
            ids = scope_part.pluck(:id)
            break ids if ids.empty?
            ids
          end

          match_projects_scope(user, last_term, last_parent_ids, limit, self_only, options).all
        end

        # matches projects according to single search term
        # @param term [String] search term
        # @param parent_ids [Array, nil] ids of parent projects
        #   If parent_ids is nil, we are looking for any projects,
        #   if parent_ids is an array of ids, we are looking for children projects,
        #   if parent_ids is [], we are looking for projects with blank parent_id.
        # @param limit [Integer]
        # @param self_only [Boolean]
        # @param options[Hash] (see #allowed_parents_scope)
        # @return [ActiveRecord::Relation] matched projects
        # @example
        #   Project.first.match_projects_scope(User.first, 'test', nil, 10, false, {})
        def match_projects_scope(user, term, parent_ids, limit, self_only, options)
          scope = allowed_parents_scope(user, options)
          scope = scope.where(parent_id: parent_ids) if parent_ids.kind_of?(Array)
          scope = scope.where(Redmine::Database.like("#{Project.table_name}.name", '?'), "%#{term}%") unless self_only
          scope.limit(limit).reorder("#{Project.table_name}.lft")
        end

        def update_project_entities_dates(day_shift)
          Project.update_project_entity_dates([self], ['created_on', 'updated_on', 'easy_start_date', 'easy_due_date'], day_shift)
          Project.update_project_entity_dates(self.versions.all, ['created_on', 'effective_date', 'updated_on'], day_shift)
          Project.update_project_entity_dates(self.issues.all, ['created_on', 'start_date', 'due_date', 'updated_on'], day_shift)
        end

        def is_planned
          if @is_planned.nil?
            self.status == Project::STATUS_PLANNED
          else
            @is_planned.to_s.to_boolean
          end
        end

        def editable?(user = User.current)
          return @editable if @editable && user == User.current

          result    = user.allowed_to?(:edit_project, self) || (user.allowed_to?(:edit_own_projects, nil, :global => true) && self.author == user)
          @editable = result if user == User.current

          result
        end

        def deleted?
          self.status == Project::STATUS_DELETED
        end

        def set_planned_status
          if is_planned.to_s.to_boolean
            self.status = Project::STATUS_PLANNED
          elsif self.status == Project::STATUS_PLANNED
            self.status = Project::STATUS_ACTIVE
          end
        end

        def deliver_all_planned_emails
          if self.send_all_planned_emails == '1'
            if Setting.notified_events.include?('issue_added')
              self.issues.open.each do |issue|
                Mailer.deliver_issue_add(issue)
              end
            end

            if self.module_enabled?(:documents) && Setting.notified_events.include?('document_added')
              self.documents.each do |document|
                Mailer.deliver_document_added(document, User.current)
              end
            end

            if self.module_enabled?(:news) && Setting.notified_events.include?('news_added')
              self.news.each do |n|
                Mailer.deliver_news_added(n)
              end
            end

            Redmine::Hook.call_hook(:model_project_send_all_planned_emails, { :project => self })
          end
        end

        def journal_comments
          @journal_comments ||= self.journals.with_notes.to_a
        end

        def last_journal_comment
          @last_journal_comment ||= self.journals.with_notes.last
        end

        def members_list(system_users: true, limit: 10, &block)
          scope = members.visible.preload(:roles, { user: (Setting.gravatar_enabled? ? :email_address : :easy_avatar) }).sorted_by_importance.limit(limit)
          scope = scope.where(users: { easy_system_flag: false }) unless system_users
          return scope.to_a unless block_given?

          scope.each(&block)
        end

        def init_overview_page
          return if new_record?
          page_template = EasyPage.find_by(page_name: 'project-overview').try(:default_template)
          EasyPageZoneModule.create_from_page_template(page_template, nil, id) if page_template
        end

        def default_project_page
          return @default_project_page if !@default_project_page.nil?

          page                  = EasySetting.value('default_project_page', self)
          @default_project_page = case page
                                  when 'project_overview'
                                    'overview'
                                  when 'issue_tracking'
                                    'issues'
                                  when 'time_tracking'
                                    'time_entries'
                                  else
                                    page || ''
                                  end
        end

        def match_starting_dates
          reload
          date = easy_start_date
          return if date.blank?

          issues.each do |issue|
            issue.update_columns(start_date: date, due_date: date + issue.duration.to_i.days)
          end
        end

        def visible_custom_field_values(user = nil)
          user_real = user || User.current
          custom_field_values.select do |value|
            value.custom_field.visible_by?(project, user_real)
          end
        end

        def can_delete_project_with_time_entries?
          TimeEntry.where(project_id: self.self_and_descendants).find_each do |time_entry|
            return false unless time_entry.valid_for_destroy?
          end

          true
        end

        private

        def copy_activity(source_project)
          delete_time_entry_activities
          source_project.project_time_entry_activities.each do |tea|
            self.project_time_entry_activities << tea unless self.project_time_entry_activities.include?(tea)
          end
          copy_project_activity_roles(source_project)
          copy_fixed_activity(source_project)
        end

        def copy_news(source_project)
          news = News.where(:project_id => source_project.id)
          news.each do |n|
            copy                  = n.dup
            copy.project_id       = self.id
            copy.easy_external_id = nil if copy.respond_to?(:easy_external_id)
            logger.warn("model_project_copy_before_save ERROR ( source_project: #{source_project.id}, news: #{n.id} )") if !copy.save && logger
          end
        end


        def copy_documents(source_project)
          source_project.documents.each do |d|
            doc_copy                  = d.dup
            doc_copy.project_id       = self.id
            doc_copy.easy_external_id = nil
            logger.warn("model_project_copy_before_save ERROR ( source_project: #{source_project.id}, doc: #{d.id} )") if !doc_copy.save && logger
            d.attachments.each do |at|
              at_copy                  = at.dup
              at_copy.easy_external_id = nil
              at_copy.container_id     = doc_copy.id
              logger.warn("model_project_copy_before_save ERROR ( source_project: #{source_project.id}, attachments #{at.id} )") if !at_copy.save && logger
            end
          end
        end

        def copy_project_activity_roles(source_project)
          source_project.project_activity_roles.each do |par|
            unless ProjectActivityRole.where(:activity_id => par.activity_id, :role_id => par.role_id, :project_id => self.id).exists?
              ProjectActivityRole.create(:activity_id => par.activity_id, :role_id => par.role_id, :project_id => self.id)
            end
          end
        end

        def copy_fixed_activity(source_project)
          EasySetting.copy_project_settings('project_fixed_activity', source_project.id, self.id)
        end

        def copy_easy_page_modules(source_project)
          if source_project.nil? || source_project.new_record?
            logger.error('Failed because source project is new record or nil') if logger
            return
          end

          if self.new_record?
            logger.error('Failed because target project is new record or nil') if logger
            return
          end

          EasyPageZoneModule.clone_by_entity_id(source_project.id, self.id, :query_mapping => @query_mapping)
        end

        def copy_repository(source_project)
          return if source_project.repository.nil?

          # EasySetting.copy_project_settings('commit_ref_keywords', source_project.id, self.id)
          # EasySetting.copy_project_settings('commit_fix_keywords', source_project.id, self.id)
          # EasySetting.copy_project_settings('commit_fix_status_id', source_project.id, self.id)
          # EasySetting.copy_project_settings('commit_fix_done_ratio', source_project.id, self.id)
          # EasySetting.copy_project_settings('commit_fix_assignee_id', source_project.id, self.id)
          # EasySetting.copy_project_settings('commit_logtime_enabled', source_project.id, self.id)
          # EasySetting.copy_project_settings('commit_logtime_activity_id', source_project.id, self.id)

          new_repository            = source_project.repository.dup
          new_repository.project_id = self.id

          logger.warn("copy_repository ERROR (source_project: #{source_project.id}, repository: #{source_project.repository.id} )") if !new_repository.save && logger
        end

        def copy_easy_queries(source_project)
          @query_mapping = {}
          source_project.easy_queries.each do |query|
            next if query.is_a?(EasyQuery.disabled_sti_class)
            new_query               = query.class.new
            new_query.attributes    = query.attributes.dup.except('id', 'project_id', 'sort_criteria', "user_id", "type")
            new_query.sort_criteria = query.sort_criteria if query.sort_criteria
            new_query.project       = self
            new_query.user_id       = query.user_id
            new_query.role_ids      = query.role_ids if query.visibility == IssueQuery::VISIBILITY_ROLES
            if new_query.valid?
              self.easy_queries << new_query
              @query_mapping[query.id.to_s] = new_query.id.to_s
            end
          end
        end

        def copy_status(source_project)
          self.status = source_project.status
        end

        def copy_easy_custom_project_menus(source_project)
          source_project.easy_custom_project_menus.order(position: :desc).each do |item|
            unless EasyCustomProjectMenu.where(menu_item: item.menu_item, name: item.name, project_id: self.id).exists?
              url = item.url.to_s.gsub("projects/#{source_project.id}", "projects/#{self.id}")
              EasyCustomProjectMenu.create(menu_item: item.menu_item, name: item.name, url: url, project_id: self.id)
            end
          end
        end

        # Migrate ids of filters from old to new query.
        def change_id_for_new_queries(key, old_entity, new_entity)
          self.easy_queries.each do |query|
            filter = query.filters[key]
            if filter
              values = filter[:values]
              values.map! do |value|
                value.to_s == old_entity.id.to_s ? new_entity.id.to_s : value
              end
              query.save
            end
          end
        end

        # Migrate ids of entities to zone modules from old to new modules
        # value_name is page_module settings value to be set
        def change_id_for_new_modules(value_name, old_entity, new_entity)
          EasyPage.where(:page_scope => 'project').each do |page|
            EasyPageZoneModule.where(easy_pages_id: page.id, entity_id: self.id).each do |page_module|
              # Change ids only for query module (for now)
              next unless page_module.module_definition.query_module?

              values = page_module.settings[:values].try(:[], value_name)
              if values
                values.map! do |value|
                  value.to_s == old_entity.id.to_s ? new_entity.id.to_s : value
                end
                page_module.save
              end

            end
          end
        end

        def calculated_start_date(options = {})
          first_date = scope_for_date_calculation(:start).pluck(:start_date).first
          dates      = []
          dates << first_date unless first_date.blank?
          unless options[:skip_versions]
            dates << shared_versions.minimum('effective_date')
            dates << Issue.fixed_version(shared_versions).minimum('start_date')
          end
          dates.flatten.compact.min
        end

        def calculated_due_date
          last_date = scope_for_date_calculation(:end).pluck(:due_date).first
          [
              last_date.blank? ? nil : last_date,
              shared_versions.maximum('effective_date'),
              Issue.fixed_version(shared_versions).maximum('due_date')
          ].flatten.compact.max
        end

        def guess_identifier
          if EasySetting.value('project_display_identifiers') && self.identifier.blank?
            self.identifier = self.id.to_s
            update_column :identifier, self.id.to_s
          elsif self.identifier.blank?
            update_column :identifier, self.id.to_s
          end
        end

        # Project with identifier = "id"
        # Template will have "id-template-1"
        # If template be created again identifier will be "id-template-2"
        def next_template_identifier
          template_identifier_prefix = "#{self.identifier}-template"

          p = Project.where("identifier LIKE '#{template_identifier_prefix}-%'").order('identifier DESC').limit(1).pluck(:identifier)
          if p.any?
            p.first.succ
          else
            "#{template_identifier_prefix}-1"
          end
        end

        def scope_for_date_calculation(type)
          date_attribute = type == :start ? 'start_date' : 'due_date'
          scope          = Issue.all
          if Setting.display_subprojects_issues?
            scope = scope.joins(:project)
            scope = scope.where(["#{Project.table_name}.lft >= ? AND #{Project.table_name}.rgt <= ?", self.lft, self.rgt])
            scope = scope.where(["#{Project.table_name}.easy_is_easy_template = ?", self.project.easy_is_easy_template?])
          else
            scope = scope.where(:project_id => self.id)
          end
          scope = scope.where("#{date_attribute} IS NOT NULL")
          scope = scope.reorder("#{date_attribute} #{type == :start ? 'asc' : 'desc'}")
          scope.limit(1)
        end

        def add_all_active_time_entry_activities
          unless new_record? || easy_is_easy_template? || (inherit_time_entry_activities && parent)
            self.class.connection.execute("INSERT INTO #{ProjectActivity.table_name} (project_id, activity_id) SELECT #{self.id}, e.id FROM #{Enumeration.table_name} e WHERE e.type = 'TimeEntryActivity' AND e.active = #{self.class.connection.quoted_true} AND e.project_id IS NULL AND e.parent_id IS NULL AND NOT EXISTS(SELECT pa.project_id FROM #{ProjectActivity.table_name} pa WHERE pa.project_id = #{self.id} AND pa.activity_id = e.id)")
          end
        end

        def delete_time_entry_activities # and projects_activity_roles
          self.class.connection.execute("DELETE FROM #{ProjectActivityRole.table_name} WHERE project_id = #{self.id}")
          self.class.connection.execute("DELETE FROM #{ProjectActivity.table_name} WHERE project_id = #{self.id}")
        end

        def update_members_notifications
          if parent_id
            members.each do |m|
              m.copy_mail_notification_from_parent(parent_id)
            end
          end
        end

        def validate_easy_license
          message = l(:'license_manager.project_limit', :email => EasyExtensions::EasyProjectSettings.app_email)
          errors.add(:base, message) if !EasyLicenseManager.has_license_limit?(:active_project_limit)
        end

      end
    end

    module InstanceMethods

      # def after_parent_changed_with_easy_extensions(parent_was)
      #   after_parent_changed_without_easy_extensions(parent_was)
      #   copy_time_entry_activities_from_parent
      # end

      def initialize_with_easy_extensions(attributes = nil, *args)
        initialize_without_easy_extensions(attributes, *args)

        if attributes.nil? || !attributes.has_key?('inherit_members') && !attributes.has_key?(:inherit_members)
          self.inherit_members = !!EasySetting.value('default_project_inherit_members')
        end
      end

      # Returns allowed parent depends on project
      # => options:
      # =>    :force => :projects or :templates
      def allowed_parents_with_easy_extensions(user = nil, options = {})
        return @allowed_parents if @allowed_parents && user.nil?
        real_user = user || User.current

        scope            = allowed_parents_scope(real_user, options)
        @allowed_parents = scope.to_a

        if real_user.allowed_to?(:add_project, nil, :global => true) || (!new_record? && parent.nil? && !@is_from_template) || (real_user.allowed_to?(:create_project_from_template, nil, :global => true) && @is_from_template)
          @allowed_parents << nil
        end
        if !parent.nil? && !@allowed_parents.empty? && !@allowed_parents.include?(parent) && !@is_from_template
          @allowed_parents << parent
        end
        @allowed_parents
      end

      # Overrides "siblings" named scope.
      def siblings_with_easy_extensions
        self.easy_is_easy_template ? siblings_without_easy_extensions.templates : siblings_without_easy_extensions.non_templates
      end

      # Overrides "children" named scope.
      def children_with_easy_extensions
        self.easy_is_easy_template ? children_without_easy_extensions.templates : children_without_easy_extensions.non_templates
      end

      def enabled_module_names_with_easy_extensions=(module_names)
        send :enabled_module_names_without_easy_extensions=, module_names
        Redmine::Hook.call_hook(:model_project_enabled_module_changed, :project => self)
      end

      def completed_percent_with_easy_extensions(options = { :include_subprojects => false })
        setting_calculation_formula = options[:formula] || EasySetting.value('project_completion_formula')
        case setting_calculation_formula
        when 'weighted'
          calculate_done_weighted_with_estimated_time(options[:include_subprojects])
        when 'time_spending'
          percentage_of_time_spending(options[:include_subprojects])
        else
          percentage_of_done_from_task(options)
        end
      end

      def unarchive_with_easy_extensions
        return false if ancestors.any?(&:scheduled_for_destroy?)
        return false if ancestors.any?(&:archived?)

        new_status = ancestors.any?(&:closed?) ? Project::STATUS_CLOSED : Project::STATUS_ACTIVE
        self_and_descendants.status(Project::STATUS_ARCHIVED).update_all(status: new_status, updated_on: Time.now)
        self_and_descendants.scheduled_for_destroy.update_all(destroy_at: nil) if scheduled_for_destroy?
        reload
      end

      def archive_with_easy_extensions!
        self_and_descendants.update_all(status: Project::STATUS_ARCHIVED, updated_on: Time.now)
        reload
      end

      def copy_members_with_easy_extensions(project)
        return if @members_copied

        members_to_copy = []
        members_to_copy.concat(project.memberships.select { |m| m.principal.is_a?(User) })
        members_to_copy.concat(project.memberships.select { |m| !m.principal.is_a?(User) })

        existing_members = self.memberships.pluck(:user_id)

        members_to_copy.each do |member|
          next if existing_members.include?(member.user_id)

          new_member            = Member.new
          new_member.attributes = member.attributes.dup.except('id', 'project_id', 'created_on', 'easy_external_id')
          # only copy non inherited roles
          # inherited roles will be added when copying the group membership
          role_ids = member.member_roles.reject(&:inherited?).collect(&:role_id)
          next if role_ids.empty?
          new_member.role_ids = role_ids
          new_member.project  = self
          self.members << new_member
        end

        @members_copied = true
      end

      def copy_versions_with_easy_extensions(project)
        versions_map      = {}
        existing_versions = self.versions.pluck(:name)
        project.versions.reorder(:id).each do |version|
          next if existing_versions.include?(version.name)

          new_version                             = Version.new
          new_version.mass_operations_in_progress = true
          new_version.attributes                  = version.attributes.dup.except('id', 'project_id', 'created_on', 'updated_on', 'easy_external_id')
          new_version.custom_field_values         = version.custom_field_values.inject({}) { |h, v| h[v.custom_field_id] = v.value_for_params; h }
          self.versions << new_version
          change_id_for_new_modules("fixed_version_id", version, new_version)
          change_id_for_new_queries("fixed_version_id", version, new_version)
          versions_map[version.id] = new_version
        end

        Redmine::Hook.call_hook(:model_project_after_copy_versions, { :project => project, :new_project => self, :versions_map => versions_map })
      end

      def copy_issues_with_easy_extensions(project, options = {})
        options[:copying_action] ||= :copying_project

        unless options.has_key?(:with_time_entries)
          options[:with_time_entries] = (options[:copying_action] != :creating_template)
        end

        if options[:only].present?
          options[:copy_time_entries] = Array.wrap(options[:only]).include?('time_entries')
        end

        # Stores the source issue id as a key and the copied issues as the
        # value.  Used to map the two togeather for issue relations.
        issues_map = {}

        # Get issues sorted by root_id, lft so that parent issues
        # get copied before their children
        project.issues.reorder('root_id, lft').each do |issue|
          new_issue = Issue.new
          new_issue.copy_from(issue, options.merge(:subtasks => false, :link => false, :keep_status => true))
          new_issue.mass_operations_in_progress = true
          new_issue.done_ratio                  = 0 if options[:copying_action] == :creating_template
          new_issue.send :project=, self, true
          new_issue.author_id = options[:issues][:author_id] if options[:issues].try(:[], :author_id)
          new_issue.tag_list  = issue.tag_list

          # Changing project resets the custom field values
          # TODO: handle this in Issue#project=
          new_issue.custom_field_values = issue.custom_field_values.inject({}) { |h, v| h[v.custom_field_id] = v.value_for_params; h }

          # Reassign fixed_versions by name, since names are unique per
          # project and the versions for self are not yet saved
          if issue.fixed_version && (issue.fixed_version.sharing == 'system' || project.shared_versions.include?(issue.fixed_version))
            new_issue.fixed_version = self.shared_versions.detect { |v| v.name == issue.fixed_version.name } || issue.fixed_version
          end
          # Reassign version custom field values
          new_issue.custom_field_values.each do |custom_value|
            if custom_value.custom_field.field_format == 'version' && custom_value.value.present?
              versions  = Version.where(:id => custom_value.value).to_a
              new_value = versions.map do |version|
                if version.project == project
                  self.versions.detect { |v| v.name == version.name }.try(:id)
                else
                  version.id
                end
              end
              new_value.compact!
              new_value          = new_value.first unless custom_value.custom_field.multiple?
              custom_value.value = new_value
            end
          end
          # Reassign the category by name, since names are unique per
          # project and the categories for self are not yet saved
          if issue.category
            new_issue.category = self.issue_categories.detect { |c| c.name == issue.category.name }
          end
          # Parent issue
          if issue.parent_id
            if copied_parent = issues_map[issue.parent_id]
              new_issue.parent_issue_id = copied_parent.id
            end
          end

          new_issue.save(:validate => false)

          if new_issue.new_record?
            logger.warn "Project#copy_issues: issue ##{issue.id} could not be copied: #{new_issue.errors.full_messages}" if logger
          else
            issues_map[issue.id] = new_issue unless new_issue.new_record?
          end
        end

        set_issue_relations_according_to_issues_map(project, issues_map) if !options[:copy_with_subprojects]

        if options[:copy_time_entries] && project.module_enabled?('time_tracking') && options[:with_time_entries]
          project.time_entries.each do |t|

            te_attributes                       = t.attributes.dup.except('id', 'project_id', 'issue_id')
            te_copy                             = TimeEntry.new(te_attributes)
            te_copy.user_id                     = t.user_id
            te_copy.mass_operations_in_progress = true
            te_copy.project_id                  = self.id

            unless t.issue_id.nil?
              new_issue = issues_map[t.issue_id]
              unless new_issue
                logger.warn("model_project_copy_before_save ERROR cannot find new issue ( source_project: #{project.id}, time_entry #{t.id}, issue_id #{t.issue_id} )") if logger
                next
              end
              te_copy.issue_id = new_issue.id
            end

            te_copy.save(:validate => false)
            logger.warn("model_project_copy_before_save ERROR ( source_project: #{project.id}, time_entry #{t.id} )") if te_copy.new_record? && logger
          end
        end

        options[:issues_map] ||= {}
        options[:issues_map].merge!(issues_map)
        Redmine::Hook.call_hook(:model_project_after_copy_issues, { :project => project, :new_project => self, :issues_map => issues_map, :options => options })
      end

      def copy_issue_categories_with_easy_extensions(project)
        project.issue_categories.each do |issue_category|
          new_issue_category            = IssueCategory.new
          new_issue_category.attributes = issue_category.attributes.dup.except('id', 'project_id', 'parent_id', 'lft', 'rgt')
          self.issue_categories << new_issue_category
          change_id_for_new_modules('category_id', issue_category, new_issue_category)
          change_id_for_new_queries('category_id', issue_category, new_issue_category)
        end
      end

      def shared_versions_with_easy_extensions
        if new_record?
          Version.
              joins(:project).
              preload(:project).
              where("#{Project.table_name}.status <> ? AND #{Version.table_name}.sharing = 'system'", Project::STATUS_ARCHIVED)
        else
          @shared_versions ||= begin
            r = root? ? self : (root || self)
            Version.
                joins(:project).
                preload(:project).
                where("#{Project.table_name}.id = #{id}" +
                          " OR (#{Project.table_name}.status <> #{Project::STATUS_ARCHIVED} AND #{Project.table_name}.easy_is_easy_template = #{self.easy_is_easy_template ? self.class.connection.quoted_true : self.class.connection.quoted_false} AND (" +
                          " #{Version.table_name}.sharing = 'system'" +
                          " OR (#{Project.table_name}.lft >= #{r.lft} AND #{Project.table_name}.rgt <= #{r.rgt} AND #{Version.table_name}.sharing = 'tree')" +
                          " OR (#{Project.table_name}.lft < #{lft} AND #{Project.table_name}.rgt > #{rgt} AND #{Version.table_name}.sharing IN ('hierarchy', 'descendants'))" +
                          " OR (#{Project.table_name}.lft > #{lft} AND #{Project.table_name}.rgt < #{rgt} AND #{Version.table_name}.sharing = 'hierarchy')" +
                          "))")
          end
        end
      end

      def start_date_without_versions
        if EasySetting.value('project_calculate_start_date')
          @start_date_without_versions ||= calculated_start_date(skip_versions: true)
        else
          @start_date_without_versions = self.easy_start_date
        end
      end

      def start_date_with_easy_extensions
        if EasySetting.value('project_calculate_start_date')
          @start_date ||= calculated_start_date
        else
          @start_date = self.easy_start_date
        end
        @start_date
      end

      def due_date_with_easy_extensions
        if EasySetting.value('project_calculate_due_date')
          @due_date ||= calculated_due_date
        else
          @due_date = self.easy_due_date
        end
        @due_date
      end

      # options:
      # => :copying_action => :creating_template - delete issue history, time entries, etc.
      # => :copying_action => :creating_project - preserve all entities as possible
      # => :copying_action => :copying_project - preserve all entities as possible as specified at :only parameter.
      def copy_with_easy_extensions(project, options = {})
        project = project.is_a?(Project) ? project.reload : Project.find(project)

        EasySetting.copy_all_project_settings(project, self)

        # Make sure that `easy_queries` and `easy_page_modules` is first in the queue. All new EasyQuery
        # have to get id of the copied entity. Currently only for: issue_categories and versions.
        to_be_copied = %w(easy_queries easy_page_modules wiki versions issue_categories issues members boards documents activity news repository status easy_custom_project_menus)

        Redmine::Hook.call_hook(:model_project_copy_additionals, :source_project => project, :to_be_copied => to_be_copied, :options => options)

        to_be_copied                = to_be_copied & Array.wrap(options[:only]) unless options[:only].nil?
        options[:with_time_entries] = false unless to_be_copied.include?('activity')
        Project.transaction do
          if save
            reload
            to_be_copied.each do |name|
              t = Time.now
              logger.info("BEGIN Project (#{project.name}).copy #{name}") if EasyExtensions.debug_mode?

              copy_method = "copy_#{name}".to_sym
              if method(copy_method).arity == -2
                send copy_method, project, options
              else
                send copy_method, project
              end

              logger.info("END Project (#{project.name}).copy #{name} - duration #{Time.now - t}s") if EasyExtensions.debug_mode?
            end
            Redmine::Hook.call_hook(:model_project_copy_before_save, :source_project => project, :destination_project => self, :options => options)
            saved = save
            Redmine::Hook.call_hook(:model_project_copy_after_save, :source_project => project, :destination_project => self, :options => options) if saved
          end
          saved
        end
      end

      def update_or_create_time_entry_activity_with_easy_extensions(id, activity_hash)
        # nothing to do
      end

      def create_time_entry_activity_if_needed_with_easy_extensions(activity)
        # nothing to do
      end

      def activities_with_easy_extensions(include_inactive = false, fallback = false)
        if fallback
          activities_without_easy_extensions(include_inactive)
        else
          self.project_time_entry_activities
        end
      end

      def active_with_easy_extensions?
        self.status == Project::STATUS_ACTIVE || self.status == Project::STATUS_PLANNED
      end

      def project_custom_field_ids=(ids)
        @all_project_custom_fields = nil
        @custom_field_values = nil
        super(ids)
      end

      def safe_attributes_with_easy_extensions=(attrs, user = User.current)
        attrs = attrs.to_unsafe_hash if attrs.respond_to?(:to_unsafe_hash)
        return unless attrs.is_a?(Hash)
        attrs = attrs.deep_dup

        if attrs['custom_fields'] && attrs['custom_fields'].is_a?(Array) && !attrs['project_custom_field_ids']
          cf_array = attrs['custom_fields']
        elsif attrs['custom_field_values'] && attrs['custom_field_values'].is_a?(Array) && !attrs['project_custom_field_ids']
          cf_array = attrs['custom_field_values']
        end

        if self.new_record?
          if cf_array.blank?
            if attrs['project_custom_field_ids'].blank?
              attrs['project_custom_field_ids'] = self.project_custom_field_ids
            end
          else
            attrs['project_custom_field_ids'] ||= []
            cf_array.each do |cf|
              cf_id = nil

              if !cf['id'].blank?
                cf_id = cf['id'].to_i
              elsif !cf['internal_name'].blank?
                cf_id = CustomField.where(:internal_name => cf['internal_name']).pluck(:id).first
              end

              attrs['project_custom_field_ids'] << cf_id if !cf_id.blank? && !attrs['project_custom_field_ids'].include?(cf_id)
            end
          end

          if !attrs['project_custom_field_ids'].blank?
            self.project_custom_field_ids = attrs.delete('project_custom_field_ids')
          end
        end

        self.easy_is_easy_template = attrs[:easy_is_easy_template].to_s.to_boolean if attrs.key?(:easy_is_easy_template)

        send(:safe_attributes_without_easy_extensions=, attrs, user)
      end

      def css_classes_with_easy_extensions(level = nil, options = {})
        self.css_project_classes(nil, options.merge({ :level => level }))
      end

      def assignable_users_with_easy_extensions(tracker = nil)
        return @assignable_users[tracker] if @assignable_users && @assignable_users[tracker]

        types = ['User']
        types << 'Group' if Setting.issue_group_assignment?

        scope = Principal.
            active.visible.
            joins(:members => :roles).
            where(:type => types, :members => { :project_id => id }, :roles => { :assignable => true }).
            non_system_flag.distinct.
            sorted

        if tracker
          # Rejects users that cannot the view the tracker
          roles = Role.where(:assignable => true).select { |role| role.permissions_tracker?(:view_issues, tracker) }
          scope = scope.where(:roles => { :id => roles.map(&:id) })
        end

        @assignable_users          ||= {}
        @assignable_users[tracker] = scope
      end

      def users_with_easy_extensions
        @users ||= User.active.with_easy_avatar.joins(:members).where("#{Member.table_name}.project_id = ?", id).distinct
      end

      def add_default_member_with_easy_extensions(user)
        if EasySetting.value('use_default_user_type_role_for_new_project')
          role_id = user.easy_user_type.default_role&.id
        end
        role_id ||= (self.root? ? Setting.new_project_user_role_id.to_i : EasySetting.value('new_subproject_user_role_id').to_i)
        role    = Role.where(:builtin => 0).givable.find_by(id: role_id) || Role.where(:builtin => 0).givable.first
        if role
          member = Member.new(:project => self, :principal => user, :roles => [role])
          self.members << member
          member
        end
      end

      def notified_users_with_easy_extensions
        members.preload(:principal).where(Member.arel_table[:mail_notification].eq(true).or(Principal.arel_table[:mail_notification].eq('all'))).map { |m| m.principal }.compact
      end

      def calculate_done_weighted_with_estimated_time(subtree = false)
        scope_issues = sum_of_issues_estimated_hours_scope(!subtree)

        if scope_issues.where('estimated_hours > 0.0').exists? &&
            (tmp = scope_issues.select('(SUM(done_ratio / 100.0 * estimated_hours) / SUM(estimated_hours) * 100.0) AS sum_alias').reorder(nil).first)
          tmp.sum_alias.to_f
        else
          100.0
        end
      end

      def close_with_easy_extensions
        self_and_descendants.active_and_planned.update_all(:status => Project::STATUS_CLOSED, :updated_on => Time.now)
        reload
      end

      def reopen_with_easy_extensions
        self_and_descendants.status(Project::STATUS_CLOSED).update_all :status => Project::STATUS_ACTIVE
        reload
      end

      def start_date_is_before_due_date
        if easy_start_date.present? && easy_due_date.present? && easy_due_date < easy_start_date
          errors.add(:easy_due_date, :due_date_after_start)
        end
      end

      def validate_related_custom_fields
        issue_custom_fields.to_a.concat(project_custom_fields.to_a).each do |cf|
          next if cf.valid?
          cf.errors.full_messages.each do |msg|
            errors[cf.name.to_sym] << ": #{msg}"
          end
        end
      end

      def easy_currency_code
        read_attribute(:easy_currency_code) || EasyCurrency.default_code
      end

      def prepare_journals(limit)
        journals = self.journals.preload(:user, :details).reorder("#{Journal.table_name}.id DESC").limit(limit).to_a
        journals.reject!(&:private_notes?) unless User.current.allowed_to?(:view_private_notes, self)
        journals.reverse! if !User.current.wants_comments_in_reverse_order?

        journals
      end

      def scheduled_for_destroy?
        self.destroy_at.present?
      end

      def schedule_for_destroy!
        return if scheduled_for_destroy?

        wait_until = Project.maximum(:destroy_at)&.tomorrow || Time.now
        hour = EasySetting.value(:project_destroy_preferred_hour).to_i
        wait_until = wait_until.tomorrow if wait_until.hour > hour
        wait_until = wait_until.change(hour: hour)

        ProjectDestroyJob.set(wait_until: wait_until).perform_later(self.id)

        self.update_column(:destroy_at, wait_until)
      end

    end

    module ClassMethods

      def copy_from_with_easy_extensions(project)
        project = project.is_a?(Project) ? project : Project.find(project)
        # clear unique attributes
        attributes                       = project.attributes.dup.except('id', 'name', 'identifier', 'status', 'parent_id', 'lft', 'rgt', 'easy_is_easy_template', 'easy_external_id')
        copy                             = Project.new(attributes)
        copy.mass_operations_in_progress = true
        copy.enabled_module_names        = project.enabled_module_names
        copy.trackers                    = project.trackers
        copy.custom_values               = project.custom_values.where(:custom_fields => { :disabled => false }).collect { |v| cloned_v = v.dup; cloned_v.easy_external_id = nil; cloned_v.customized = copy; cloned_v }
        copy.project_custom_fields       = project.project_custom_fields
        copy.issue_custom_fields         = project.issue_custom_fields
        copy.status                      = project.status
        copy.tag_list                    = project.tag_list
        copy
      end

      def allowed_to_condition_with_easy_extensions(user, permission, options = {})
        tbl_name = options[:table_name] || self.table_name

        perm    = Redmine::AccessControl.permission(permission)
        options ||= {}

        if options[:include_archived]
          base_statement = '1=1'
        else
          base_statement = (perm && perm.read? ? "#{tbl_name}.status <> #{Project::STATUS_ARCHIVED}" : "#{tbl_name}.status IN (#{Project::STATUS_ACTIVE},#{Project::STATUS_PLANNED})")
        end

        if !options[:skip_pre_condition] && perm && perm.project_module
          # If the permission belongs to a project module, make sure the module is enabled
          base_statement << " AND EXISTS (SELECT 1 AS one FROM #{EnabledModule.table_name} em WHERE em.project_id = #{tbl_name}.id AND em.name='#{perm.project_module}')"
        end

        if project = options[:project]
          #project_statement = project.project_condition(options[:with_subprojects])
          project_statement = "#{tbl_name}.id = #{project.id}"
          if options[:with_subprojects]
            project_statement = "(#{project_statement} OR (#{tbl_name}.lft > #{project.lft} AND #{tbl_name}.rgt < #{project.rgt}))"
          end
          base_statement = "(#{project_statement}) AND (#{base_statement})"
        end

        statement = if user.admin? || (perm && perm.acts_as_admin?(user))
                      base_statement
                    else
                      statements = []
                      unless options[:member]
                        role = user.builtin_role
                        if role.allowed_to?(permission)
                          s = "#{tbl_name}.is_public = #{connection.quoted_true}"
                          if user.id
                            group         = role.anonymous? ? Group.anonymous : Group.non_member
                            principal_ids = [user.id, group.id].compact
                            s             = "(#{s} AND #{tbl_name}.id NOT IN (SELECT project_id FROM #{Member.table_name} WHERE user_id IN (#{principal_ids.join(',')})))"
                          end
                          if block_given? && (sb = yield(role, user))
                            s = "(#{s} AND (#{sb}))"
                          end
                          statements << s
                        end
                      end

                      all_allowed_project_ids = []
                      user.easy_project_ids_by_role(options).each do |role, project_ids|
                        if role.allowed_to?(permission) && project_ids.any?
                          if block_given? && (sb = yield(role, user))
                            statements << "(#{tbl_name}.id IN (#{project_ids.join(',')}) AND (#{sb}))"
                          else
                            all_allowed_project_ids |= project_ids
                          end
                        end
                      end
                      statements << "#{tbl_name}.id IN (#{all_allowed_project_ids.join(', ')})" if all_allowed_project_ids.any?
                      statements << options[:additional_statement] if options[:additional_statement]

                      if statements.empty?
                        '1=0'
                      else
                        "((#{base_statement}) AND (#{statements.join(' OR ')}))"
                      end
                    end
        statement
      end

    end

  end

end
EasyExtensions::PatchManager.register_model_patch 'Project', 'EasyPatch::ProjectPatch'

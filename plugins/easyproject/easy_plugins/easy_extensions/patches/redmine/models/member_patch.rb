module EasyPatch
  module MemberPatch

    def self.included(base)
      base.include(InstanceMethods)
      base.extend(ClassMethods)
      base.class_eval do

        belongs_to :group, :foreign_key => 'user_id'

        after_create :copy_mail_notification_from_parent
        before_destroy :remove_watchers

        scope :visible, lambda { |*args|
          user = args.shift || User.current
          if user.easy_lesser_admin_for?(:users)
            all
          else
            # display only members with visible user types and self
            where(:user_id => Member.unscoped { Principal.visible })
          end
        }

        scope :sorted_by_importance, -> do
          joins(:user).order(Arel.sql('( SELECT MIN(COALESCE( roles.position, 999 )) FROM member_roles INNER JOIN roles ON member_roles.role_id = roles.id WHERE member_roles.member_id = members.id ) ASC'), User.fields_for_order_statement)
        end

        class << self
          alias_method_chain :create_principal_memberships, :easy_extensions
        end

      end
    end

    module InstanceMethods

      def remove_watchers
        Watcher.joins("JOIN #{Issue.table_name} ON watchable_id = #{Issue.table_name}.id").
            where(watchable_type: 'Issue', user_id: self.user_id).
            where("#{Issue.table_name}.project_id = #{self.project_id}").destroy_all
      end

      def copy_mail_notification_from_parent(parent_id = nil)
        parent_id ||= project.parent.id if project && project.parent
        if parent_id && user
          membership = Member.find_by(:user_id => user.id, :project_id => parent_id)
          if membership && membership.mail_notification
            update_attributes(:mail_notification => true)
          end
        end
      end

      def assigned_tasks_for_reassign
        # collect tasks assigned to member which should be updated after member deletion
        # if member is group, collect all tasks from group and users
        # if after group deletion, user from group is still member with own role, then his tasks are not collected
        issues = Issue.arel_table
        members = Member.arel_table
        member_roles = MemberRole.arel_table
        projects = Project.arel_table

        subquery_members_with_inherited = member_roles.join(members).on(members[:id].eq(member_roles[:member_id]))
                                        .where(members[:project_id].eq(project_id))
                                        .group(members[:user_id], member_roles[:inherited_from])
                                        .project(members[:user_id].as('principal_id'), Arel.sql('1'))
                                        .as(Arel.sql(ActiveRecord::Base.connection.quote_table_name('mi')))
        subquery_join_table = Arel::SelectManager.new.tap do |manager|
          manager.project(Arel.sql('COUNT(*) as count'), subquery_members_with_inherited[:principal_id].as('p_id'))
          manager.from(subquery_members_with_inherited)
          manager.group(subquery_members_with_inherited[:principal_id])
        end.as(Arel.sql(ActiveRecord::Base.connection.quote_table_name('join_mi')))

        join_sources = issues.join(subquery_join_table).on(subquery_join_table[:p_id].eq(issues[:assigned_to_id])).join_sources

        groups_users = Arel::Table.new :groups_users
        users = User.arel_table
        users_from_group = users.join(groups_users)
              .on(groups_users[:user_id].eq(users[:id]))
              .where(groups_users[:group_id].eq(user_id))
              .project(users[:id])
        join_sources += issues.join(projects).on(projects[:id].eq(issues[:project_id])).join_sources
        Issue.from(issues).joins(join_sources)
              .where(projects[:id].eq(project_id))
              .where(issues[:assigned_to_id].eq(user_id).or(issues[:assigned_to_id].in(users_from_group)))
              .where(subquery_join_table[:count].eq(1))
              .select(Arel.sql('*'))
      end
    end

    module ClassMethods

      def create_principal_memberships_with_easy_extensions(principal, attributes)
        if attributes && attributes[:role_ids].blank? && principal.respond_to?(:easy_user_type)
          role_ids              = Array(principal.easy_user_type.try(:role_id)).presence
          attributes            = attributes.dup
          attributes[:role_ids] = role_ids
        end
        create_principal_memberships_without_easy_extensions(principal, attributes)
      end

    end

  end
end
EasyExtensions::PatchManager.register_model_patch 'Member', 'EasyPatch::MemberPatch'

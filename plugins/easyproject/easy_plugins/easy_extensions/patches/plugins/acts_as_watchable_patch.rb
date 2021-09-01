module EasyPatch
  module ActsAsWatchableInstanceMethodsPatch

    def self.included(base)
      base.include(InstanceMethods)

      base.class_eval do

        alias_method_chain :addable_watcher_users, :easy_extensions
        alias_method_chain :notified_watchers, :easy_extensions
        alias_method_chain :add_watcher, :easy_extensions
        alias_method_chain :remove_watcher, :easy_extensions
        alias_method_chain :watched_by?, :easy_extensions

      end
    end

    module InstanceMethods

      def addable_watcher_users_with_easy_extensions
        return [] if self.project.nil?
        users = self.project.users.with_easy_avatar.visible.sorted
        users = users.where.not(id: self.watcher_user_ids) unless self.new_record?
        users = users.to_a
        if self.is_a?(Issue) && !User.current.allowed_to?(:add_issue_watchers, self.project)
          users.reject! { |user| !self.project.visible?(user) }
        end
        users
      end

      def notified_watchers_with_easy_extensions
        if watcher_groups.any?
          scope = User.active.where(id: watcher_groups.map(&:user_ids).flatten.concat(watcher_user_ids))
        else
          scope = watcher_users
        end
        notified = scope.active.to_a
        notified.reject! do |user|
          user.mail.blank? || ['none', 'only_owner', 'only_assigned'].include?(user.mail_notification) ||
            (respond_to?(:visible?) && !visible?(user))
        end

        if self.is_a?(Issue) && closed? && !closing?
          notified.reject! { |u| u.pref.no_notified_if_issue_closing }
        end

        notified
      end

      def add_watcher_with_easy_extensions(user)
        return if self.watchers.detect { |watcher| watcher.user_id == user.id }

        if user.is_a?(Group)
          self.watchers << Watcher.new(:group => user)
        else
          add_watcher_without_easy_extensions(user)
        end
      end

      def remove_watcher_with_easy_extensions(user)
        if user.is_a?(Group)
          users_of_other_watcher_groups = watcher_groups.where.not(:id => user.id).collect { |group| group.users.pluck(:id) }.flatten.uniq
          users_to_remove               = [user.id] + user.users.pluck(:id) - users_of_other_watcher_groups

          watchers.where(:user_id => users_to_remove).delete_all
        else
          remove_watcher_without_easy_extensions(user)
        end
      end

      def available_groups
        if self.respond_to?(:project)
          groups = Group.joins(:members).where(:members => { :project_id => self.project_id }).where.not("#{Group.table_name}" => { :id => self.watcher_groups.pluck(:id) }).sorted
          groups = groups.preload(:easy_avatar) if EasySetting.value('avatar_enabled')
        else
          groups = []
        end
        groups
      end

      # Returns true if object is watched by +principal+
      def watched_by_with_easy_extensions?(principal)
        !!(principal && (self.watcher_user_ids.detect { |uid| uid == principal.id } || self.watcher_group_ids.detect { |gid| gid == principal.id }))
      end

      def watcher_principal_ids=(principal_ids)
        if principal_ids.is_a?(Array)
          principal_ids = principal_ids.uniq
        end
        self.watcher_user_ids = User.where(id: principal_ids).pluck(:id)
        self.watcher_group_ids = Group.where(id: principal_ids).pluck(:id)
      end
    end

  end

  module ActsAsWatchableClassMethodsPatch

    def self.included(base)
      base.class_eval do

        #fix for method safe_attributes= with use mass-assignment
        def acts_as_watchable_with_easy_extensions(options = {})
          acts_as_watchable_without_easy_extensions(options)

          has_many :watcher_groups, :through => :watchers, :source => :group, :validate => false

        end

        alias_method_chain :acts_as_watchable, :easy_extensions

      end
    end

  end
end
EasyExtensions::PatchManager.register_redmine_plugin_patch 'Redmine::Acts::Watchable::InstanceMethods', 'EasyPatch::ActsAsWatchableInstanceMethodsPatch'
EasyExtensions::PatchManager.register_redmine_plugin_patch 'Redmine::Acts::Watchable::ClassMethods', 'EasyPatch::ActsAsWatchableClassMethodsPatch'

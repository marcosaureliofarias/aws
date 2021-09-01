module EasyPatch
  module RolePatch

    def self.included(base)
      base.extend(ClassMethods)
      base.include InstanceMethods

      base.class_eval do

        acts_as_easy_translate

        has_and_belongs_to_many :activities, :join_table => 'projects_activity_roles', :class_name => 'TimeEntryActivity', :association_foreign_key => 'activity_id'

        has_many :project_activity_roles, :class_name => 'ProjectActivityRole', :dependent => :delete_all
        has_many :projects, :through => :project_activity_roles
        has_many :role_activities, :through => :project_activity_roles
        has_many :easy_default_query_mappings, :dependent => :destroy
        has_one :easy_global_time_entry_setting

        has_and_belongs_to_many :easy_queries, :join_table => "#{table_name_prefix}easy_queries_roles#{table_name_suffix}", :foreign_key => 'role_id'

        # column description doesn't exist when migrating from redmine to easyredmine, see migration 062_insert_builtin_roles.rb
        if column_names.include? 'description'
          validates_length_of :description, :maximum => 255
        end


        safe_attributes 'reorder_to_position', 'description', 'easy_external_id', 'limit_assignable_users'

        after_save :invalidate_cache, :if => :builtin?
        after_destroy :invalidate_cache, :if => :builtin?

        alias_method_chain :consider_workflow?, :easy_extensions

        class << self

          alias_method_chain :find_or_create_system_role, :easy_extensions

        end

        def invalidate_cache
          RequestStore.store[:system_roles] = {}
        end

      end
    end

    module InstanceMethods

      def consider_workflow_with_easy_extensions?
        consider_workflow_without_easy_extensions? || has_permission?(:edit_own_issues) || has_permission?(:edit_assigned_issue)
      end

    end

    module ClassMethods

      def find_or_create_system_role_with_easy_extensions(buildin, name)
        RequestStore.store[:system_roles]          ||= {}
        RequestStore.store[:system_roles][buildin] ||= find_or_create_system_role_without_easy_extensions(buildin, name)
      end

    end

  end

end
EasyExtensions::PatchManager.register_model_patch 'Role', 'EasyPatch::RolePatch'

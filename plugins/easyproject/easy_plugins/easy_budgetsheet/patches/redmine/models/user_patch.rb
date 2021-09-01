module EasyBudgetsheet
  module UserPatch

    def self.included(base)
      base.extend(ClassMethods)
      base.include(InstanceMethods)

      base.class_eval do

      end
    end

    module InstanceMethods

    end

    module ClassMethods

      def easy_budgetsheet_available_users
        available_role_ids = Role.all.to_a.select do |role|
          role.permissions.detect{|p| [:edit_own_time_entries, :edit_time_entries, :log_time].include?(p)}
        end.map(&:id)

        User.active.non_system_flag.visible.sorted.
                          joins(:members => :member_roles).
                          where(:member_roles => {:role_id => available_role_ids}).
                          distinct
      end

    end

  end

end
EasyExtensions::PatchManager.register_model_patch 'User', 'EasyBudgetsheet::UserPatch'

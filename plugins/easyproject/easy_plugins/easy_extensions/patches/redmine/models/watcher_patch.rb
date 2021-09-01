module EasyPatch
  module WatcherPatch

    def self.included(base)
      base.include(InstanceMethods)

      base.class_eval do

        belongs_to :group, :foreign_key => 'user_id'
        belongs_to :principal, :foreign_key => 'user_id'

        skip_callback :validate, :before, get_callbacks('validate').select { |callback| callback.filter.try(:attributes) == [:user] && callback.filter.is_a?(ActiveRecord::Validations::PresenceValidator) }.first.try(:filter)

        validates_presence_of :user_id

        before_save :add_group_members_as_watchers

      end
    end

    module InstanceMethods

      GROUP_LIMIT = 6
      USER_LIMIT  = 50

      private

      def add_group_members_as_watchers
        if group
          group.users.pluck(:id).each { |user_id| Watcher.create(:user_id => user_id, :watchable => watchable) }
        end
      end

    end

  end
end
EasyExtensions::PatchManager.register_model_patch 'Watcher', 'EasyPatch::WatcherPatch'

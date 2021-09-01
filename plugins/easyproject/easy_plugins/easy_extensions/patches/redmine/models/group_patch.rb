module EasyPatch
  module GroupPatch

    def self.included(base)

      base.class_eval do
        base.include(InstanceMethods)
      
        validates_length_of :description, maximum: 255

        safe_attributes 'name',
                        'description',
                        'easy_system_flag',
                        'user_ids',
                        'custom_field_values',
                        'custom_fields',
                        'easy_external_id',
                        :if => lambda { |group, current_user| current_user.easy_lesser_admin_for?(:groups) && !group.builtin? }

        has_many :roles, lambda { distinct }, :through => :members
        has_one :easy_avatar, :class_name => 'EasyAvatar', :as => :entity, :dependent => :destroy
        has_one :email_address, lambda { none }, :foreign_key => 'user_id'
        has_many :email_addresses, lambda { none }, :foreign_key => 'user_id'

        alias_method_chain :user_added, :easy_extensions
        alias_method_chain :user_removed, :easy_extensions

        def allowed_to?(action, context, options = {}, &block)
          self.users.each do |user|
            unless user.allowed_to?(action, context, options, &block)
              return false
            end
          end

          return true
        end

        class << self
          def additional_select_options
            User.current.logged? ? { "<< #{l(:label_me_and_my_groups)} >>" => 'me_and_my_groups' } : {}
          end
        end

      end
    end

    module InstanceMethods

      def user_added_with_easy_extensions(user)
        Watcher.where(:group => self).find_each(:batch_size => 100) do |watcher|
          Watcher.create(:user_id => user.id, :watchable_type => watcher.watchable_type, :watchable_id => watcher.watchable_id)
        end
        user_added_without_easy_extensions(user)
      end

      def user_removed_with_easy_extensions(user)
        Watcher.where(:group => self).find_each(:batch_size => 100) do |watcher|
          Watcher.where(:user_id => user.id, :watchable_type => watcher.watchable_type, :watchable_id => watcher.watchable_id).destroy_all
        end
        user_removed_without_easy_extensions(user)
      end

    end

  end
end
EasyExtensions::PatchManager.register_model_patch 'Group', 'EasyPatch::GroupPatch', :after => 'Principal'

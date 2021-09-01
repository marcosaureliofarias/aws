module EasyPatch
  module ActsAsUserReadable

    def self.included(base)
      base.extend(ClassMethods)
    end

    module ClassMethods

      def acts_as_user_readable(options = {})
        return if self.included_modules.include?(EasyPatch::ActsAsUserReadable::ActsAsUserReadableMethods)

        cattr_accessor :user_readable_options
        self.user_readable_options = {}

        if EasyUserReadEntity.table_exists?
          send(:include, EasyPatch::ActsAsUserReadable::ActsAsUserReadableMethods)
        else
          send(:include, EasyPatch::ActsAsUserReadable::ActsAsUserReadableEmptyMethods)
        end

      end

    end

    module ActsAsUserReadableMethods

      def self.included(base)
        base.class_eval do

          has_many :user_read_records, :as => :entity, :class_name => 'EasyUserReadEntity'
          has_many :current_user_read_records, -> { for_user }, :as => :entity, :class_name => 'EasyUserReadEntity'

          after_update :delete_all_user_read_records
          #after_commit :mark_as_read, :on => :create

          def unread?(user = nil)
            user.nil? ? current_user_read_records.empty? : user_read_records.for_user(user).empty?
          end

          def mark_as_read(user = nil)
            user ||= User.current
            EasyExtensions::EasyJobs::UserReadableTask.perform_later(self.id, self.class.name, user.id)
          end

          def delete_all_user_read_records
            if @current_journal && @current_journal.notes.present?
              user_read_records.where.not(user_id: User.current.id).destroy_all
            end
            true
          end
        end
      end

    end

    module ActsAsUserReadableEmptyMethods

      def self.included(base)
        base.class_eval do

          def user_read_records(*)
            []
          end

          def unread?(*)
            nil
          end

          def mark_as_read(*)
            nil
          end

        end
      end

    end

  end
end
EasyExtensions::PatchManager.register_rails_patch 'ActiveRecord::Base', 'EasyPatch::ActsAsUserReadable'

module EasyPatch
  module PrincipalPatch

    def self.included(base)
      base.include(InstanceMethods)
      base.extend(ClassMethods)

      base.class_eval do

        class << self
          alias_method_chain :visible, :easy_extensions
          alias_method_chain :fields_for_order_statement, :easy_extensions

          def disabled_sti_class
            EasyDisabledPrincipal
          end
        end

        has_one :easy_avatar, :class_name => 'EasyAvatar', :as => :entity, :dependent => :destroy
        has_one :email_address, lambda { none }, :foreign_key => 'user_id'
        has_many :email_addresses, lambda { none }, :foreign_key => 'user_id'

        scope :non_system_flag, lambda { where(:easy_system_flag => false) }

      end
    end

    module InstanceMethods

    end

    module ClassMethods

      def visible_with_easy_extensions(*args)
        user = args.first || User.current

        if user.easy_lesser_admin_for?(:users)
          all
        else
          user_arel_table = User.arel_table
          visible_without_easy_extensions(*args).where(user_arel_table[:easy_user_type_id].in(user.easy_user_type.try(:easy_user_visible_type_ids))
                                                           .or(user_arel_table[:id].eq(user.id))
                                                           .or(user_arel_table[:type].not_in(([User] + User.descendants).map(&:name))))
        end
      end

      def fields_for_order_statement_with_easy_extensions(table = nil)
        table   ||= table_name
        columns = ['type'] + (User.name_formatter[:order] - ['id']) + ['lastname', 'id']
        columns.uniq.map { |field| Arel.sql("#{table}.#{field}") }
      end

    end
  end
end
EasyExtensions::PatchManager.register_model_patch 'Principal', 'EasyPatch::PrincipalPatch'

# frozen_string_literal: true

module EasyGraphql
  module Types
    class EasyEntityActivity < Base
      description 'Sales activity'

      self.entity_class = 'EasyEntityActivity'

      field :id, ID, null: false
      field :description, String, null: true
      field :available_types, [EasyGraphql::Types::HashKeyValue], null: true
      field :entity_type, EasyGraphql::Types::HashKeyValue, null: true
      field :entity_id, Integer, null: false
      field :entity_name, String, null: true
      field :start_time, GraphQL::Types::ISO8601DateTime, null: true
      field :end_time, GraphQL::Types::ISO8601DateTime, null: true
      field :category, Types::Enumeration, null: false
      field :categories, [Types::Enumeration], null: true
      field :user_attendees, [Types::User], null: true, method: :easy_entity_activity_users

      if Redmine::Plugin.installed?(:easy_contacts)
        field :contact_attendees, [Types::EasyContact], null: true, method: :easy_entity_activity_contacts
      end

      field :all_day, Boolean, null: true
      field :is_finished, Boolean, null: true
      field :editable_entity, Boolean, null: true

      def categories
        ::EasyEntityActivityCategory.sorted
      end

      # based on plugins/easy_scheduler/patches/easy/easy_extensions/easy_entity_activity_decorator_patch.rb:4
      def available_types
        return [] unless Redmine::Plugin.installed?(:easy_crm) || Redmine::Plugin.installed?(:easy_contacts)

        [easy_crm_case_type, easy_contact_type]
      end

      def entity_type
        object.entity_type == 'EasyCrmCase' ? easy_crm_case_type : easy_contact_type
      end

      def entity_name
        object.entity&.to_s
      end

      private

      def easy_crm_case_type
        { key: 'EasyCrmCase', value: ::I18n.t(:field_easy_crm_case) }
      end

      def easy_contact_type
        { key: 'EasyContact', value: ::I18n.t(:field_easy_contact) }
      end

    end
  end
end

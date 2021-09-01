# frozen_string_literal: true

module EasyGraphql
  module Types
    class EasyMeeting < Base

      self.entity_class = 'EasyMeeting'

      field :id, ID, null: false
      field :name, String, null: false
      field :description, String, null: true
      field :mails, String, null: true
      field :place_name, String, null: true
      field :location, String, null: true
      field :uid, String, null: false
      field :priority, Types::HashKeyValue, null: true
      field :available_priorities, [Types::HashKeyValue], null: true
      field :privacy, Types::HashKeyValue, null: true
      field :available_privacies, [Types::HashKeyValue], null: true
      field :email_notifications, Types::HashKeyValue, null: true
      field :available_email_notifications, [Types::HashKeyValue], null: true
      field :all_day, Boolean, null: true
      field :big_recurring, Boolean, null: true
      field :author, Types::User, null: true
      field :project, Types::Project, null: true
      field :easy_room, Types::EasyRoom, null: true
      field :easy_invitations, [Types::EasyInvitation], null: true
      field :start_time, GraphQL::Types::ISO8601DateTime, null: true
      field :end_time, GraphQL::Types::ISO8601DateTime, null: true
      field :created_at, GraphQL::Types::ISO8601DateTime, null: true
      field :updated_at, GraphQL::Types::ISO8601DateTime, null: true
      field :visible, Boolean, null: true, method: :visible?
      field :editable, Boolean, null: true, method: :editable?

      field :easy_repeat_settings, GraphQL::Types::JSON, null: true
      field :easy_is_repeating, Boolean, null: true
      field :easy_repeat_parent, self, null: true

      field :easy_zoom_enabled, GraphQL::Types::Boolean, null: true

      def easy_zoom_enabled
        ::Redmine::Plugin.installed?(:easy_zoom)
      end

      def author
        object.author if object.author&.visible?
      end

      def project
        object.project if object.project&.visible?
      end

      def priority
        prepare_priority(object.priority)
      end

      def available_priorities
        ::EasyMeeting.priorities.keys.map do |prio|
          prepare_priority(prio)
        end
      end

      def prepare_priority(prio)
        { key: prio, value: ::I18n.t("default_priority_#{prio}") }
      end

      def privacy
        prepare_privacy(object.privacy)
      end

      def available_privacies
        ::EasyMeeting.privacies.keys.map do |priv|
          prepare_privacy(priv)
        end
      end

      def prepare_privacy(priv)
        { key: priv, value: ::I18n.t(privacy_lang_key(priv)) }
      end

      def privacy_lang_key(priv)
        case priv
        when 'xpublic'
          :field_is_public
        when 'xprivate'
          :field_is_private
        when 'confidential'
          :field_is_confidential
        end
      end

      def email_notifications
        prepare_email_notifications(object.email_notifications)
      end

      def available_email_notifications
        ::EasyMeeting.email_notifications.keys.map do |notification|
          prepare_email_notifications(notification)
        end
      end

      def prepare_email_notifications(notification)
        { key: notification, value: ::I18n.t("label_email_notifications.#{notification}") }
      end

      def easy_invitations
        object.easy_invitations.visible
      end

    end
  end
end

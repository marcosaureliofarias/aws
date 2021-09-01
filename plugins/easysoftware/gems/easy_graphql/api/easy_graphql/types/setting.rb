# frozen_string_literal: true

module EasyGraphql
  module Types
    class Setting < Base

      ALLOWED_SETTINGS = {
          redmine: %w(text_formatting date_format time_format attachment_max_size start_of_week issue_done_ratio),
          easy: %w(issue_private_note_as_default enable_private_issues billable_things_default_state),
          time_entry: %w(timelog_comment_editor_enabled)
      }.each_with_object({}) { |(type, settings), hash| settings.each { |setting| hash[setting] = type } }

      field :key, String, 'text_formatting, timelog_comment_editor_enabled, attachment_max_size', null: false, hash_key: 'key'
      field :value, GraphQL::Types::JSON, null: true
      field :project, Types::Project, null: true, hash_key: 'project'

      # Settings are saved in
      #   - Setting
      #   - EasySetting
      #   - Class variables
      #   - EasyMoneySettings
      #   - EasyGlobalTimeEntrySetting
      #   - .......
      #
      # Some are defined on one project, some globally and some are combination of both
      #
      # Some follow project hiararchy
      #
      # Some are visible only for admin
      #
      # Some contains sensitive data (password or access tokens)
      #
      # => Thats why this ugly case
      # => Less ugly but still not the best solution
      def value
        case ALLOWED_SETTINGS[object['key']]
        when :easy
          ::EasySetting.value(object['key'], object['project'].try(:id))
        when :redmine
          if object['key'] == 'date_format'
            ::Setting.date_format.presence || ::I18n.t('date.formats.default')
          else
            ::Setting.send(object['key'])
          end
        when :time_entry
          ::EasyGlobalTimeEntrySetting.value(object['key'], ::User.current.roles)
        else
          raise GraphQL::ExecutionError, "Unknow setting '#{object['key']}'"
        end
      end

    end
  end
end

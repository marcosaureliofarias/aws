# frozen_string_literal: true

module EasyGraphql
  module Types
    class Query < Base

      description 'The query root of app schema'

      field :issue, Types::Issue, null: true do
        description 'Find an issue by ID'
        argument :id, ID, required: true
      end

      field :project, Types::Project, null: true do
        description 'Find a project by ID'
        argument :id, ID, required: true
      end

      field :user, Types::User, null: true do
        description 'Find an user by ID'
        argument :id, ID, required: true
      end

      field :all_issues, [Types::Issue], null: false do
        extension Extensions::EasyQuery, query_klass: EasyIssueQuery
      end

      field :all_projects, [Types::Project], null: false do
        extension Extensions::EasyQuery, query_klass: EasyProjectQuery
      end

      field :all_users, [Types::User], null: false do
        extension Extensions::EasyQuery, query_klass: EasyUserQuery
      end

      field :all_enumerations, [Types::Enumeration], null: false do
        argument :type, String, required: false
      end

      field :all_locales, [Types::Locale], null: false do
        argument :locale, String, required: false
        argument :keys, [String], required: true
      end

      field :attachments_custom_values, [Types::CustomValue], null: true

      field :all_settings, [Types::Setting], null: false do
        argument :keys, [String], required: true
        argument :project_id, ID, required: false
      end

      field :activated_plugins, [String], null: true

      def attachments_custom_values
        ::Attachment.new.visible_custom_field_values
      end

      def issue(id:)
        ::Issue.visible.find_by(id: id)
      end

      def project(id:)
        ::Project.visible.find_by(id: id)
      end

      def user(id:)
        ::User.visible.find_by(id: id)
      end

      def all_enumerations(type: nil)
        scope = ::Enumeration.all
        scope = scope.where(type: type) if type
        scope.to_a
      end

      def all_locales(locale: nil, keys: [])
        locale = locale || ::User.current.language || I18n.locale
        I18n.with_locale(locale) do
          keys.map do |key|
            Types::Locale::Entity.new(key, I18n.t(key))
          end
        end
      end

      def all_settings(keys:, project_id: nil)
        if project_id
          project = ::Project.visible.find_by(id: project_id)

          if !project
            raise GraphQL::ExecutionError, 'Project does not exists or it is not visible'
          end
        end

        keys.map do |key|
          { 'key' => key, 'project' => project }
        end
      end

      def activated_plugins
        ::EasyHostingPlugin.where(activated: true).pluck(:plugin_name)
      end

    end
  end
end

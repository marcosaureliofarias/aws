module EasyExtensions
  class Suggester

    mattr_accessor :types, :additional_search_types
    self.types                   = {}
    self.additional_search_types = []

    def self.get(search_type)
      key   = search_type.to_s.underscore
      klass = types[key] || Common
      klass.new(search_type)
    end

    def self.available_search_types
      default_search_types = Redmine::Search.available_search_types - EasyExtensions::EasyProjectSettings.disabled_features[:suggester_search_types]

      default_search_types | additional_search_types
    end

    def self.add_additional_search_type(type)
      self.additional_search_types << type.to_s
    end

    def self.remove_additional_search_type(type)
      self.additional_search_types.delete(type.to_s)
    end

    # Search acros system
    # Keep it simple stupid becase the method is patched in easy_search gem
    #
    # @param types [Array<String>] allowed things to search
    # @param limit [Integer] max number of returned items
    #
    # @return [Hash{EasyExtensions::Suggester::Common => Array}]
    def self.search(term, types:, limit:, open_projects: false)
      suggested_result = {}

      types.each do |search_type|
        break if limit <= 0

        suggester = EasyExtensions::Suggester.get(search_type)
        result    = suggester.search(term, limit: limit, open_projects: open_projects)

        suggested_result[suggester] = result
        limit                       -= result.size
      end

      suggested_result.delete_if { |_k, v| v.blank? }
      suggested_result
    end

    class Common

      def self.inherited(base)
        type                  = base.name.split('::').last.underscore
        Suggester.types[type] = base
      end

      def initialize(search_type)
        @search_type = search_type
      end

      def search(term, *args)
        entity_klass = @search_type.classify.constantize
        options = args.extract_options!
        options.reverse_merge!(titles_only: true, open_issues: true, open_projects: false)
        entity_klass.search_results(term, User.current, nil, options).to_a
      end

      def render_api(api, entities, view_context)
        category_key     = "label_#{@search_type.singularize}"
        default_category = "#{category_key}_plural"
        category         = I18n.t(category_key, default: I18n.t(default_category))

        entities.each do |entity|
          api.suggest_entity do
            api.value entity.event_title
            api.label entity.event_title
            api.id view_context.url_to_entity(entity, format: nil, jump: view_context.params[:jump])
            api.category category
          end
        end
      end

    end

    class Proposer < Common

      def search(term, *args)
        options = args.extract_options!
        EasyExtensions::ActionProposer.get_items(term, options[:limit])
      end

      def render_api(api, items, view_context)
        category = I18n.t('easy_proposer.action_label')

        items.each do |item|
          api.suggest_entity do
            api.value item.caption
            api.label item.description
            api.id view_context.url_for(item.url)
            api.category category
          end
        end
      end

    end

    class Projects < Common

      def render_api(api, projects, view_context)
        category = I18n.t(:label_project_plural)

        projects.each do |project|
          api.suggest_entity do
            api.value project.to_s
            api.project_id project.id
            api.closed project.closed?
            api.label project.family_name(separator: "\302\240\302\273\302\240")
            api.id view_context.url_to_project(project, format: nil, jump: view_context.params[:jump])
            api.category category
          end
        end
      end

    end

    class Issues < Common

      def render_api(api, issues, view_context)
        category = I18n.t(:label_issue_plural)

        issues.each do |issue|
          api.suggest_entity do
            api.value issue.to_s
            api.label issue.project.to_s
            api.issue_id issue.id
            api.id view_context.url_to_issue(issue, format: nil, jump: view_context.params[:jump])
            api.category category
          end
        end
      end

    end

    class Users < Common

      def render_api(api, users, view_context)
        category = I18n.t(:label_user_plural)

        users.each do |user|
          api.suggest_entity do
            api.value user.to_s
            api.label user.to_s
            api.id view_context.url_to_user(user, format: nil, jump: view_context.params[:jump])
            api.category category
          end
        end
      end

    end

  end
end

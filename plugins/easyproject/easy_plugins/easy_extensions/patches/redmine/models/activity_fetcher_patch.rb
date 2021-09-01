module EasyPatch
  module Activity
    module FetcherPatch

      def self.included(base)
        base.include(InstanceMethods)

        base.class_eval do
          alias_method_chain :initialize, :easy_extensions
        end
      end

      module InstanceMethods

        def initialize_with_easy_extensions(user, options = {})
          options.assert_valid_keys(:project, :with_subprojects, :author, :project_ids, :user, :display_updated, :display_read)
          @user    = user
          @project = options[:project]
          @options = options

          @scope = event_types
        end

        def easy_events_count(from = nil, to = nil, options = {})
          return 0 if !@scope
          e                = 0
          @options[:limit] = options[:limit]

          @scope.each do |event_type|
            constantized_providers(event_type).each do |provider|
              e += provider.easy_find_events(event_type, @user, from, to, @options).count
            end
          end
          e
        end

        def easy_events(from = nil, to = nil, options = {})
          return [] if !@scope
          e                = []
          @options[:limit] = options[:limit]

          @scope.each do |event_type|
            constantized_providers(event_type).each do |provider|
              e.concat(provider.easy_find_events(event_type, @user, from, to, @options).to_a)
            end
          end

          e.sort_by!(&:event_datetime)
          e.reverse!

          if options[:limit]
            e.slice!(options[:limit]..-1)
          end
          e
        end

      end
    end
  end
end
EasyExtensions::PatchManager.register_model_patch 'Redmine::Activity::Fetcher', 'EasyPatch::Activity::FetcherPatch'


module EasyPatch

  module ActsAsActivityProviderMethodsPatch

    def self.included(base)
      base.include(ClassMethods)

      base.class_eval do

      end
    end

    module ClassMethods
      def easy_event_type_name(event_type = nil)
        event_type || self.name.underscore.pluralize
      end

      def easy_find_events(event_type, user, from, to, options)
        provider_options           = activity_provider_options[event_type]
        options[:update_timestamp] = activity_provider_options[:update_timestamp] || provider_options[:timestamp]
        easy_provider_options      = activity_provider_options[:easy_activity_options][event_type] if activity_provider_options[:easy_activity_options]
        raise "#{self.name} can not provide #{event_type} events." if provider_options.nil?

        scope = (provider_options[:scope] || default_provider_scope(provider_options[:global_entity]))

        if from && to
          update_timestamp = provider_options[:timestamp]
          update_timestamp = options[:update_timestamp] if options[:display_updated]
          scope            = scope.where("#{update_timestamp} BETWEEN ? AND ?", from, to)
        end

        if options[:author]
          return scope.none if provider_options[:author_key].nil?
          scope = scope.where("#{provider_options[:author_key]} = ?", options[:author].id)
        end

        if options[:user]
          return scope.none if easy_provider_options.nil? || easy_provider_options[:user_scope].nil?
          scope = easy_provider_options[:user_scope].call(options[:user], scope)
        end

        if options[:project_ids]
          if respond_to?(:easy_activity_custom_project_scope)
            scope = easy_activity_custom_project_scope(scope, options, event_type)
          elsif column_names.include?('project_id')
            scope = scope.where(project_id: options[:project_ids])
          else
            return scope.none
          end
        end

        if options[:limit]
          # id and creation time should be in same order in most cases
          scope = scope.reorder("#{table_name}.id DESC").limit(options[:limit])
        end

        if provider_options.has_key?(:global_entity)
          entity = provider_options[:global_entity].safe_constantize
          scope = if entity.respond_to?(:visible)
                    scope.merge(entity.visible(user, options))
                  else
                    scope.none
                  end
        elsif provider_options.has_key?(:permission)
          scope = scope.where(Project.allowed_to_condition(user, provider_options[:permission] || :view_project, options))
        elsif respond_to?(:visible)
          scope = scope.visible(user, options)
        else
          ActiveSupport::Deprecation.warn "acts_as_activity_provider with implicit :permission option is deprecated. Add a visible scope to the #{self.name} model or use explicit :permission option."
          scope = scope.where(Project.allowed_to_condition(user, "view_#{self.name.underscore.pluralize}".to_sym, options))
        end

        # options[:display_read] do not remove already seen events
        if !options[:display_read] && self.respond_to?(:user_readable_options)
          arel_table = self.arel_table

          self_table = self.arel_table
          eure_table = EasyUserReadEntity.arel_table
          j          = self_table.join(eure_table, Arel::Nodes::OuterJoin).
              on(eure_table[:user_id].eq(user.id).and(self_table[:id].eq(eure_table[:entity_id])).and(eure_table[:entity_type].eq(self.name))).
              join_sources
          scope      = scope.joins(j).where(eure_table[:user_id].eq(nil))

          #scope = scope.includes(:user_read_records)
          #eure_table = EasyUserReadEntity.arel_table
          #scope = scope.where(scope.where(eure_table[:user_id].eq(user.id)).exists.not)
          #scope = scope.includes(:user_read_records).where(EasyUserReadEntity.arel_table[:user_id].not_eq(user.id))
        end

        scope.distinct
      end

      def default_provider_scope(global_entity)
        entity = global_entity.safe_constantize if global_entity.present?
        if entity.present?
          self.joins("JOIN #{entity.table_name} ON journalized_id = #{entity.table_name}.id").
              joins("LEFT OUTER JOIN #{JournalDetail.table_name} ON #{JournalDetail.table_name}.journal_id = #{Journal.table_name}.id").
              where("#{Journal.table_name}.journalized_type = '#{global_entity}' AND" +
                        " (#{JournalDetail.table_name}.prop_key = 'status_id' OR #{Journal.table_name}.notes <> '')").distinct
        else
          self
        end
      end
    end

  end

  module ActsAsActivityProviderClassMethodsPatch
    def self.included(base)
      base.include(ClassMethods)

      base.class_eval do
        alias_method_chain :acts_as_activity_provider, :easy_extensions
      end
    end

    module ClassMethods
      def acts_as_activity_provider_with_easy_extensions(options = {})
        unless self.included_modules.include?(Redmine::Acts::ActivityProvider::InstanceMethods)
          cattr_accessor :activity_provider_options
          send :include, Redmine::Acts::ActivityProvider::InstanceMethods
        end

        options.assert_valid_keys(:type, :permission, :timestamp, :author_key, :scope, :global_entity)
        self.activity_provider_options ||= {}

        # One model can provide different event types
        # We store these options in activity_provider_options hash
        event_type = options.delete(:type) || self.name.underscore.pluralize

        options[:timestamp] ||= "#{table_name}.created_on"
        options[:author_key] = "#{table_name}.#{options[:author_key]}" if options[:author_key].is_a?(Symbol)
        self.activity_provider_options[event_type] = options
      end
    end
  end

end
EasyExtensions::PatchManager.register_patch_to_be_first 'Redmine::Acts::ActivityProvider::InstanceMethods::ClassMethods', 'EasyPatch::ActsAsActivityProviderMethodsPatch', :first => true
EasyExtensions::PatchManager.register_patch_to_be_first 'Redmine::Acts::ActivityProvider::ClassMethods', 'EasyPatch::ActsAsActivityProviderClassMethodsPatch', :first => true

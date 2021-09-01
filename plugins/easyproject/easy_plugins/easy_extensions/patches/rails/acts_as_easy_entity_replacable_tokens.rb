module EasyPatch
  module ActsAsEasyEntityReplacableTokens

    def self.included(base)
      base.extend(ClassMethods)
    end

    module ClassMethods

      def acts_as_easy_entity_replacable_tokens(options = {})
        return if self.included_modules.include?(EasyPatch::ActsAsEasyEntityReplacableTokens::ActsAsEasyEntityReplacableTokensMethods)

        cattr_accessor :easy_entity_replacable_tokens_options
        self.easy_entity_replacable_tokens_options = {}

        self.easy_entity_replacable_tokens_options[:easy_query_class] = options.delete(:easy_query_class)
        self.easy_entity_replacable_tokens_options[:token_prefix]     = (options.delete(:token_prefix) || self.name.underscore)

        send(:include, EasyPatch::ActsAsEasyEntityReplacableTokens::ActsAsEasyEntityReplacableTokensMethods)
      end

    end

    module ActsAsEasyEntityReplacableTokensMethods

      def self.included(base)
        base.extend ClassMethods
        base.send :include, InstanceMethods
      end

      module ClassMethods

        def easy_entity_replacable_tokens_list(project = nil)
          eqc    = self.easy_entity_replacable_tokens_options[:easy_query_class]
          tokens = []

          if eqc
            query         = eqc.new
            query.project = project

            query.available_columns.each do |column|
              tokens << ["#{self.easy_entity_replacable_tokens_options[:token_prefix]}_#{column.name}", column]
            end
          end

          tokens
        end

      end

      module InstanceMethods

        def add_easy_entity_replacable_token(token, column)
          @easy_entity_replacable_tokens ||= []
          @easy_entity_replacable_tokens << [token, column]
        end

        def easy_entity_replacable_tokens
          create_easy_entity_replacable_tokens_from_easy_query
          @easy_entity_replacable_tokens || []
        end

        def create_easy_entity_replacable_tokens_from_easy_query
          return nil if @easy_entity_replacable_tokens_from_easy_query_added
          eqc = self.class.easy_entity_replacable_tokens_options[:easy_query_class]

          if eqc
            query         = eqc.new
            query.project = project if respond_to?(:project)

            query.available_columns.each do |column|
              token = "#{self.class.easy_entity_replacable_tokens_options[:token_prefix]}_#{column.name}"

              add_easy_entity_replacable_token(token, column)
            end

            @easy_entity_replacable_tokens_from_easy_query_added = true
          end
        end

      end
    end

  end
end
EasyExtensions::PatchManager.register_rails_patch 'ActiveRecord::Base', 'EasyPatch::ActsAsEasyEntityReplacableTokens'

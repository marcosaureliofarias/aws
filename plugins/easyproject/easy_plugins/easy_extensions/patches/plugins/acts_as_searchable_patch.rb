module EasyPatch
  module ActsAsSearchablePatch

    def self.included(base)
      base.include InstanceMethods

      base.class_eval do

        alias_method_chain :search_result_ranks_and_ids, :easy_extensions
        alias_method_chain :search_results_from_ids, :easy_extensions
        alias_method_chain :search_token_match_statement, :easy_extensions
        alias_method_chain :search_scope, :easy_extensions

      end
    end

    module InstanceMethods

      def search_token_match_statement_with_easy_extensions(column, value = '?')
        column = "CAST(#{column} AS TEXT)" if column == "#{self.table_name}.id" && Redmine::Database.postgresql?
        search_token_match_statement_without_easy_extensions(column, value)
      end

      def search_result_ranks_and_ids_with_easy_extensions(tokens, user = User.current, projects = nil, options = {})
        tokens   = [] << tokens unless tokens.is_a?(Array)
        projects = [] << projects if projects.is_a?(Project)

        columns = searchable_options[:columns]
        columns = searchable_options[:title_columns] || columns[0..0] if options[:titles_only]

        r       = []
        queries = 0

        unless options[:attachments] == 'only'
          r       = fetch_ranks_and_ids(
              search_scope(user, projects, options).
                  where(search_tokens_condition(columns, tokens, options[:all_words])),
              options[:limit]
          )
          queries += 1

          if !options[:titles_only] && searchable_options[:search_custom_fields]
            searchable_custom_fields = CustomField.where(:type => "#{self.name}CustomField", :searchable => true).to_a

            if searchable_custom_fields.any?
              fields_by_visibility = searchable_custom_fields.group_by { |field|
                field.visibility_by_project_condition(searchable_options[:project_key].presence, user, "#{CustomValue.table_name}.custom_field_id")
              }
              clauses              = []
              fields_by_visibility.each do |visibility, fields|
                clauses << "(#{CustomValue.table_name}.custom_field_id IN (#{fields.map(&:id).join(',')}) AND (#{visibility}))"
              end
              visibility = clauses.join(' OR ')

              r       |= fetch_ranks_and_ids(
                  search_scope(user, projects, options).
                      joins(:custom_values).
                      where(visibility).
                      where(search_tokens_condition(["#{CustomValue.table_name}.value"], tokens, options[:all_words])),
                  options[:limit]
              )
              queries += 1
            end
          end

          if !options[:titles_only] && searchable_options[:search_journals]
            r       |= fetch_ranks_and_ids(
                search_scope(user, projects, options).
                    joins(:journals).
                    where("#{Journal.table_name}.private_notes = ? OR (#{Project.allowed_to_condition(user, :view_private_notes)})", false).
                    where(search_tokens_condition(["#{Journal.table_name}.notes"], tokens, options[:all_words])),
                options[:limit]
            )
            queries += 1
          end
        end

        if searchable_options[:search_attachments] && (options[:titles_only] ? options[:attachments] == 'only' : options[:attachments] != '0')
          r       |= fetch_ranks_and_ids(
              search_scope(user, projects, options).
                  joins(:attachments).
                  where(search_tokens_condition(["#{Attachment.table_name}.filename", "#{Attachment.table_name}.description"], tokens, options[:all_words])),
              options[:limit]
          )
          queries += 1
        end

        if queries > 1
          r = r.sort.reverse
          if options[:limit] && r.size > options[:limit]
            r = r[0, options[:limit]]
          end
        end

        r
      end

      def search_results_from_ids_with_easy_extensions(ids)
        order = (self == Project) ? "#{Project.table_name}.lft" : searchable_options[:title_columns].try(:first)
        where(id: ids).preload(searchable_options[:preload]).order(order).to_a
      end

      def search_scope_with_easy_extensions(user, projects, options={})
        if projects.is_a?(Array) && projects.empty?
          # no results
          return none
        end

        scope = (searchable_options[:scope] || self)
        if scope.is_a? Proc
          scope = scope.call(options)
        end

        if respond_to?(:visible) && !searchable_options.has_key?(:permission)
          scope = scope.visible(user)
        else
          permission = searchable_options[:permission] || :view_project
          scope = scope.where(Project.allowed_to_condition(user, permission))
        end

        if projects && searchable_options[:project_key].present?
          scope = scope.where("#{searchable_options[:project_key]} IN (?)", projects.map(&:id))
        end
        scope
      end

    end

  end
end
EasyExtensions::PatchManager.register_redmine_plugin_patch 'Redmine::Acts::Searchable::InstanceMethods::ClassMethods', 'EasyPatch::ActsAsSearchablePatch'

module EasyPatch
  module ActiveRecordRelationPatch

    def self.included(base)

      base.class_eval do

        # delete after accept of MR https://github.com/rails/rails/pull/27249 and update to coresponding version of rails
        # reason to patch is obvious from test in pull request - problems in grouping and limiting with has_many associations
        def limited_ids_for_with_easy_extensions(relation)
          if connection.respond_to?(:column_name_from_arel_node) # master
            col    = if group_values.empty?
                       arel_attribute(primary_key)
                     else
                       arel_attribute(primary_key).minimum.as(primary_key)
                     end
            values = @klass.connection.columns_for_distinct(
                connection.column_name_from_arel_node(col),
                relation.order_values
            )

            relation = relation.except(:select).select(values).distinct!

            id_rows = skip_query_cache_if_necessary { @klass.connection.select_all(relation.arel, "SQL") }
            id_rows.map { |row| row[primary_key] }
          else # 5.1.4
            col    = "#{quoted_table_name}.#{quoted_primary_key}"
            col    = "MIN(#{col}) AS #{primary_key}" unless group_values.empty?
            values = @klass.connection.columns_for_distinct(
                col, relation.order_values)

            relation = relation.except(:select).select(values).distinct!
            arel     = relation.arel

            id_rows = @klass.connection.select_all(arel, "SQL", relation.bound_attributes)
            id_rows.map { |row| row[primary_key] }
          end
        end

        alias_method_chain :limited_ids_for, :easy_extensions

      end
    end

  end
end

EasyExtensions::PatchManager.register_patch_to_be_first 'ActiveRecord::Relation', 'EasyPatch::ActiveRecordRelationPatch', :first => true

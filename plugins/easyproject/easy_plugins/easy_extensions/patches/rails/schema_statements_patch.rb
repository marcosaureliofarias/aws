module EasyPatch
  module SchemaStatementsPatch

    def self.included(base)
      base.class_eval do
        def add_easy_uniq_index(table_name, column_name, options = {})
          options[:unique] = true
          return if index_exists? table_name, column_name, options
          return if ActiveRecord::Base.connection.primary_key(table_name).is_a?(Array)

          if Redmine::Database.mysql?
            begin
              add_index table_name, column_name, options
            rescue ActiveRecord::RecordNotUnique
              remove_duplicities(table_name, column_name)
              add_index table_name, column_name, options
            end
          else # other adapters may not support InFailedSqlTransactions
            remove_duplicities(table_name, column_name)
            add_index table_name, column_name, options
          end
        end

        private

        def remove_duplicities(table_name, column_name)
          distinct_columns = Array(column_name).map(&:to_s).join(', ')
          ActiveRecord::Base.transaction do
            primary_key = ActiveRecord::Base.connection.primary_key(table_name)
            unless primary_key
              primary_key = 'fake_id'
              add_column table_name, primary_key, :primary_key
              fake_key = true
            end
            ActiveRecord::Base.connection.execute("DELETE FROM #{table_name} WHERE #{primary_key} NOT IN (SELECT * FROM (SELECT MAX(#{primary_key}) FROM #{table_name} GROUP BY #{distinct_columns}) AS r)")
            remove_column table_name, primary_key if fake_key
          end
        end
      end
    end
  end
end
EasyExtensions::PatchManager.register_rails_patch 'ActiveRecord::ConnectionAdapters::SchemaStatements', 'EasyPatch::SchemaStatementsPatch'

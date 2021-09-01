class AddOutputsToEasyQueries < ActiveRecord::Migration[4.2]
  def up
    EasyQuery.delete_invalid_subclasses

    add_column :easy_queries, :outputs, :string, default: ['list'].to_yaml unless column_exists?(:easy_queries, :outputs)
    EasyQuery.reset_column_information
    EasyQuery.all.each do |eq|
      out = ['chart', 'calendar'].select { |o| eq.__send__("#{o}?") }
      out << 'list' if eq.table?
      eq.update_column(:outputs, out)
    end
    remove_column :easy_queries, :table
    remove_column :easy_queries, :chart
    remove_column :easy_queries, :calendar
  end

  def down
    remove_column :easy_queries, :outputs
    add_column :easy_queries, :table, :boolean, default: true
    add_column :easy_queries, :chart, :boolean, default: false
    add_column :easy_queries, :calendar, :boolean, default: false
  end
end

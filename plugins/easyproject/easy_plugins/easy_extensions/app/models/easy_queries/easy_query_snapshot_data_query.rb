class EasyQuerySnapshotDataQuery < EasyQuery

  self.queried_class = EasyQuerySnapshotData

  attr_accessor :source_query

  def self.chart_support?
    true
  end

  def is_snapshot?
    true
  end

  def snapshotable_columns?
    @source_query.present? && @source_query.inline_columns.select(&:sumable_header?).any?
  end

  def initialize_available_filters
    add_available_filter 'easy_query_snapshot_id', { type: :integer, group: default_group_label }
  end

  def initialize_available_columns
    group = default_group_label
    add_available_column EasyQueryColumn.new(:value1, sumable: :both, group: group)
    add_available_column EasyQueryDateColumn.new(:date, groupable: true, group: group)
  end

  def path(options = {})
    if self.filters['easy_query_snapshot_id'] && self.filters['easy_query_snapshot_id']['operator'] == '='
      if easy_query_snapshot = EasyQuerySnapshot.where(id: self.filters['easy_query_snapshot_id']['values'][0]).first
        easy_query_snapshot.create_easy_query.path options
      end
    end
  end

end

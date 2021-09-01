class EasyQuerySnapshotData < ActiveRecord::Base

  self.table_name = 'easy_query_snapshot_data'

  belongs_to :easy_query_snapshot

end

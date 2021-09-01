class EasyQuerySnapshot < ActiveRecord::Base

  belongs_to :execute_as_user, class_name: 'User', foreign_key: 'execute_as_user_id'
  belongs_to :author, class_name: 'User'

  has_many :easy_query_snapshot_data, class_name: 'EasyQuerySnapshotData', dependent: :destroy

  scope :run_at, ->(time) { where(["#{EasyQuerySnapshot.table_name}.nextrun_at IS NULL OR #{EasyQuerySnapshot.table_name}.nextrun_at <= ?", time]) }
  scope :run_now, -> { run_at(Time.now) }

  serialize :period_options, Hash

  store :settings, accessors: [], coder: JSON

  def create_easy_query
    if easy_query_id.present?
      EasyQuery.find_by(id: easy_query_id)
    elsif epzm_uuid.present?
      epzm = EasyPageZoneModule.find_by(uuid: epzm_uuid)
      epzm.module_definition.get_query(epzm.get_settings, nil, { project: nil }) if epzm && epzm.module_definition
    end
  end

  def executable_user
    @executable_user ||= case self.execute_as
                         when 'author'
                           self.author
                         when 'user'
                           self.execute_as_user
                         end

    @executable_user || self.author || User.current
  end

end

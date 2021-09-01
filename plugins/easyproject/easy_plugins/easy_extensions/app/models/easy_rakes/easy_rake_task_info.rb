class EasyRakeTaskInfo < ActiveRecord::Base

  STATUS_PLANNED      = 0
  STATUS_RUNNING      = 1
  STATUS_ENDED_OK     = 5
  STATUS_ENDED_FORCED = 8
  STATUS_ENDED_FAILED = 9

  belongs_to :easy_rake_task
  has_many :easy_rake_task_info_details, :dependent => :destroy

  scope :status_ok, lambda { where(:status => EasyRakeTaskInfo::STATUS_ENDED_OK) }
  scope :status_failed, lambda { where(:status => [EasyRakeTaskInfo::STATUS_ENDED_FORCED, EasyRakeTaskInfo::STATUS_ENDED_FAILED]) }
  scope :status_planned, lambda { where(:status => EasyRakeTaskInfo::STATUS_PLANNED) }
  scope :status_running, lambda { where(:status => EasyRakeTaskInfo::STATUS_RUNNING) }

  store :options, coder: JSON

  def planned?
    status == STATUS_PLANNED
  end

  def running?
    status == STATUS_RUNNING
  end

  def ok?
    status == STATUS_ENDED_OK
  end

  def failed?
    [EasyRakeTaskInfo::STATUS_ENDED_FORCED, EasyRakeTaskInfo::STATUS_ENDED_FAILED].include?(status)
  end

end

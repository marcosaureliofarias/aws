class EasyIcalendar < ActiveRecord::Base
  belongs_to :user
  has_many :events, class_name: 'EasyIcalendarEvent', dependent: :destroy

  attr_accessor :in_background
  alias :in_background? :in_background

  enum status: [:pending, :in_progress, :failed, :success]
  enum visibility: [:is_public, :is_private, :is_invisible]

  scope :not_running, -> { where.not(status: EasyIcalendar.statuses[:in_progress]) }
  before_validation :set_user_id
  after_initialize :set_visibility

  validates_presence_of :name, :url, :status, :user

  after_commit :import_events, on: :create, if: -> { pending? }

  def url=(url)
    super(url&.strip)
  end

  def failed_import!(msg)
    self.last_run_at = Time.now
    self.status = :failed
    self.message = msg&.truncate(30_000) # limit of text columns in db
    self.save!
  end

  def success_import!
    self.last_run_at = Time.now
    self.status = :success
    self.message = ''
    self.synchronized_at = Time.now # time of sucess synchronization
    self.save!
  end
  
  private

  def set_user_id
    self.user_id ||= User.current.id
  end

  def set_visibility
    self.visibility ||= :is_public
  end

  def import_events
    ImportIcalEventsJob.perform_later(self)
  end

end

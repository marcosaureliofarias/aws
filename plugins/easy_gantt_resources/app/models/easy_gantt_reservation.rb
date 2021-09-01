class EasyGanttReservation < ActiveRecord::Base

  belongs_to :assigned_to, class_name: 'Principal', foreign_key: 'assigned_to_id'
  belongs_to :project
  has_many :resources, class_name: 'EasyGanttReservationResource',
                       foreign_key: 'easy_gantt_reservation_id',
                       dependent: :destroy

  validates_presence_of :assigned_to_id, :start_date, :due_date, :name

  attr_accessor :original_id

  accepts_nested_attributes_for :resources

  def resources_attributes=(*args)
    resources.each{|d| d.mark_for_destruction }
    super
  end

  def safe_attributes=(attrs)
    attrs = attrs.to_unsafe_hash.symbolize_keys if attrs.respond_to?(:to_unsafe_hash)
    self.name = attrs[:name]
    self.project_id = attrs[:project_id]
    self.estimated_hours = attrs[:estimated_hours] || 0
    self.start_date = attrs[:start_date] || User.current.today
    self.due_date = attrs[:due_date]
    self.allocator = attrs[:allocator] || 'evenly'
    self.author_id ||= User.current.id
    self.assigned_to_id = attrs[:assigned_to_id] || User.current.id
    self.description = attrs[:description]
  end

end

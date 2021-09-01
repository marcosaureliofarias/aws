class EasyIntegration < ActiveRecord::Base
  include Easy::Redmine::BasicEntity

  belongs_to :easy_oauth2_client_application, optional: true
  belongs_to :execute_as_user, optional: true, class_name: "User"
  has_many :easy_integration_logs, dependent: :destroy

  scope :active, -> { where(active: true) }
  scope :periodical, -> { where(on_time: true).where(EasyIntegration.arel_table[:next_run_at].lteq(Time.now)) }

  safe_attributes 'name', 'metadata_klass', 'metadata_settings',
                  'active', 'perform_once',
                  'on_create', 'on_update', 'on_destroy', 'on_time',
                  'use_query', 'query_settings',
                  'use_journal', 'cron_expr', 'easy_oauth2_client_application_id'

  validates :name, :entity_klass, :metadata_klass, :service_klass, presence: true
  validate :validate_query_attributes, if: ->(easy_integration) { easy_integration.use_query? }
  validate :validate_service_settings

  after_commit :set_next_run, on: [:create, :update]

  def self.find_for(entity, action)
    scope = self.active.where(entity_klass: entity.class)
    scope = case action.to_s
            when 'create'
              scope.where(on_create: true)
            when 'update'
              scope.where(on_update: true)
            when 'destroy'
              scope.where(on_destroy: true)
            when 'time'
              scope.where(on_time: true)
            end
    scope.select { |easy_integration| !easy_integration.can_perform_on?(entity, action) }
  end

  def metadata
    @metadata ||= metadata_klass.safe_constantize&.new
  end

  def service
    @service ||= service_klass.safe_constantize&.new(self)
  end

  def can_perform_on?(entity, action)
    perform_once? ? easy_integration_logs.where(entity: entity).none? : true
  end

  private

  def set_next_run
    return nil if cron_expr.blank?

    c = Fugit::Cron.parse(cron_expr)
    time = c.next_time if c
    update_column(:next_run_at, time.utc) if time
  end

  def validate_query_attributes
    errors.add(:query_settings, 'query_settings must be present') if query_settings.blank?
    errors.add(:execute_as_user_id, 'execute_as_user must be present') unless execute_as_user
  end

  def validate_service_settings
    service.validate_settings
  end

end

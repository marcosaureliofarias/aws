class EasyCrmCaseStatus < ActiveRecord::Base

  STATUS_FIELDS = %w(is_paid is_won is_closed is_provisioned)

  include Redmine::SafeAttributes

  has_many :easy_crm_cases
  has_and_belongs_to_many :custom_fields, class_name: 'EasyCrmCaseCustomField', join_table: "#{table_name_prefix}custom_fields_easy_crm_case_status#{table_name_suffix}", association_foreign_key: 'custom_field_id'

  validates :name, :presence => true

  scope :sorted, lambda { order("#{table_name}.position ASC") }
  scope :active, lambda { where(is_won: false, is_closed: false) }

  acts_as_positioned

  before_save :check_default

  safe_attributes 'name', 'is_default', 'reorder_to_position', 'position', 'is_easy_contact_required', 'is_closed', 'is_won', 'is_paid', 'show_in_search_results', 'only_for_admin', 'is_provisioned'

  def self.default
    EasyCrmCaseStatus.find_by(is_default: true) || EasyCrmCaseStatus.first
  end

  def to_s
    self.name
  end

  private

  def check_default
    if is_default? && is_default_changed?
      EasyCrmCaseStatus.update_all(is_default: false)
    end
  end

end

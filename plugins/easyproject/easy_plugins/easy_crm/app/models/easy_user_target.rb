class EasyUserTarget < ActiveRecord::Base

  INVOICE_COMPARE_COLUMNS = ['subtotal', 'total', 'paid_amount']
  CRM_CASE_COMPARE_COLUMNS = ['price']

  include Redmine::SafeAttributes

  belongs_to :user

  validates :target, :user_id, presence: true
  validates :target, numericality: {greater_than_or_equal_to: 0}

  acts_as_easy_currency(:target, :currency, :valid_from)

  safe_attributes *%w{ target valid_from valid_to user_id currency }

  scope :visible, -> {all}

end
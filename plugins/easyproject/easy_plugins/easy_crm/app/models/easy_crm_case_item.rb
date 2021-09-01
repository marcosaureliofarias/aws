class EasyCrmCaseItem < ActiveRecord::Base
  include Redmine::SafeAttributes

  set_associated_query_class EasyCrmCaseItemQuery

  belongs_to :easy_crm_case, inverse_of: :easy_crm_case_items

  after_destroy :recalculate_crm_case

  before_validation :set_default_values

  validates :name, :presence => true, length: 0..255
  validates :easy_crm_case, :amount, :price_per_unit, :total_price, :presence => true
  validates_numericality_of :amount, :price_per_unit, :total_price
  validates :discount, :numericality => {:greater_than_or_equal_to => 0, :less_than_or_equal_to => 100}

  acts_as_positioned :scope => :easy_crm_case_id
  acts_as_easy_currency(:price_per_unit, :currency, :date_for_price_recalculation)
  acts_as_easy_currency(:total_price, :currency, :date_for_price_recalculation)
  acts_as_easy_entity_replacable_tokens :easy_query_class => EasyCrmCaseItemQuery

  scope :sorted, lambda { order("#{table_name}.position ASC") }

  safe_attributes 'easy_crm_case_id', 'name', 'description', 'total_price', 'product_code', 'amount', 'unit', 'price_per_unit', 'discount', 'position', 'reorder_to_position', 'easy_external_id'

  def self.css_icon
    'icon icon-reorder'
  end

  def self.human_attribute_name(attribute, options = {})
    I18n.t("activerecord.attributes.easy_crm_case.easy_crm_case_items.#{attribute}", options)
  end

  def date_for_price_recalculation
    easy_crm_case.contract_date || updated_at
  end

  def currency
    easy_crm_case.currency unless easy_crm_case.nil?
  end

  def recalculate_crm_case
    easy_crm_case.save
  end

  def set_default_values
    self.discount = EasyCrmCaseItem.columns_hash['discount'].default if discount.blank?
  end

end

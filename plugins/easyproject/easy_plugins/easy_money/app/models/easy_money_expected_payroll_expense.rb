class EasyMoneyExpectedPayrollExpense < ActiveRecord::Base
  extend EasyMoney::EasyCurrencyRecalculateMixin

  belongs_to :project
  belongs_to :entity, :polymorphic => true
  belongs_to :easy_currency, foreign_key: :easy_currency_code, primary_key: :iso_code

  validates :entity_type, :presence => true
  validates :entity_id, :presence => true
  validates_numericality_of :price, :allow_nil => false, :only_integer => false, :greater_than_or_equal_to => 0.0

  before_save :update_project_id

  acts_as_easy_currency :price, :easy_currency_code

  def project_from_entity
    case self.entity_type
    when 'Project'
      self.entity
    else
      self.entity.project if self.entity.respond_to?(:project)
    end
  end

  def update_project_id
    self.project_id = project_from_entity.try(:id)
  end

end

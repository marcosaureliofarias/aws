class EasyMoneyRateType < ActiveRecord::Base
  class STATUS
    ACTIVE     = 1
    ARCHIVED   = 9
  end

  self.table_name = 'easy_money_rate_types'

  RATE_TYPE_CACHE = EasyMoney::EasyMoneyRateTypeCache.new(:id, :name)

  default_scope{order("#{EasyMoneyRateType.table_name}.position ASC")}

  acts_as_positioned

  validates :name, :presence => true

  scope :active, lambda { where(["#{EasyMoneyRateType.table_name}.status = ?", EasyMoneyRateType::STATUS::ACTIVE]) }
  scope :archived, lambda { where(["#{EasyMoneyRateType.table_name}.status = ?", EasyMoneyRateType::STATUS::ARCHIVED]) }

  before_save :set_default
  before_save :change_name
  after_create :expire_cache
  after_save :expire_cache, :if => Proc.new{|x| x.saved_change_to_name? || x.saved_change_to_active?}
  after_destroy :expire_cache

  def self.default
    where(:is_default => true).first
  end

  def self.rate_type_cache(conditions = {})
    rates = Rails.cache.fetch('rate_type_cache') do
      self.active.pluck(:id, :name).map do |r|
        RATE_TYPE_CACHE.new(r[0], r[1])
      end
    end
    if conditions.any?
      conditions.slice(:id, :name).each do |condition, value|
        return rates.detect{|rate| rate.send(condition) == value }
      end
    else
      rates
    end
  end

  def translated_name
    I18n.t("easy_money_rate_type.#{name}").html_safe
  end

  private

  def expire_cache
    Rails.cache.delete('rate_type_cache')
  end

  def set_default
    if is_default? && is_default_changed?
      EasyMoneyRateType.update_all(:is_default => false)
    end
    return true
  end

  def change_name
    self.name = self.name.tr(' ', '_').underscore unless self.name.blank?
    true
  end

end

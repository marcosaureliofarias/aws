class EasyCurrencyExchangeRate < ActiveRecord::Base

  validates :rate, numericality: { greater_than: 0.to_d }, :allow_nil => true

  validate :validate_date_lock

  belongs_to :base_currency, class_name: 'EasyCurrency', primary_key: :iso_code, foreign_key: :base_code
  belongs_to :target_currency, class_name: 'EasyCurrency', primary_key: :iso_code, foreign_key: :to_code

  scope :rates_by_iso, ->(base_iso_code, date) {
    joins(<<-SQL).select(:valid_on, :to_code, :rate)
      INNER JOIN (SELECT sub.base_code as sub_base, MAX(sub.valid_on) as max_valid_on FROM easy_currency_exchange_rates AS sub
      WHERE sub.base_code = #{self.connection.quote(base_iso_code)} AND sub.valid_on <= #{self.connection.quote(date)}
      GROUP BY sub.base_code) AS GroupDT
      ON easy_currency_exchange_rates.base_code = GroupDT.sub_base
      AND easy_currency_exchange_rates.valid_on = GroupDT.max_valid_on
    SQL
  }

  class << self
    def find_exchange_rate(base_currency, to_currency, date = nil)
      scope = find_exchange_rate_scope(base_currency, to_currency)
      scope.where('valid_on <= ?', date).order(valid_on: :desc).limit(1).first || scope.where(valid_on: nil).limit(1).first
    end

    def find_exchange_rate_value(base_currency, to_currency, date = nil)
      return 1 if base_currency == to_currency
      scope = find_exchange_rate_scope(base_currency, to_currency)
      scope.where('valid_on <= ?', date).order(valid_on: :desc).limit(1).pluck(:rate).first || scope.where(valid_on: nil).limit(1).pluck(:rate).first
    end

    def recalculate(base_currency, to_currency, value, date = nil)
      return value if base_currency.nil? || to_currency.nil? || base_currency == to_currency || !value.is_a?(Numeric)
      if (exchange_rate = self.find_exchange_rate_value(base_currency, to_currency, date))
        exchange_rate.to_d * value
      else
        value
      end
    end
  end

  def reverse_pair_rate(date)
    (1 / EasyCurrencyExchangeRate.find_exchange_rate_value(base_currency, target_currency, date).to_d).to_d
  end

  def reverse_pair(date = nil)
    EasyCurrencyExchangeRate.find_exchange_rate(target_currency, base_currency, date)
  end

  private

  def self.find_exchange_rate_scope(base_currency, to_currency)
    base_code   = base_currency.is_a?(EasyCurrency) ? base_currency.iso_code : base_currency
    target_code = to_currency.is_a?(EasyCurrency) ? to_currency.iso_code : to_currency
    EasyCurrencyExchangeRate.where(base_code: base_code, to_code: target_code)
  end

  def validate_date_lock
    return if EasySetting.value(:easy_currency_exchange_rates).nil? || EasySetting.value(:easy_currency_exchange_rates)[:locked_after_months].blank? || !valid_on
    lock_date = Date.today.advance(months: EasySetting.value(:easy_currency_exchange_rates)[:locked_after_months].to_i * -1)
    errors.add(:date, l(:date_is_locked)) if lock_date > valid_on
  end

end

class EasyCurrency < ActiveRecord::Base
  include Redmine::SafeAttributes

  class NotConfiguredError < StandardError;
  end

  has_many :exchange_rates_from, class_name: 'EasyCurrencyExchangeRate', foreign_key: :base_code, dependent: :destroy, primary_key: :iso_code
  has_many :exchange_rates_to, class_name: 'EasyCurrencyExchangeRate', foreign_key: :to_code, dependent: :destroy, primary_key: :iso_code
  has_many :projects, foreign_key: :easy_currency_code, primary_key: :iso_code, inverse_of: :easy_currency

  validates :name, presence: true
  validates :iso_code, length: { is: 3 }, presence: true, uniqueness: true
  validate :validate_max_activated

  safe_attributes 'name', 'iso_code', 'digits_after_decimal_separator', 'symbol', 'activated', 'project_ids', 'is_default'

  after_create :create_exchange_rates, :ensure_synchronize_task
  before_save :check_default
  after_save :invalidate_currencies_setup
  after_save :invalidate_cache
  after_update :notify_admins
  after_destroy :invalidate_cache

  ACTIVATED_CURRENCY_LIMIT = 6

  ISO_PATH = File.join EasyExtensions::EASYPROJECT_EASY_PLUGINS_DIR, 'easy_extensions', 'assets', 'xml_data_store', 'iso.xml'

  COUNTRY_MAPPING_ISO_PATH = File.join EasyExtensions::EASYPROJECT_EASY_PLUGINS_DIR, 'easy_extensions', 'assets', 'xml_data_store', 'iso_country_currency_mapping.xml'

  scope :activated, -> { where(activated: true).sorted }
  scope :non_activated, -> { where(activated: [false, nil]) }
  scope :sorted, -> { order(:iso_code) }

  def self.get_currency_list
    saved = active_currencies_codes
    data  = []
    File.open(ISO_PATH) { |f| data = Hash.from_xml(f)['ISO_4217']['CcyTbl']['CcyNtry'] }
    data.reject { |x| saved.include?(x['Ccy']) || x['Ccy'].nil? }.uniq { |x| x['Ccy'] }.sort_by { |x| /EUR|USD|CZK|RUB/i.match?(x['Ccy']) ? 0 : 1 }
  end

  def self.get_country_currency_hash(country_code_length = 2)
    return nil unless [2, 3].include? country_code_length
    hash = {}
    File.open(COUNTRY_MAPPING_ISO_PATH) do |file|
      Hash.from_xml(file)["country_currency_mapping"]["countries"]["country"].each { |h| hash[h['country_alphabetic_code_' + country_code_length.to_s]] = h['currency_alphabetic_code'] }
    end
    hash
  end

  def self.get_currency_code_for_country_code(country_code)
    country_code = country_code.to_s
    self.get_country_currency_hash(country_code.length).try(:[], country_code)
  end

  def self.active_currencies_codes
    EasyCurrency.activated.pluck(:iso_code)
  end

  def self.get_id_from_string(str)
    (EasyCurrency.find_by(iso_code: str) || EasyCurrency.find_by(symbol: str)).try(:id)
  end

  def self.reinitialize_tables(drop = nil)
    to_add = []
    if drop.is_a?(Array)
      currencies = drop.map(&:upcase)
    else
      currencies = EasyCurrency.pluck(:iso_code)
    end
    currency_models = EasyEntityWithCurrency.entities
    currency_models.each do |model|
      model.reset_column_information
      price_columns    = model.respond_to?(:currency_options) && model.currency_options.map { |x| x[:price_method] }
      price_columns    ||= []
      currency_columns = price_columns.product(currencies).map { |x| x.join('_') }
      if drop.nil?
        currency_columns -= model.column_names
      else
        currency_columns = currency_columns & model.column_names
      end
      to_add << { table: model.table_name, model: model, columns: currency_columns } if currency_columns.any?
    end

    to_add.each do |record|
      puts "#{drop.nil? && 'Add' || 'Drop'} price columns in different currencies to #{record[:table]}"

      ActiveRecord::Migration.change_table(record[:table]) do |t|
        record[:columns].each do |c|
          if drop
            t.remove c
          else
            t.decimal c, precision: 32, scale: 4
          end
        end
      end
    end

    EasyCurrency.where(iso_code: currencies).update_all(activated: true)

    currency_models.each { |x| x.reset_column_information }

    to_add
  end

  def create_exchange_rates
    EasyCurrency.where('id <> ?', self.id).each do |currency|
      EasyCurrencyExchangeRate.create(base_code: self.iso_code, to_code: currency.iso_code)
      EasyCurrencyExchangeRate.create(base_code: currency.iso_code, to_code: self.iso_code)
    end
    EasyCurrencyExchangeRate.create(base_code: iso_code, to_code: iso_code, rate: BigDecimal(1))
  end

  def exchange_table(date, currencies = EasyCurrency.sorted)
    ex_table = []
    currencies.each do |currency|
      ex_table << EasyCurrencyExchangeRate.find_exchange_rate(self, currency, date)
    end
    ex_table
  end

  def self.exchange_table(date)
    ex_table   = {}
    currencies = EasyCurrency.sorted
    currencies.each do |currency|
      ex_table[currency] = currency.exchange_table(date, currencies)
      return nil if ex_table[currency].any?(&:nil?)
    end
    ex_table
  end

  def self.synchronize_exchange_rates(date, provider = EasyExtensions::ApiServicesForExchangeRates::RatesEasysoftwareCom)
    if (codes = EasyCurrency.pluck(:iso_code)).any?
      rates = {}
      codes.each do |code|
        response = provider.exchange_table(code, date, codes) || {}
        if response['base'] == code
          response['rates'].each do |target, value|
            record      = EasyCurrencyExchangeRate.where(base_code: code, to_code: target, valid_on: date).first_or_initialize
            record.rate = value
            record.save!
          end
          rates[code] = response['rates']
        end
      end
      rates
    end
  end

  def self.exchange_table_by_base(base)
    easy_currency_settings = EasySetting.value(:easy_currency_exchange_rates, nil)
    easy_currency_settings ||= { start: 12, end: 2, day_of_month: Date.today.day }
    months_start           = easy_currency_settings['start'].present? ? easy_currency_settings['start'].to_i * -1 : -12
    months_end             = easy_currency_settings['end'].present? ? easy_currency_settings['end'].to_i : 2
    day                    = easy_currency_settings['day_of_month'].present? ? easy_currency_settings['day_of_month'].to_i : Date.today.day
    ex_table               = {}
    currencies             = EasyCurrency.where('id <> ?', base.id).order(:iso_code)
    day                    = [1, [Time.days_in_month(Date.today.month), day].min].max
    current_date           = Date.today.change(day: day)
    months_end.downto(months_start) do |i|
      row = []
      currencies.each do |target|
        row << EasyCurrencyExchangeRate.find_exchange_rate(base, target, current_date.advance(months: i))
      end
      ex_table[current_date.advance(months: i)] = row
    end
    ex_table
  end

  def validate_max_activated
    errors.add(:base, l(:limit_for_currencies_hit, limit: ACTIVATED_CURRENCY_LIMIT)) unless EasyCurrency.all.count <= ACTIVATED_CURRENCY_LIMIT
  end

  def invalidate_currencies_setup
    self.class.invalidate_currencies_setup
  end

  def self.invalidate_currencies_setup
    if EasySetting.value('easy_currencies_initialized') && (setting = EasySetting.find_by(name: 'easy_currencies_initialized', project_id: nil))
      setting.value = false
      setting.save
    end
  end

  def invalidate_cache
    Rails.cache.delete [self.class.name, self.iso_code]
  end

  def project_ids=(project_ids)
    self.projects = Project.where(:id => project_ids).to_a
  end

  def self.[](iso_code)
    Rails.cache.fetch [self.name, iso_code] do
      EasyCurrency.find_by_iso_code(iso_code)
    end
  end

  def self.get_symbol(iso_code)
    self[iso_code].try(:symbol) || iso_code || ''
  end

  def self.get_name(iso_code)
    self[iso_code].try(:name) || iso_code || ''
  end

  def to_s
    name
  end

  def self.default
    find_by_is_default(true) || activated.first
  end

  def self.default_code
    Rails.cache.fetch [self.name, 'default'] do
      default.try(:iso_code)
    end
  end

  private

  def notify_admins
    user_time = User.current.user_time_in_zone(Time.now)
    EasyBroadcast.create(author: User.current, start_at: user_time, end_at: user_time + 1.day, message: l(:easy_currency_setup_needed))
  end

  def check_default
    if self.is_default_changed?
      self.class.update_all(is_default: false) if self.is_default?
      Rails.cache.delete [self.class.name, 'default']
    end
  end

  def ensure_synchronize_task
    unless EasyRakeTaskSynchronizeCurrencies.exists?
      t         = EasyRakeTaskSynchronizeCurrencies.new(active: true, settings: {}, period: :daily, interval: 1, next_run_at: (Date.tomorrow.to_time + 8.hour))
      t.builtin = 1
      t.save!
    end
  end

end

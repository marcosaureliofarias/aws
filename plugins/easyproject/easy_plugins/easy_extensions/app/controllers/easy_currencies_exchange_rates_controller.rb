class EasyCurrenciesExchangeRatesController < ApplicationController
  layout 'admin'

  helper :easy_setting
  include EasySettingHelper


  before_action { |c| c.require_admin_or_lesser_admin(:easy_currency) }
  before_action :prepare, only: [:index, :bulk_update]
  before_action :last_change_rates, only: [:index]
  before_action :easy_currency_init_check

  helper :sort
  include SortHelper


  def bulk_update
    if Array(params['rate']).any?
      if params['base']
        params['rate'].each do |date, rate_id|
          rate_id.each do |key, rate|
            old           = EasyCurrencyExchangeRate.find(key)
            rate_to_write = BigDecimal(rate)
            if old && rate_to_write.finite? && rate_to_write > 0
              if old.valid_on == date.to_date
                old.rate = rate
                old.save
              else
                new                    = old.dup
                new.valid_on, new.rate = date.to_date, rate_to_write
                new.save
              end
            end
          end
        end
        redirect_to({ action: :index, tab: 'EasyCurrencyExchangeRateByBase', base: params['base'] }, { :notice => l(:notice_successful_update) })
      else
        date = params['date'].to_date
        date ||= Date.today
        params['rate'].each do |key, rate|
          rate_to_write = BigDecimal(rate)
          old           = EasyCurrencyExchangeRate.find(key)
          if old && rate_to_write.finite? && rate_to_write > 0
            if old.valid_on == date
              old.rate = rate
              old.save
            else
              new                    = old.dup
              new.valid_on, new.rate = date, rate
              new.save
            end
          end
        end
        redirect_to({ action: :index, tab: 'EasyCurrencyExchangeRateByDate', date: params['date'] }, { :notice => l(:notice_successful_update) })
      end
    end
  end

  def update_settings
    save_easy_settings
    redirect_to action: :index, tab: 'EasyCurrencyExchangeRateSettings'
  end

  def index
    @date = params[:date].to_date rescue Date.today
    @exchange_table = EasyCurrency.exchange_table(@date)
    if !@currencies.empty? && @exchange_table
      @tabs = [
          { :name => 'EasyCurrencyExchangeRateByDate', :partial => 'easy_currencies_exchange_rates/by_date', :label => :tab_easy_currencies_exchange_rates_by_date, :no_js_link => true },
          { :name => 'EasyCurrencyExchangeRateByBase', :partial => 'easy_currencies_exchange_rates/by_base', :label => :tab_easy_currencies_exchange_rates_by_base, :no_js_link => true },
          { :name => 'EasyCurrencyExchangeRateSettings', :partial => 'easy_currencies_exchange_rates/settings', :label => :tab_easy_currencies_exchange_rates_settings, :no_js_link => true }
      ]
      @tabs << { :name => 'EasyCurrencyExchnageRateLastCurrency', :partial => 'easy_currencies_exchange_rates/last_few', :label => :tab_easy_currencies_exchange_rates_last_few, :no_js_link => true } if !@last_exchange_tables.empty?
      @easy_currency_settings = EasySetting.value(:easy_currency_exchange_rates, nil) || { 'start' => 12, 'end' => 2, 'day_of_month' => Date.today.day }
      base_id                 = params[:base] ? params[:base].to_i : false
      @base                   = base_id ? EasyCurrency.find(base_id) : EasyCurrency.first
      @exchange_table_month   = EasyCurrency.exchange_table_by_base(@base)

      @last_date_of_rate = EasyCurrencyExchangeRate.where.not(valid_on: nil).order(valid_on: :desc).first&.valid_on

      respond_to do |format|
        format.html
      end
    else
      flash[:error] = I18n.t(:easy_currency_exchange_rates_invalid) unless @exchange_table
      redirect_to easy_currencies_path
    end
  end

  def synchronize_rates
    @date = params[:date].to_date rescue Date.today
    rates = EasyCurrency.synchronize_exchange_rates(@date, EasyExtensions::ApiServicesForExchangeRates::RatesEasysoftwareCom)
    if rates.present?
      redirect_to({ action: :index, tab: 'EasyCurrencyExchangeRateByDate', date: params[:date] }, notice: l(:easy_currency_synchronization_successful))
    else
      flash[:error] = l(:easy_currency_synchronization_failure, codes: '')
      redirect_to({ action: :index, tab: 'EasyCurrencyExchangeRateByDate', date: params[:date] })
    end
  end

  def prepare
    @exchange_tables = EasyCurrencyExchangeRate.preload(:base_currency).group_by { |x| x.base_currency }
    @currencies      = EasyCurrency.reorder(:iso_code)
  end

  def easy_currency_init_check
    if EasyCurrency.non_activated.exists? || !EasyEntityWithCurrency.initialized?
      flash[:warning] = l(:easy_currency_setup_needed)

    end
  end

  def last_change_rates
    @last_exchange_tables = EasyCurrencyExchangeRate.where.not(valid_on: nil).order(valid_on: :desc, updated_at: :desc).first(50)
  end


end

module EasyExtensions
  module EasyAttributeFormatter
    include ActionView::Helpers::NumberHelper
    include ActionView::Helpers::TagHelper

    def format_price(price, currency = nil, options = {})
      currency ||= options[:entity].currency if options[:entity] && options[:entity].respond_to?(:currency)
      currency = EasyCurrency.get_symbol(currency)

      if currency.present?
        options = options.reverse_merge(unit: currency)
        value   = options[:humanize] ? format_locale_number(price, options) : price # rails does not have number_to_human_currency
        value   = number_to_currency(value, options)
        format_number(price, value, options)
      else
        format_number(price, nil, options)
      end
    end

    def format_locale_price(price, currency = nil, options = {})
      options.merge!(l('number.currency.format').except(:unit))
      format_price(price, currency, options)
    end

    def format_locale_number(value, options = {})
      locale = options[:locale].presence || User.current.language.presence || ::I18n.locale
      if options[:percentage].present?
        number_to_percentage(value, { locale: locale }.merge!(options))
      elsif options[:humanize].present? && (!value.respond_to?(:finite?) || value.finite?)
        number_to_human(value, format: '%n%u', precision: 2, significant: false)
      else
        number_with_precision(value, { locale: locale }.merge!(options))
      end
    end

    def format_number(number, value = nil, options = {})
      value ||= format_locale_number(number, options)
      value = value.to_s

      if options[:no_html]
        value
      else
        content_tag(:span, value, :title => options[:title], :class => "#{('overdrawn' if number.to_f < 0.0)}") unless value.blank?
      end
    end

    def easy_format_hours(value, options = {})
      options[:no_html] = !!options[:no_html]
      options[:format]  ||= User.current.pref[:hours_format] || 'short'
      value             = value.to_f
      if !options[:no_html]
        format_number(value, html_hours(value, options), options).html_safe
      else
        if options[:format] == 'short' || options[:humanize]
          l(:label_f_hour_short, value: format_locale_number(value, options.except(:format)))
        elsif options[:format] == 'simple'
          hours_int       = value.to_i
          min             = ((value.hours - hours_int.hours) / 1.minute).round
          formatted_hours = format_locale_number(hours_int, options.merge(precision: 0, format: nil))
          formated        = "<strong>#{l(:label_f_hour_abbreviation, value: formatted_hours)}</strong>"
          formated << " <span class='nowrap'>#{l(:label_f_minute_abbreviation, value: min)}</span>" unless min.zero?
          formated.html_safe
        else
          rounded_value = value.round(2)
          hours_int     = rounded_value.to_i
          min           = ((rounded_value.hours - hours_int.hours) / 1.minute).round
          formated      = "#{l((hours_int.abs == 1) ? :label_f_hour : :label_f_hour_plural, value: hours_int)}"
          formated << " #{l(min.abs == 1 ? :label_minute : :label_minute_plural, value: min)}" unless min.zero?
          formated
        end
      end
    end

    def format_time_range(start_time, end_time, include_date = false)
      return '' unless start_time && end_time
      format_time(start_time, include_date) + ' - ' + format_time(end_time, include_date)
    end

    def easy_format_object(value, object, html = true)
      case object
      when Numeric
        format_locale_number(object, strip_insignificant_zeros: true)
      else
        value
      end
    end

    def easy_html_hours(value, options = {})
      html = easy_format_hours(value, { no_html: true, format: options[:format] })
      case options[:format]
      when 'long', 'short'
        html.gsub!(%r{([\d*\W?]+\d+\s\w+)}) do
          h = "<span class='hours hours-int'>#{$1}</span>"
          h << "<span class='hours hours-dec'> #{$2}</span>" if $2
          h
        end
      else
        html = content_tag(:span, easy_format_hours(value, { no_html: true, format: options[:format] }), :class => 'hours')
      end
      html.html_safe
    end

    def format_period(value, period)
      week_start_lamb = -> do
        start_of_week = Setting.start_of_week
        start_of_week = l(:general_first_day_of_week, :default => '1') if start_of_week.blank?
        start_of_week.to_i
      end

      time = value.to_time
      case period
      when :second
        format_time(value)
      when :minute
        format_date(value) + ' ' + I18n.l(value, format: '%H:%M')
      when :hour
        format_date(value) + ' ' + I18n.l(value, format: '%H')
      when :day
        format_date(value)
      when :week
        # same logic as MySQL group
        if week_start_lamb.call == 7
          I18n.l(value, format: '%U. %Y')
        else
          I18n.l(value, format: '%W. %Y')
        end
      when :month
        I18n.l(value, format: '%B %Y')
      when :quarter
        (((value.month - 1) / 3) + 1).to_s + '. ' + I18n.l(value, format: '%Y')
      when :year
        I18n.l(value, format: '%Y')
      when :hour_of_day
        time.hour.to_s
      when :day_of_week
        (7 - week_start_lamb.call + ((time.wday - 1) % 7) % 7).to_s
      when :day_of_month
        I18n.l(value, format: '%e')
      when :month_of_year
        I18n.l(value, format: '%B')
      else
        raise "Invalid period"
      end
    end

  end
end

module EasyPatch
  module I18nPatch

    def self.included(base)
      base.include(InstanceMethods)

      base.class_eval do

        alias_method_chain :format_time, :easy_extensions
        alias_method_chain :valid_languages, :easy_extensions

        def format_short_date(date)
          return nil unless date
          d = date.is_a?(Date) ? date : begin
            ; date.to_date;
          rescue;
            nil;
          end
          ::I18n.l(d, :locale => locale, :format => short_date_format) if d
        end

        def format_date_or_time(value)
          if value.is_a?(Date)
            format_date(value)
          else
            format_time(value)
          end
        end

        def format_date_with_zone(date, user = nil)
          return nil unless date
          user ||= User.current
          return format_date(date) if date.is_a?(Date)
          begin
            time  = date.is_a?(String) ? date.to_time : date
            zone  = user.time_zone
            local = zone ? time.in_time_zone(zone) : (time.utc? ? time.localtime : time)
            format_date(local)
          rescue
            date
          end
        end

        def day_short_name(day)
          ::I18n.t('date.abbr_day_names')[day % 7]
        end

        def short_date_format
          Setting.date_format.present? ? Setting.date_format.sub(/[^\w\.]{0,2}%Y.?/, "") : ::I18n.t("date.formats.short")
        end

        def to_js_date_format(date_format)
          date_format.gsub(/%[d|m|b|B|e]/, '%d' => 'dd', '%m' => 'MM', '%b' => 'MMM', '%B' => 'MMMM', '%e' => 'dd')
        end

      end
    end

    module InstanceMethods

      def format_time_with_easy_extensions(time, include_date = true, user = nil)
        return nil unless time
        user             ||= User.current
        options          = {}
        options[:format] = (Setting.time_format.blank? ? :time : Setting.time_format)
        options[:locale] = User.current.language unless User.current.language.blank?
        begin
          time  = time.to_time if time.is_a?(String)
          zone  = user.time_zone
          local = zone ? time.in_time_zone(zone) : (time.utc? ? time.localtime : time)
          (include_date ? "#{format_date(local)} " : "") + ::I18n.l(local, options)
        rescue
          time
        end
      end

      def valid_languages_with_easy_extensions
        EasyExtensions::SUPPORTED_LANGS
      end


    end
  end
end

module EasyPatch
  module I18nBackendImplementationPatch

    def self.included(base)
      base.include(InstanceMethods)

      base.class_eval do

        alias_method_chain :available_locales, :easy_extensions

      end
    end

    module InstanceMethods

      def available_locales_with_easy_extensions
        @available_locales ||= Dir.glob(File.join(EasyExtensions::EASY_EXTENSIONS_DIR, 'config', 'locales', '*.yml')).collect { |f| File.basename(f).split('.').first }.collect(&:to_sym)
      end

    end
  end
end

EasyExtensions::PatchManager.register_concern_patch 'Redmine::I18n', 'EasyPatch::I18nPatch'
EasyExtensions::PatchManager.register_concern_patch 'Redmine::I18n::Backend::Implementation', 'EasyPatch::I18nBackendImplementationPatch'

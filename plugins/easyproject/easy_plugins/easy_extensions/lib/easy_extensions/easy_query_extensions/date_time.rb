module EasyExtensions
  module EasyQueryExtensions
    module DateTime

      def date_condition(column, period, connection = ActiveRecord::Base.connection)
        case connection.adapter_name.downcase
        when /(mysql|mariadb)/
          case period
          when :day_of_week # Sunday = 0, Monday = 1, etc
            # use CONCAT for consistent return type (String)
            ["DAYOFWEEK(CONVERT_TZ(DATE_SUB(#{column}, INTERVAL #{day_start} HOUR), '+00:00', ?)) - 1", time_zone]
          when :hour_of_day
            ["(EXTRACT(HOUR from CONVERT_TZ(#{column}, '+00:00', ?)) + 24 - #{day_start}) % 24", time_zone]
          when :day_of_month
            ["DAYOFMONTH(CONVERT_TZ(DATE_SUB(#{column}, INTERVAL #{day_start} HOUR), '+00:00', ?))", time_zone]
          when :day_of_year
            ["DAYOFYEAR(CONVERT_TZ(DATE_SUB(#{column}, INTERVAL #{day_start} HOUR), '+00:00', ?))", time_zone]
          when :month_of_year
            ["MONTH(CONVERT_TZ(DATE_SUB(#{column}, INTERVAL #{day_start} HOUR), '+00:00', ?))", time_zone]
          when :year_short
            ["YEAR(CONVERT_TZ(DATE_SUB(#{column}, INTERVAL #{day_start} HOUR), '+00:00', ?))", time_zone]
          when :week
            ["DATE_SUB(CAST(#{column} AS DATE), INTERVAL ((#{7 - week_start} + WEEKDAY(#{column})) % ?) DAY)", 7]
          when :cweek
            ["WEEKOFYEAR(CONVERT_TZ(DATE_SUB(#{column}, INTERVAL #{day_start} HOUR), '+00:00', ?))", time_zone]
          when :quarter
            ["DATE_SUB(DATE_ADD(MAKEDATE(YEAR(#{column}), 1), INTERVAL QUARTER(#{column}) QUARTER), INTERVAL 1 QUARTER)"]
          else
            format =
                case period
                when :second
                  "%Y-%m-%d %H:%i:%S"
                when :minute
                  "%Y-%m-%d %H:%i:00"
                when :hour
                  "%Y-%m-%d %H:00:00"
                when :day
                  "%Y-%m-%d 00:00:00"
                when :month
                  "%Y-%m-01 00:00:00"
                else # year
                  "%Y-01-01 00:00:00"
                end

            # ["DATE_ADD(CONVERT_TZ(DATE_FORMAT(CONVERT_TZ(DATE_SUB(#{column}, INTERVAL #{day_start} HOUR), '+00:00', ?), '#{format}'), ?, '+00:00'), INTERVAL #{day_start} HOUR)", time_zone, time_zone]
            ["DATE_ADD(DATE_FORMAT(DATE_SUB(#{column}, INTERVAL #{day_start} HOUR), ?), INTERVAL #{day_start} HOUR)", format]
          end
        when 'postgresql', 'postgis'
          case period
          when :day_of_week
            postgres_extract("DOW", column, connection)
          when :hour_of_day
            postgres_extract("HOUR", column, connection)
          when :day_of_month
            postgres_extract("DAY", column, connection)
          when :day_of_year
            postgres_extract("DOY", column, connection)
          when :month_of_year
            postgres_extract("MONTH", column, connection)
          when :year_short
            postgres_extract("YEAR", column, connection)
          when :week # start on Sunday, not PostgreSQL default Monday
            # postgres_extract("HOUR", column, connection)
            ["(DATE_TRUNC('#{period}', (#{column}::timestamptz - INTERVAL '#{week_start} day' - INTERVAL '#{day_start}' hour)) + INTERVAL '#{week_start} day' + INTERVAL '#{day_start}' hour)"]
          when :cweek
            postgres_extract("WEEK", column, connection)
          else
            # ["(DATE_TRUNC('#{period}', (#{column}::timestamptz - INTERVAL '#{day_start} hour') AT TIME ZONE ?) + INTERVAL '#{day_start} hour') AT TIME ZONE ?", time_zone, time_zone]
            "(DATE_TRUNC('#{period}', (#{column}::timestamptz - INTERVAL '#{day_start} hour')) + INTERVAL '#{day_start} hour')"
          end
        else
          raise "Connection adapter not supported: #{adapter_name}"
        end
      end

      def timestamp_cast(value)
        if Redmine::Database.postgresql?
          "CAST((CASE WHEN #{value} <> '' THEN to_timestamp(#{value}, 'YYYY MM DD HH24 MI SS') ELSE NULL END) AS TIMESTAMP)"
        else
          "CAST(#{value} AS DATETIME)"
        end
      end

      protected

      def time_zone
        (User.current.time_zone || Time.zone || ActiveSupport::TimeZone['Etc/UTC']).formatted_offset
      end

      def week_start
        start_of_week = Setting.start_of_week
        start_of_week = l(:general_first_day_of_week, default: '1') if start_of_week.blank?

        start_of_week.to_i - 1
      end

      def day_start
        0
      end

      def postgres_extract(extractor, column, connection)
        db_table, db_col = column.split "."
        if db_table && db_col && connection.columns(db_table).detect { |c| c.name == db_col }&.type == :date
          ["EXTRACT(#{extractor} from #{db_col})::integer"]
        else
          ["EXTRACT(#{extractor} from #{db_col || db_table}::timestamptz AT TIME ZONE ? - INTERVAL '#{day_start} hour')::integer", time_zone]
        end
      end

    end
  end
end

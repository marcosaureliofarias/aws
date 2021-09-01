module EasySwagger
  module ResponseEntities
    # ActsAsEasyRepeatable options for request/response
    module EasyRepeatOptions

      # @param [Hash] options
      # @option options [Proc] :if
      def easy_repeat_options(**options)
        property "easy_repeat_settings", options do
          key :type, "object"
          key :description, "Repeating options"
          property "simple_period"
          property "end_date", format: "date"
          property "endtype_count_x", type: "integer"
          property "start_timepoint", format: "date"
          property "repeated", type: "integer" do
            key :description, "How many times it was repeated"
          end
          property "week_days", type: "array" do
            items do
              key :type, "string"
            end
          end
          property "period" do
            key :enum, %w[daily weekly monthly yearly]
          end
          property "create_now" do
            key :description, "Is `none` or number"
          end
          property "endtype" do
            key :enum, %w[date count endless project_end]
          end
          property "daily_option" do
            key :enum, %w[each work]
          end
          property "daily_each_x", type: "integer"
          property "monthly_option" do
            key :enum, %w[xth]
          end
          property "monthly_day", type: "integer"
          property "monthly_custom_order", type: "integer"
          property "monthly_custom_day", type: "integer"
          property "monthly_period", type: "integer"
          property "yearly_option" do
            key :enum, %w[date]
          end
          property "yearly_month", type: "integer"
          property "yearly_day", type: "integer"
          property "yearly_custom_order", type: "integer"
          property "yearly_custom_day", type: "integer"
          property "yearly_custom_month", type: "integer"
          property "yearly_period", type: "integer"
          property "repeat_hour" do
            key :description, "Should be in format %H:%M"
            key :example, "04:00"
          end
          property "create_now_count", type: "integer"
        end
      end

    end
  end
end
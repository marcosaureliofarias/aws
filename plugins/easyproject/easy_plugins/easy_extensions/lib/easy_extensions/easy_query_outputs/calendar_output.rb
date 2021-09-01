module EasyExtensions
  module EasyQueryOutputs
    class CalendarOutput < EasyExtensions::EasyQueryHelpers::EasyQueryOutput

      def self.available_for?(query)
        query.calendar_support?
      end

    end
  end
end

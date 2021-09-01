module EasyExtensions
  module EasyQueryHelpers
    class EasyOutputs < RedmineExtensions::EasyQueryHelpers::Outputs

      def outputs
        @outputs ||= enabled_outputs.map { |o| EasyQueryOutput.output_klass_for(o, @query).new(@presenter, self) }.sort_by { |a| a.order }
      end

      def available_output_names
        @available_output_names ||= EasyQueryOutput.available_outputs_for(@query)
      end

      def available_outputs
        @available_outputs ||= EasyQueryOutput.available_output_klasses_for(@query).map { |klass| klass.new(@presenter, self) }
      end

    end
  end
end

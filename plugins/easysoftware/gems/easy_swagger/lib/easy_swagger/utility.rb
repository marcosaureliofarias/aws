module EasySwagger
  module ResponseEntities
    module Utility

      # extend :if condition for node with check to request params include this extension
      def extend_options_for(include_value, **options)
        external_if_option = options[:if]
        if_option = Proc.new do |context, object|
          external_condition = case external_if_option
          when Proc
            external_if_option.call(context, object)
          when Symbol
            object.send(external_if_option)
          else
            true
          end
          external_condition && context&.params&.[](:include) && context.params[:include].split(',').include?(include_value)
        end
        options[:if] = if_option
        options
      end

    end
  end
end

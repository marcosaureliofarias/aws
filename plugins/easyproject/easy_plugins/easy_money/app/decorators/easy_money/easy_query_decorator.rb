module EasyMoney
  class EasyQueryDecorator < SimpleDelegator
    attr_reader :query

    def initialize(entity, query)
      super entity
      @query = query
    end

    def model
      __getobj__
    end

    def nested_send(method_name)
      if respond_to?(method_name)
        public_send(method_name)
      else
        model.nested_send(method_name)
      end
    end
  end
end

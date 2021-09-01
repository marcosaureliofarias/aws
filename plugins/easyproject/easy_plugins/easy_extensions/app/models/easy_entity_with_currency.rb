class EasyEntityWithCurrency
  class << self
    attr_writer :entities

    def entities
      @entities || []
    end

    def add(*entity_classes)
      self.entities = entities | Array(entity_classes)
    end

    alias_method :register, :add

    def initialized?
      EasySetting.value('easy_currencies_initialized')
    end
  end
end

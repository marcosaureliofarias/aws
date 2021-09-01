module EasyCore::Factory

  class << self
    # @param [ActiveRecord] model
    # @param [Symbol] factory
    # @param [Hash] searched_by
    def first_or_create(model, factory = nil, **searched_by)
      attributes = searched_by.dup
      if block_given?
        yield attributes
      end
      model.find_by(searched_by) || FactoryBot.create(factory || model.to_s.underscore, **attributes)
    end

    alias_method :foc, :first_or_create
  end

end

require 'delegate'

class EasyMoneyDecorator < SimpleDelegator
  def initialize(object, view_context)
    super object
    @view_context = view_context
  end

  def human_attribute_name(attribute_name)
    model.class.human_attribute_name attribute_name
  end

  def model
    __getobj__
  end

  def _h
    @view_context
  end
end

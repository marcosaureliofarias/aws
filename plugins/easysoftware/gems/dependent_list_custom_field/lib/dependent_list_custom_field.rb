require 'rys'

require 'dependent_list_custom_field/version'
require 'dependent_list_custom_field/engine'

module DependentListCustomField

  # Configuration of DependentListCustomField
  #
  # @example Direct configuration
  #   DependentListCustomField.config.my_key = 1
  #
  # @example Configuration via block
  #   DependentListCustomField.configure do |c|
  #     c.my_key = 1
  #   end
  #
  # @example Getting a configuration
  #   DependentListCustomField.config.my_key
  #

  # configure do |c|
  #   c.my_key = 'This is my private config for DependentListCustomField'
  #
  #   # System rys (not visible to the users)
  #   # c.systemic = true
  # end

end

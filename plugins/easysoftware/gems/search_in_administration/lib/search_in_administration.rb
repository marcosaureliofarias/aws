require 'rys'

require 'search_in_administration/version'
require 'search_in_administration/engine'

module SearchInAdministration

  # Configuration of SearchInAdministration
  #
  # @example Direct configuration
  #   SearchInAdministration.config.my_key = 1
  #
  # @example Configuration via block
  #   SearchInAdministration.configure do |c|
  #     c.my_key = 1
  #   end
  #
  # @example Getting a configuration
  #   SearchInAdministration.config.my_key
  #

  # configure do |c|
  #   c.my_key = 'This is my private config for SearchInAdministration'
  #
  #   # System rys (not visible to the users)
  #   # c.systemic = true
  # end

end

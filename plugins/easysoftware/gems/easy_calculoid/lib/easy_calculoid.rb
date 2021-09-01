require 'rys'

require 'easy_calculoid/version'
require 'easy_calculoid/engine'

module EasyCalculoid

  # Configuration of EasyCalculoid
  #
  # @example Direct configuration
  #   EasyCalculoid.config.my_key = 1
  #
  # @example Configuration via block
  #   EasyCalculoid.configure do |c|
  #     c.my_key = 1
  #   end
  #
  # @example Getting a configuration
  #   EasyCalculoid.config.my_key
  #

  # configure do |c|
  #   c.my_key = 'This is my private config for EasyCalculoid'
  #
  #   # System rys (not visible to the users)
  #   # c.systemic = true
  # end

end

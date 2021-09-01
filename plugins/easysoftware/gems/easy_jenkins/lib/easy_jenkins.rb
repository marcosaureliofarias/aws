require 'rys'

require 'easy_jenkins/version'
require 'easy_jenkins/engine'

module EasyJenkins

  # Configuration of EasyJenkins
  #
  # @example Direct configuration
  #   EasyJenkins.config.my_key = 1
  #
  # @example Configuration via block
  #   EasyJenkins.configure do |c|
  #     c.my_key = 1
  #   end
  #
  # @example Getting a configuration
  #   EasyJenkins.config.my_key
  #

  # configure do |c|
  #   c.my_key = 'This is my private config for EasyJenkins'
  #
  #   # System rys (not visible to the users)
  #   # c.systemic = true
  # end

end

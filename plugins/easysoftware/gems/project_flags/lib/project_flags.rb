require 'rys'

require 'project_flags/version'
require 'project_flags/engine'

module ProjectFlags

  # Configuration of ProjectFlags
  #
  # @example Direct configuration
  #   ProjectFlags.config.my_key = 1
  #
  # @example Configuration via block
  #   ProjectFlags.configure do |c|
  #     c.my_key = 1
  #   end
  #
  # @example Getting a configuration
  #   ProjectFlags.config.my_key
  #

  # configure do |c|
  #   c.my_key = 'This is my private config for ProjectFlags'
  #
  #   # System rys (not visible to the users)
  #   # c.systemic = true
  # end

end

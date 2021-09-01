require 'rys'

require 'issue_duration/version'
require 'issue_duration/engine'
require 'issue_duration/issue_easy_duration_formatter'

module IssueDuration

  # Configuration of IssueDuration
  #
  # @example Direct configuration
  #   IssueDuration.config.my_key = 1
  #
  # @example Configuration via block
  #   IssueDuration.configure do |c|
  #     c.my_key = 1
  #   end
  #
  # @example Getting a configuration
  #   IssueDuration.config.my_key
  #

  # configure do |c|
  #   c.my_key = 'This is my private config for IssueDuration'
  #
  #   # System rys (not visible to the users)
  #   # c.systemic = true
  # end

end

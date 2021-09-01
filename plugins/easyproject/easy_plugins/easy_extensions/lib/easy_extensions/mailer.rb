module EasyExtensions
  module Mailer
    EMAIL_REGEXP = Regexp.new('\b[A-Z0-9._%+-]+@[A-Z0-9.-]+\.[A-Z]{2,}\b', true)
  end
end

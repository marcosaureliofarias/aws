require 'rys'
require 'graphql'


if Rails.env.development?
  require 'graphiql/rails'
end

require 'easy_api'
require 'easy_graphql/version'
require 'easy_graphql/engine'

module EasyGraphql

  configure do |c|
    c.systemic = true
  end

  # For now its do basically nothing
  # Later there could be an schema cache invalidation
  # Because schema is generated on first touch (then is cached)
  def self.patch(klass, &block)
    klass = klass.constantize rescue nil
    klass&.class_eval(&block)
  end

end

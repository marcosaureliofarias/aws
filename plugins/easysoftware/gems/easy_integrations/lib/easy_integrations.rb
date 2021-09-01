require 'rys'
require 'sidekiq'
require 'sidekiq-cron'

require 'easy_integrations/version'
require 'easy_integrations/engine'

module EasyIntegrations
  autoload :EntitiesFinder, 'easy_integrations/entities_finder'
  autoload :Trigger, 'easy_integrations/trigger'

  module Categories
    autoload :Base, 'easy_integrations/categories/base'
    autoload :Messaging, 'easy_integrations/categories/messaging'
    autoload :Other, 'easy_integrations/categories/other'

    def self.each(&block)
      [Messaging.new, Other.new].each(&block)
    end
  end

  module Metadata
    autoload :Base, 'easy_integrations/metadata/base'
    autoload :RocketChat, 'easy_integrations/metadata/rocket_chat'
  end

  module Services
    autoload :Base, 'easy_integrations/services/base'
  end

  @@_registered_metadata = {}
  @@_registered_services = {}

  def self.register_metadata(symbol, klass, options = {})
    @@_registered_metadata[symbol.to_sym] ||= { klass: klass, options: options }
  end

  def self.register_service(symbol, klass, options = {})
    @@_registered_services[symbol.to_sym] ||= { klass: klass, options: options }
  end

  def self.registered_metadata
    @@_registered_metadata
  end

  def self.registered_services
    @@_registered_services
  end

  def self.metadata_for_category(category)
    @@_registered_metadata.select { |k, v| v.category.slug == category.slug }.values.map { |k| k[:klass] }
  end

end

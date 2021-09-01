require 'rys'

require 'easy_service_manager/version'
require 'easy_service_manager/engine'

module EasyServiceManager
  autoload :Service, 'easy_service_manager/service'

  module Services
    autoload :EasySetting, 'easy_service_manager/services/easy_setting'
  end

  configure do |c|
    c.systemic = true
  end

  def self.private_key
    @private_key
  end

  def self.public_key
    @public_key ||= EasyServiceManager::Engine.root.join('config/service_manager.pubk').to_s
  end

  def self.master?
    !!@master
  end

  def self.master!(private_key:)
    @private_key = private_key
    @master = true
  end

end

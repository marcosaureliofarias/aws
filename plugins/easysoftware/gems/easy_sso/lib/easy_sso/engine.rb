require 'rys'

module EasySso
  class Engine < ::Rails::Engine
    include Rys::EngineExtensions

    rys_id 'easy_sso'
    #    hosting_plugin true if respond_to?(:hosting_plugin)

    initializer 'easy_sso.setup' do
      # Custom initializer
    end
  end
end

require 'rys'

module EasyJenkins
  class Engine < ::Rails::Engine
    include Rys::EngineExtensions

    config.autoload_paths << File.expand_path("../lib/easy_jenkins/api", __FILE__)

    config.generators do |g|
      g.test_framework :rspec, fixture: false
      g.integration_tool :rspec
      g.assets false
      g.helper true
    end

    rys_id 'easy_jenkins'
    hosting_plugin true if respond_to?(:hosting_plugin)

    initializer 'easy_jenkins.setup' do
      # Custom initializer
    end

  end
end

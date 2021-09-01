module EasyMonitoring
  class Engine < ::Rails::Engine
    isolate_namespace EasyMonitoring

    initializer 'easy_monitoring.setup' do
      # Custom initializer
    end

  end
end

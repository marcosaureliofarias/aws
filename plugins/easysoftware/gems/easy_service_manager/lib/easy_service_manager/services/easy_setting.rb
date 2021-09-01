module EasyServiceManager
  module Services
    class EasySetting < EasyServiceManager::Service

      def execute
        ::EasySetting.where(name: @value['name']).each do |setting|
          setting.value = @value['value']
          setting.save
        end
      end

    end
  end
end

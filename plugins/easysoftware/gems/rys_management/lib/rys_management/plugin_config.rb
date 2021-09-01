module RysManagement
  module PluginConfig

    def self.included(base)
      base.extend(ClassMethods)
    end

    module ClassMethods

      def setting(name, project=nil)
        EasySetting.value("#{self.engine.rys_id}_#{name}", project)
      end

      def set_setting(name, value, project: nil)
        setting = EasySetting.find_or_initialize_by(name: "#{self.engine.rys_id}_#{name}", project: project)
        setting.value = value
        setting.save
      end

    end

  end
end

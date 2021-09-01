module EasyHelpdesk
  module UserPreferencePatch

    def self.included(base)
      base.class_eval do

        safe_attributes 'hide_sla_data'

        def hide_sla_data
          self[:hide_sla_data] == true || self[:hide_sla_data] == '1'
        end

        def hide_sla_data=(value)
          self[:hide_sla_data]=value
        end

      end
    end


  end

end
EasyExtensions::PatchManager.register_model_patch 'UserPreference', 'EasyHelpdesk::UserPreferencePatch'

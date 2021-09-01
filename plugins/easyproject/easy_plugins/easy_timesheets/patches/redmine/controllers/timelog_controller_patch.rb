module EasyTimesheets
  module TimelogControllerPatch

    def self.included(base)
      base.class_eval do

        skip_before_action :authorize, :only => [:easy_timesheets]
        before_action :find_optional_project, :only => [:easy_timesheets]
        before_action :authorize_global, :only => [:easy_timesheets]

      end
    end
  end
end
# EasyExtensions::PatchManager.register_controller_patch 'TimelogController', 'EasyTimesheets::TimelogControllerPatch'

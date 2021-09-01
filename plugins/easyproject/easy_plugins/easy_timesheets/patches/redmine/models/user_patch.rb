module EasyTimesheets
  module UserPatch

    def self.included(base)
      base.class_eval do
        has_many :easy_timesheets, :dependent => :destroy
      end
    end
  end
end
EasyExtensions::PatchManager.register_model_patch 'User', 'EasyTimesheets::UserPatch'

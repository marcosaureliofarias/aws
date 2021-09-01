module EasyTimesheets
  module TimeEntryPatch

    def self.included(base)

      base.class_eval do

        belongs_to :easy_timesheet

        before_create :ensure_time_sheet, :if => Proc.new{|t| EasyTimesheet.enable_ensure_time_sheet_for_time_entry?}

        private

        def ensure_time_sheet
          t = EasyTimesheet.table_name
          self.easy_timesheet = EasyTimesheet.where(:user_id => self.user_id).where(["#{t}.start_date <= :d AND #{t}.end_date >= :d", :d => self.spent_on]).where(:locked => false).first
        end

      end
    end

  end

end
EasyExtensions::PatchManager.register_model_patch 'TimeEntry', 'EasyTimesheets::TimeEntryPatch'

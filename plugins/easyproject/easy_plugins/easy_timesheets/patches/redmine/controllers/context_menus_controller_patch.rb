module EasyTimesheets
  module ContextMenusControllerPatch

    def self.included(base)
      base.class_eval do

        def easy_timesheets
          @can = {}
          @is = {}

          @easy_timesheets = EasyTimesheet.where(:id => params[:ids])
          if @easy_timesheets.count == 1
            @easy_timesheet = @easy_timesheets.first
          else
            @can[:delete_all] = @easy_timesheets.detect{|e| !e.editable?}.nil?
          end

          @can[:locking] = @easy_timesheets.all?(&:can_lock?)
          @can[:unlocking] = @easy_timesheets.all?(&:can_unlock?)

          if @can[:locking] || @can[:unlocking]
            if @easy_timesheet
              @is[:locked] = @easy_timesheet.locked?
            else
              all_locked = @easy_timesheets.pluck(:locked).uniq
              @is[:locked] = all_locked.count == 1 && all_locked.first
            end
          end
          render :layout => false
        end

      end
    end
  end
end
EasyExtensions::PatchManager.register_controller_patch 'ContextMenusController', 'EasyTimesheets::ContextMenusControllerPatch'

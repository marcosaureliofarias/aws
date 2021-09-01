module EasyTimesheets
  module EasyQueryButtonsHelperPatch

    def self.included(base)
      base.class_eval do

        def easy_timesheet_query_additional_ending_buttons(entity, options)
          links = ActiveSupport::SafeBuffer.new
          if entity.monthly?
            links << link_to('', monthly_show_easy_timesheets_path(entity), class: 'icon-controls xl-icon', title: l(:title_easy_timesheet_show))
          else
            links << link_to('', entity, class: 'icon-controls xl-icon', title: l(:title_easy_timesheet_show))
          end
          links << link_to('', entity, class: 'icon-del xl-icon', title: l(:title_easy_timesheet_destroy), method: :delete, data: { confirm: l(:text_are_you_sure) }) if entity.editable?

          links
        end

      end
    end

  end
end

EasyExtensions::PatchManager.register_helper_patch 'EasyQueryButtonsHelper', 'EasyTimesheets::EasyQueryButtonsHelperPatch'

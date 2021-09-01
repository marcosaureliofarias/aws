module EasyHelpdesk
  module EasyRakeTasksHelperPatch

    def self.included(base)
      base.include(InstanceMethods)

      base.class_eval do

        alias_method_chain :task_delete_confirmation, :easy_helpdesk

      end
    end

    module InstanceMethods

      def task_delete_confirmation_with_easy_helpdesk(task)
        if task.type.eql? "EasyRakeTaskEasyHelpdeskReceiveMail"
          l(:text_mailbox_delete_confirmation)
        else
          task_delete_confirmation_without_easy_helpdesk task
        end
      end

    end

  end
end
EasyExtensions::PatchManager.register_helper_patch 'EasyRakeTasksHelper', 'EasyHelpdesk::EasyRakeTasksHelperPatch'

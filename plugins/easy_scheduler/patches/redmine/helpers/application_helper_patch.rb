# module EasyScheduler
#   module ApplicationHelperPatch
#
#     def self.included(base)
#       base.extend(ClassMethods)
#       base.send(:include, InstanceMethods)
#     end
#
#     module InstanceMethods
#     end
#
#     module ClassMethods
#     end
#
#   end
# end

# RedmineExtensions::PatchManager.register_helper_patch 'ApplicationHelper', 'EasyScheduler::ApplicationHelperPatch'

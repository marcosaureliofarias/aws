if Redmine::Plugin.installed?(:easy_extensions)
  Redmine::AccessControl.update_permission :manage_easy_contacts, { :easy_contacts => [:recalculate_cf] }
  Redmine::AccessControl.update_permission :manage_author_easy_contacts, { :easy_contacts => [:recalculate_cf] }
  Redmine::AccessControl.update_permission :manage_assigned_easy_contacts, { :easy_contacts => [:recalculate_cf] }
end

module EasyImportsHelper

  def import_entities_tabs
    [{ name: 'projects_and_tasks', partial: 'easy_imports/tabs/projects_and_tasks', label: l('easy_imports.title_projects_and_tasks') },
     { name: 'users', partial: 'easy_imports/tabs/users', label: l('label_user_plural') }]
    # {name: 'all_at_once', partial: 'easy_imports/tabs/all_at_once', label: 'All at once'}]
  end

end

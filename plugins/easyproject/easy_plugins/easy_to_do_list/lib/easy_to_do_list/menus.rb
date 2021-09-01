Redmine::MenuManager.map :easy_servicebar_items do |menu|
  menu.push(:easy_to_do_list_toolbar, { controller: 'easy_to_do_lists', action: 'show_toolbar' }, html: {
      class: 'icon-issue-status',
      id: 'easy_to_do_list_toolbar_trigger',
      title: EasyExtensions::MenuManagerProc.new { I18n.t(:heading_easy_to_do_list) },
      remote: true
    },
    caption: '',
    param: :project_id,
    if: lambda{|project| User.current.logged? && User.current.allowed_to_globally?(:use_easy_to_do_list, {})}
  )
end
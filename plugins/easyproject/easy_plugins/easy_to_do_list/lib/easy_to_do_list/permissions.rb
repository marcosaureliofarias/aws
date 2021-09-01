Redmine::AccessControl.map do |map|
  map.easy_category(:easy_to_do_list) do |pmap|
    pmap.permission(:use_easy_to_do_list, {
        easy_to_do_lists: [:show_toolbar, :index, :show, :create, :update, :destroy],
        easy_to_do_list_items: [:index, :show, :create, :update, :destroy]
      }, global: true)
  end
end
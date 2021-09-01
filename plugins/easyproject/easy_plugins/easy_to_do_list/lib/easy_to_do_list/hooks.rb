module EasyToDoListModule
  class Hooks < Redmine::Hook::ViewListener
    render_on :view_layouts_base_body_bottom, partial: 'easy_to_do_lists/view_layouts_base_body_bottom'
  end
end

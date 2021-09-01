module EasyRedmine
  class Hooks < Redmine::Hook::ViewListener

    render_on :view_layouts_base_html_head_top, partial: 'layouts/easy_redmine/view_layouts_base_html_head_top'

    def view_layouts_base_html_head(context = {})
      stylesheet_link_tag('easy_redmine', plugin: 'easy_redmine')
    end

  end
end
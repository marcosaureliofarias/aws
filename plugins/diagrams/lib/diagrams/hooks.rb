module Diagrams
  class Hooks < Redmine::Hook::ViewListener
    CONTROLLER_BLACKLIST = ['EasyPrintableTemplatesController']

    def view_layouts_base_body_bottom(context = {})
      return if module_disabled?(context)

      context[:hook_caller].render('wiki/diagram_modal', context)
    end

    def view_issues_show_details_bottom(context = {})
      return if module_disabled?(context)

      context[:hook_caller].render('wiki/diagram_modal', context)
    end

    def view_layouts_base_html_head(context = {})
      return if module_disabled?(context)

      html =  context[:hook_caller].render('redmine_jstoolbar_buttons/redmine_jstoolbar_buttons_partial', context)
      html << context[:hook_caller].render('diagrams/redmine_ckeditor_buttons', context)
      html << context[:hook_caller].render('diagrams/toggle_position', context)
      html << stylesheet_link_tag('redmine_ckeditor_buttons.css', plugin: 'diagrams')
      html
    end

    private

    def module_disabled?(context)
      CONTROLLER_BLACKLIST.include? context[:controller].class.name
    end
  end
end

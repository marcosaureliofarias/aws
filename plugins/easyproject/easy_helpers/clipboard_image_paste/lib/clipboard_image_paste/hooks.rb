#*******************************************************************************
# clipboard_image_paste Redmine plugin.
#
# Hooks.
#
# Authors:
# - Richard Pecl
#
# Terms of use:
# - GNU GENERAL PUBLIC LICENSE Version 2
#*******************************************************************************

module ClipboardImagePaste
  class Hooks  < Redmine::Hook::ViewListener
    # Render image paste form on every page,
    # javascript allows the form to show on issues, news, files, documents, wiki
    def view_layouts_base_body_bottom(context = {})
      unless context[:hook_caller].is_mobile_device?
        context[:hook_caller].render(partial: "clipboard_image_paste/add_form", locals: context)
      end
    end

    def easy_extensions_javascripts_hook(context={})
      context[:template].require_asset('clipboard_image_paste.js')
    end

    def easy_extensions_stylesheets_hook(context={})
      context[:template].require_asset('clipboard_image_paste.css')
    end

  end # class
end # module

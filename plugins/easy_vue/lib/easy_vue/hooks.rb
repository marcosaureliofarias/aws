module EasyVue
  class Hooks < Redmine::Hook::ViewListener
    def view_layouts_base_html_head(context)
      bundle_path = 'easy_vue.js'
      context[:hook_caller].javascript_include_tag(bundle_path, defer: true)
    end

    def view_layouts_base_body_bottom(context)
      ctx = Redmine::Plugin.installed?(:easy_theme_designer) && EasyThemeDesign.in_use ? 'u__with-theme' : ''
      r = context[:hook_caller].raw('<div class="'+ctx+'"><div id="app" class="u__with-theme"></div></div>')
      if Setting.text_formatting == 'HTML'
        js = "window.ckSettings = {};"
        js << "window.ckSettings.mentions = [#{context[:hook_caller].ck_mentions('app').join(',')}];"
        js << "window.ckSettings.options = {#{context[:hook_caller].ck_options('app').join(',')}};"
        r << context[:hook_caller].javascript_tag(js)
      end
      r
    end
  end
end

# Hooks definitions
# http://www.redmine.org/projects/redmine/wiki/Hooks

module EasyZapier
  class Hooks < ::Redmine::Hook::ViewListener

    def easy_extensions_stylesheets_hook(context={})
      context[:template].require_asset('easy_zapier/easy_zapier.css')
    end

  end
end

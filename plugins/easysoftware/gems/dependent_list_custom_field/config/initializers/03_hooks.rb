# Hooks definitions
# http://www.redmine.org/projects/redmine/wiki/Hooks
#
module DependentListCustomField
  class Hooks < ::Redmine::Hook::ViewListener
    def easy_extensions_javascripts_hook(context={})
      context[:template].require_asset('dependent_list_custom_field/dependent_list')
    end
  end
end

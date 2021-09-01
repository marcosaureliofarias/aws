ActiveSupport.on_load(:easyproject, yield: true) do

  require 'easy_calculation/hooks'
  require 'easy_calculation/proposer'

  Redmine::MenuManager.map :project_menu do |menu|
    menu.push :easy_calculation, {:controller => 'easy_calculation', :action => 'show'}, :before => :settings, :caption => :project_module_easy_calculation, :if => Proc.new {|p| User.current.allowed_to?(:view_easy_calculation, p) || User.current.admin?}
  end

  Redmine::MenuManager.map :admin_menu do |menu|
    menu.push :easy_calculation, :easy_calculation_settings_path, :caption => :project_module_easy_calculation, :html => {:class => 'icon icon-calculation-2'}, :if => Proc.new {User.current.admin?}
  end

  Redmine::MenuManager.map :admin_dashboard do |menu|
    menu.push :easy_calculation, :easy_calculation_settings_path, :caption => :project_module_easy_calculation, :html => {:menu_category => 'extensions', :class => 'icon icon-calculation-2'}, :if => Proc.new {User.current.admin?}
  end

  Redmine::AccessControl.map do |map|
    map.project_module :easy_calculation do |pmap|
      pmap.permission :view_easy_calculation, {:easy_calculation => [:show, :order, :save_to_easy_money, :description, :preview, :update], :easy_calculation_items => [:create, :edit, :update, :destroy]}, :read => true

      pmap.permission :add_issue_to_easy_calculation, {:easy_calculation_items => [:add_issue]}
      pmap.permission :remove_issue_from_easy_calculation, {:easy_calculation_items => [:remove_issue]}
    end
  end
end

RedmineExtensions::Reloader.to_prepare do

  require_dependency 'easy_calculation/calculation'
  require_dependency 'easy_calculation/list'

end

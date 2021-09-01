Dir[File.dirname(__FILE__) + '/lib/easy_alerts/rules/*.rb'].each {|file| require_dependency file }
EpmEasyAlerts.register_to_scope(:user, :plugin => :easy_alerts)

ActiveSupport.on_load(:easyproject, yield: true) do

  require 'easy_alerts/hooks'
  require 'easy_alerts/proposer'

  Redmine::MenuManager.map :top_menu do |menu|
    menu.push(:alerts, :alerts_path, {
        :caption => :label_alerts,
        :if => Proc.new{User.current.allowed_to_globally?(:view_alerts, {})},
        :after => :users,
        :html => {:class => 'icon icon-warning'}
      })
    menu.push(:alerts_new, :new_alert_path, {
        :parent => :alerts,
        :caption => :button_alerts_add_new_alert,
        :if => Proc.new{User.current.allowed_to_globally?(:view_alerts, {})}
      })
    menu.push(:alert_reports, { :controller => 'alert_reports', :action => 'index' }, {
        :parent => :alerts,
        :caption => :label_alerts_my_reports,
        :if => Proc.new{User.current.allowed_to_globally?(:view_alerts, {})}
      })
  end

  Redmine::AccessControl.map do |map|
    map.easy_category :easy_alerts do |pmap|

      pmap.permission :view_alerts, {
        :alerts => [:index, :show, :new, :create, :edit, :update, :destroy, :context_changed, :rule_changed, :custom_action, :report],
        :alert_reports => [:index, :show, :new, :create, :edit, :update, :destroy, :alert, :archive_report, :unarchive_report, :archive],
      }, :read => true, :global => true
      #pmap.permission :manage_alert_types, {:alert_types => [:index, :show, :new, :create, :edit, :update, :destroy]}, :global => true
      #pmap.permission :manage_alert_contexts, {:alert_contexts => [:index, :show, :new, :create, :edit, :update, :destroy]}, :global => true
      pmap.permission :manage_alerts_for_all, {}, :global => true

    end
  end

end

RedmineExtensions::Reloader.to_prepare do

  Dir[File.dirname(__FILE__) + '/lib/easy_alerts/none_easy_extensions/*.rb'].each {|file| require_dependency file }

  # pp Sidekiq::Cron::Job.all
  # Sidekiq::Cron::Job.create(name: 'Alerts - evaluation', cron: '*/15 * * * *', class: 'EasyAlertMaintenanceJob')
  # pp Sidekiq::Cron::Job.all


end

#Dir[File.dirname(__FILE__) + '/test/mailers/previews/*.rb'].each {|file| require_dependency file } if Rails.env.development?

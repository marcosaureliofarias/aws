module EasyQuerySettingsHelper
  def easy_query_settings_tabs
    tabs = Array.new
    EasyQuery.registered_subclasses.each do |easy_query_name, options|
      underscored = easy_query_name.underscore
      tabs << {
          :name          => underscored,
          :partial       => options[:easy_query_settings_partial] || 'easy_query_settings/setting',
          :label         => l(underscored, :scope => [:easy_query, :name], :default => h(underscored)),
          :redirect_link => true,
          :url           => { :controller => 'easy_query_settings', :action => 'setting', :tab => underscored }
      }
    end

    return tabs
  end

end

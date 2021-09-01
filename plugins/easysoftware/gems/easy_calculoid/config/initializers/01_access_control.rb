if Redmine::Plugin.installed?(:easy_extensions)
  Redmine::AccessControl.map do |map|
    map.easy_category :easy_calculoid do |pmap|
      pmap.permission(:view_easy_calculoid, {
        }, read: true, global: true)
    end
  end
end

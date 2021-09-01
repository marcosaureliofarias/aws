if Redmine::Plugin.installed?(:easy_extensions) && EasyTwofaRemember.table_exists?
  EasyTwofaRemember.expired.destroy_all
end

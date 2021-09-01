ActiveSupport.on_load(:easyproject, yield: true) do
  require 'easy_project_attachments/hooks'

  Redmine::AccessControl.map do |map|
    map.easy_category :attachment do |pmap|
      pmap.permission :view_easy_project_attachments, { :easy_project_attachments => :index }, :read => true
      pmap.permission :view_easy_global_attachments, {}, global: true
    end
  end
end

RedmineExtensions::Reloader.to_prepare do

  EasyQuery.map do |query|
    query.register 'EasyProjectAttachmentQuery'
  end

end

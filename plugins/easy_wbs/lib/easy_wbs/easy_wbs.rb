module EasyWbs

  def self.easy_extensions?
    Redmine::Plugin.installed?(:easy_extensions)
  end

  def self.easy_money?(project)
    return false unless Redmine::Plugin.installed?(:easy_money)
    return false unless User.current.allowed_to?(:view_easy_money, project)

    RequestStore.store[:easy_wbs_easy_money] ||= {}

    if RequestStore.store[:easy_wbs_easy_money][:project_id].nil?
       RequestStore.store[:easy_wbs_easy_money][:project_id] = Project.has_module('easy_money').where("projects.lft >= #{project.lft} AND projects.rgt <= #{project.rgt}").any?
    else
      RequestStore.store[:easy_wbs_easy_money][:project_id]
    end
  end

end

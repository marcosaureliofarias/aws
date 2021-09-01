module EasyJenkins
  class Hooks < ::Redmine::Hook::ViewListener
    def helper_project_settings_tabs(context = {})
      Rys::Feature.on('easy_jenkins.project.render_tab') do
        project = context[:project]
        return unless project.module_enabled?(:easy_jenkins)

        context[:tabs] << { name: 'easy_jenkins', url: context[:controller].easy_jenkins_settings_project_path(project), partial: 'projects/settings/easy_jenkins_settings', label: :label_easy_jenkins_settings, redirect_link: true } if User.current.allowed_to?(:manage_easy_jenkins_settings, project)
      end
    end

    def helper_easy_issue_tabs(context = {})
      Rys::Feature.on('easy_jenkins.issue.render_tab') do
        issue = context[:issue]
        project = context[:project]
        return unless User.current.allowed_to?(:manage_easy_jenkins_settings, project)

        url = issue_render_tab_path(issue, tab: 'easy_jenkins_ci')
        context[:tabs] << { name: 'easy_jenkins_ci', label: l(:label_easy_jenkins_ci_plural), trigger: "EntityTabs.showAjaxTab(this, '#{url}')"}
      end
    end
  end
end

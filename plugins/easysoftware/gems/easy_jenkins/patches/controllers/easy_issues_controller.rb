Rys::Patcher.add('EasyIssuesController') do
  apply_if_plugins :easy_extensions

  included do
  end

  instance_methods(feature: 'easy_jenkins.issue.render_tab') do
    def render_tab
      case params[:tab]
      when 'easy_jenkins_ci'
        render partial: 'issues/tabs/easy_jenkins_ci'
      else
        super
      end
    end
  end

  class_methods do
  end

end

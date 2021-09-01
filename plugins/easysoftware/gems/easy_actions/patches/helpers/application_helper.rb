Rys::Patcher.add('ApplicationHelper') do

  apply_if_plugins :easy_extensions

  included do

    def include_easy_actions_assets
      unless @include_easy_actions_assets
        include_easy_dagre_d3_assets

        content_for :body_bottom do
          javascript_include_tag('easy_actions/saveSvgAsPng.js', defer: true)
        end

        @include_easy_actions_assets = true
      end
      nil
    end

    def format_easy_action_sequence_instance_status(easy_action_sequence_instance)
      css = ['badge']
      css << case easy_action_sequence_instance.status
             when "waiting"
               "badge-important"
             when "running"
               "badge-notice"
             when "done"
               "badge-positive"
             end

      content_tag(:span, l(easy_action_sequence_instance.status, scope: [:easy_actions, :label_easy_action_sequence_instance_status]), class: css.join(' '))
    end

  end

end

Rys::Patcher.add('ApplicationHelper') do

  apply_if_plugins :easy_extensions

  included do

    def include_easy_dagre_d3_assets
      unless @include_easy_dagre_d3_assets
        include_easy_d3_assets

        content_for :body_bottom do
          javascript_include_tag('easy_dagre_d3/dagre-d3.min.js', defer: true) +
              stylesheet_link_tag('easy_dagre_d3/chart.css')
        end

        @include_easy_dagre_d3_assets = true
      end
      nil
    end

  end

end

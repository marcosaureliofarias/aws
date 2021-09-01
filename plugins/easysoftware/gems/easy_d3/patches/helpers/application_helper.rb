Rys::Patcher.add('ApplicationHelper') do

  apply_if_plugins :easy_extensions

  included do

    def include_easy_d3_assets
      unless @include_easy_d3_assets
        content_for :body_bottom do
          javascript_include_tag('https://d3js.org/d3.v5.min.js', defer: true)
        end

        @include_easy_d3_assets = true
      end
      nil
    end

  end

end

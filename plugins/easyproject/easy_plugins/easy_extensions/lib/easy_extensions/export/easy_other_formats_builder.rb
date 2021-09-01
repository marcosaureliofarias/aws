module EasyExtensions
  module Export
    class EasyOtherFormatsBuilder

      def initialize(view, options = {})
        @view    = view
        @options = options
      end

      # Creates a link tag of the given +name+ using for named format.
      # +query+ parameters follow +name+
      # last parameter +options+ contains *caption* or +url+ *Hash*

      # +name+, +query+, +options+
      def link_to(name, *args)
        options = args.extract_options!
        format  = name.to_s.downcase
        query   = args.shift
        url     = options.delete(:url) || {}
        url.stringify_keys!

        params = EasyExtensions::Tracking.to_params(
            utm_campaign: @options[:utm_campaign],
            utm_content:  @options[:utm_content],
            utm_term:     format)
        params[:export] = true
        params[:format] = format

        if query && url.blank?
          params[:sort] = @view.params[:sort] if @view.params[:sort].present?
          url = query.path(params)
        else
          url = @view.params.to_unsafe_hash.except('page', 'controller', 'action').merge(params).merge(url)
        end
        caption      = options.delete(:caption) || name
        html_options = { :class => format, :rel => 'nofollow' }.merge(options)
        @view.content_tag('span', @view.link_to(caption, url, html_options))
      end
    end
  end
end

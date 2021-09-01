module EasyExtensions
  module EasyEntityCards

    class Base

      attr_reader :entity, :source_entity, :options

      def initialize(entity, source_entity, options = {})
        @entity, @source_entity, @options = entity, source_entity, options

        raise ArgumentError, 'The \'entity\' variable cannot be nil!' if @entity.nil?
        raise ArgumentError, 'The \'source_entity\' variable cannot be nil!' if @source_entity.nil?

        @link_to_entity, @link_to_entity_contextual_links, @avatar = nil, nil, nil
        @detail, @contextual_links                                 = nil, nil
        @footer_left, @footer_right, @footer_bottom                = nil, nil, nil

        @options ||= {}
      end

      def link_to_entity(html = nil, &block)
        internal_html_for(:@link_to_entity, html, &block)
      end

      def link_to_entity_contextual_links(html = nil, &block)
        internal_html_for(:@link_to_entity_contextual_links, html, &block)
      end

      def avatar(html = nil, &block)
        internal_html_for(:@avatar, html, &block)
      end

      def detail(html = nil, &block)
        internal_html_for(:@detail, html, &block)
      end

      def contextual_links(html = nil, &block)
        internal_html_for(:@contextual_links, html, &block)
      end

      def footer_left(html = nil, &block)
        internal_html_for(:@footer_left, html, &block)
      end

      def footer_right(html = nil, &block)
        internal_html_for(:@footer_right, html, &block)
      end

      def footer_bottom(html = nil, &block)
        internal_html_for(:@footer_bottom, html, &block)
      end

      def footer?
        !footer_left.blank? || !footer_right.blank? || !footer_bottom.blank?
      end

      protected

      def internal_html_for(variable, html = nil, &block)
        if !html.blank?
          instance_variable_set(variable, html.to_s)
        elsif block_given?
          instance_variable_set(variable, yield(self))
        else
          instance_variable_get(variable).try(:html_safe)
        end
      end

    end

  end
end

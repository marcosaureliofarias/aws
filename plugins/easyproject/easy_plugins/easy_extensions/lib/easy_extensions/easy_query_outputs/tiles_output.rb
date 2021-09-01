module EasyExtensions
  module EasyQueryOutputs
    class TilesOutput < EasyExtensions::EasyQueryHelpers::EasyQueryOutput

      MAX_LIMIT = 300

      def self.available_for?(query)
        query.tiles_support?
      end

      def self.displays_snapshot?
        true
      end

      def order
        5
      end

      def entity_count
        @entity_count ||= @query.entity_count
      end

      def entities
        @entities ||= @query.entities(fetch: true, limit: self.class::MAX_LIMIT, preload: @query.entity.new.respond_to?(:tag_list) ? [:tags] : [])
      end

      def card_size_class
        case entity_count
        when 0, 1
          'size-10'
        when 2
          'size-5'
        when 3
          'size-33 size-s-5'
        else
          'size-33 size-s-5 size-xl-25'
        end
      end

      def render_context
        @render_context ||= build_context(@query.render_context)
      end

      def tile_settings
        @query.settings['tile'] || {}
      end

      def tile_avatar_column_name
        tile_settings['avatar_column']
      end

      def tile_avatar_column
        @tile_avatar_column ||= @query.columns.detect { |col| col.name == tile_avatar_column_name }
      end

      def tile_column_names
        res = tile_settings['columns'] || []
        res |= [tile_avatar_column_name].compact
      end

      def before_render
        return unless tile_column_names.any?
        @columns_was        = @query.columns
        @query.column_names = tile_column_names
      end

      def after_render
        @query.columns = @columns_was if @columns_was
      end

      def header_links(entity)
        render_context.header_links(entity)
      end

      def export_links(entity)
        links = []
        h.easy_entity_exports(entity).each do |format, options|
          url   = options[:url] || h.__send__(options[:path_method] || "#{entity.class.name.underscore}_path", entity, format: format)
          cls   = options[:class] || 'icon icon-' + format.to_s
          title = options[:title] || h.l("title_other_formats_links_#{format}")
          links << h.__send__(options[:link_method] || :link_to, h.easy_export_name(format), url, remote: options[:remote], class: cls, title: title)
        end
        links.join(' ').html_safe
      end

      def tag_list(entity)
        if entity.respond_to?(:tag_list)
          entity_tags = entity.tags
          h.content_tag(:span, entity_tags.map { |t| h.link_to(t, h.easy_tag_path(t.name)) }.join(', ').html_safe, class: 'entity-array') if entity_tags.any?
        end
      end

      private

      def build_context(view_context)
        case view_context
        when nil
          DefaultRenderContext.new(self)
        when 'entity_assignments'
          EntityAssignmentContext.new(self)
        end
      end

    end


    class DefaultRenderContext

      def initialize(output)
        @output = output
      end

      def header_links(entity)
      end

    end

    class EntityAssignmentContext < DefaultRenderContext

      def initialize(output)
        super
        @source_entity = output.options[:source_entity]
      end

      def header_links(entity)
        if !@output.options[:hide_remove_entity_link] && !(@output.options[:options] && @output.options[:options][:hide_remove_entity_link])
          @output.h.link_to(@output.h.content_tag(:span, @output.h.l(:title_remove_referenced_entity_from_entity, source_entity: @source_entity.to_s), class: 'tooltip'), {
              controller:                 'easy_entity_assignments', action: 'destroy',
              source_entity_type:         @source_entity.class.name, source_entity_id: @source_entity,
              referenced_collection_name: @output.options[:options][:referenced_collection_name],
              referenced_entity_type:     entity.class.name, referenced_entity_id: entity,
              module_name:                @output.options[:options][:module_name] },
                            method: :delete, remote: true, class: 'icon icon-unlink',
                            data:   { confirm: @output.h.l(:text_are_you_sure) },
                            title:  @output.h.l(:title_remove_referenced_entity_from_entity, source_entity: @source_entity.to_s))
        end
      end

    end
  end

end

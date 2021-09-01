module EasyProjectAttachments
  module EntityAttributeHelperPatch

    def self.included(base)
      base.include(InstanceMethods)

      base.class_eval do

        def format_html_attachment_attribute(entity_class, attribute, unformatted_value, options={})
          value = format_entity_attribute(entity_class, attribute, unformatted_value, options)

          case attribute.name
          when :container_type
            l(:"label_#{value.to_s.underscore}")
          when :container_link
            link_to_entity(options[:entity].container)
          when :filename
            link_to_attachment(options[:entity])
          when :filesize
            number_to_human_size(value.to_i)
          when :downloads
            "#{value}x"
          when :project
            link_to_project(options[:entity].project)
          when :thumbnail
            link_to_attachment_with_thumbnail(options[:entity],
                                              only_path: true,
                                              class: 'attachment',
                                              title: l(:button_show)) if options[:entity].visible?
          else
            h(value)
          end
        end

      end
    end

    module InstanceMethods

    end

  end

end
EasyExtensions::PatchManager.register_helper_patch 'EntityAttributeHelper', 'EasyProjectAttachments::EntityAttributeHelperPatch'

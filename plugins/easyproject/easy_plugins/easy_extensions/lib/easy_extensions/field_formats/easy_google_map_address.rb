module EasyExtensions
  module FieldFormats

    class EasyGoogleMapAddress < Redmine::FieldFormat::TextFormat
      add 'easy_google_map_address'

      self.form_partial = nil

      def label
        :label_easy_google_maps_address
      end

      def formatted_value(view, custom_field, value, customized = nil, html = false)
        return '' if value.blank?
        return value.to_s unless html
        google_maps_url = "#{Setting.protocol}://maps.google.com/maps?f=q&q=#{h(value).tr("\n", ',')}&ie=UTF8&om=1"

        s = h(value).gsub("\n", '<br />')
        s << '<br />'

        s << view.link_to(l(:button_link_easy_google_map_address), google_maps_url, :class => 'external', :target => '_blank')
        s.html_safe
      end

      def edit_tag(view, tag_id, tag_name, custom_value, options = {})
        view.text_area_tag(tag_name, custom_value.value, { :id => tag_id, :rows => 4, :cols => 50 }.merge(options))
      end

    end

  end
end

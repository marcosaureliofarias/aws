module EasyContactPatch
  module ApplicationHelperPatch

    def self.included(base)
      base.extend(ClassMethods)
      base.include(InstanceMethods)

      base.class_eval do
        class << self
          alias_method_chain :redmine_links_allowed_prefixes, :easy_contact
        end

        def url_to_easy_contact(easy_contact, options={})
          easy_contact_url(easy_contact, options.merge(url_standard_options(options)).merge(:project_id => @project))
        end

        def link_to_easy_contact(easy_contact, options={})
          link_to(easy_contact.name, easy_contact_path(easy_contact, {:project_id => @project}.merge(options.delete(:url) || {})), {:class => entity_css_icon(easy_contact)}.merge(options))
        end

        def render_easy_entity_card_easy_contact(easy_contact, source_entity, options = {})
          easy_entity_card(easy_contact, source_entity, options) do |eec|

            eec.link_to_entity link_to_entity(easy_contact, {title: easy_contact.easy_contact_type.to_s})
            eec.avatar avatar(easy_contact, :style => :medium, :no_link => true)

            detail = ''

            cfs = easy_contact.visible_custom_field_values.reject{|cf| cf.value.blank? && !cf.custom_field.show_empty?}

            cfs.each_with_index do |cf, idx|
              detail << content_tag(:p, content_tag(:span, show_value(cf), :title => cf.custom_field.translated_name))
            end
            eec.detail detail

            eec.footer_left content_tag(:span, easy_contact.tag_list.map{|t| link_to(t, easy_tag_path(t))} .join(', ').html_safe, :class => 'entity-array') if !easy_contact.tag_list.blank?
            cl = []
            cl << link_to_google_map(easy_contact.address, :name => '')
            cl << link_to(content_tag(:span, 'vCard', :class => 'tooltip'), url_to_easy_contact(easy_contact, :format => :vcf), :class => 'icon icon-vcard', :title => l(:title_other_formats_links_vcard))
            cl << link_to(content_tag(:span, 'QR', :class => 'tooltip'), url_to_easy_contact(easy_contact, :format => :qr), :class => 'icon icon-qr', :title => l(:title_other_formats_links_qr), :remote => true)
            eec.footer_right cl.join(' ')
          end
        end

      end
    end

    module InstanceMethods

    end

    module ClassMethods
      def redmine_links_allowed_prefixes_with_easy_contact
        redmine_links_allowed_prefixes_without_easy_contact + ['easy_contact']
      end
    end

  end

end
EasyExtensions::PatchManager.register_helper_patch 'ApplicationHelper', 'EasyContactPatch::ApplicationHelperPatch'

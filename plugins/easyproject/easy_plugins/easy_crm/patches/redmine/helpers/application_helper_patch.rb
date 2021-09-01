module EasyCrm
  module ApplicationHelperPatch

    def self.included(base)
      base.extend(ClassMethods)
      base.include(InstanceMethods)

      base.class_eval do

        alias_method_chain :edit_entity_path, :easy_crm
        class << self
          alias_method_chain :redmine_links_allowed_prefixes, :easy_crm
        end

        def bulk_edit_link_to_easy_crm_case(easy_crm_case)
          link_to "#{l(:field_easy_crm_case)}: #{easy_crm_case.to_s}", url_to_easy_crm_case(easy_crm_case)
        end

        def link_to_easy_crm_case(easy_crm_case, options = {})
          link_to(easy_crm_case, url_to_easy_crm_case(easy_crm_case, options), options[:html] || {})
        end

        def url_to_easy_crm_case(easy_crm_case, options={})
          options[:lock_version] = easy_crm_case.lock_version if options[:format].to_s == 'json'
          easy_crm_case_url(easy_crm_case, options.merge(url_standard_options(options)))
        end

        def easy_crm_case_journal_id_link(journal, entity)
          link_to(easy_crm_case_path(entity, :anchor => "change-#{journal.id}"), :class => 'journal journal-id', :title => "#{truncate(h(entity.name), :length => 100)}") do
            (content_tag(:i, '', :class => 'icon-link') + content_tag(:span, journal.id.to_s)).html_safe
          end
        end

        def render_easy_entity_card_easy_crm_case(easy_crm_case, source_entity, options = {})
          easy_entity_card(easy_crm_case, source_entity, options) do |eec|
            eec.link_to_entity link_to(easy_crm_case, url_to_easy_crm_case(easy_crm_case))

            eec.avatar(avatar(easy_crm_case.assigned_to, style: :medium, no_link: true)) if easy_crm_case.assigned_to
            if easy_crm_case.external_assigned_to && EasyUserType.easy_type_partner.any?
              eec.avatar(avatar(easy_crm_case.external_assigned_to, style: :medium, no_link: true))
            end

            str = "
      <div class=\"splitcontent\">
        <div class=\"splitcontentleft\">
          <p>
            <span>#{easy_crm_case.assigned_to}</span>
          </p>"
          if EasyUserType.easy_type_partner.any?
            str << "<p>
              <span>#{easy_crm_case.external_assigned_to}</span>
            </p>"
          end
          str << "<p>
            <span class=\"status\">#{easy_crm_case.easy_crm_case_status.name}</span>
          </p>
        </div>
        <div class=\"splitcontentright\">
          <p>
            <span title=\"#{j EasyCrmCase.human_attribute_name(:contract_date)}\">#{easy_crm_case.contract_date ? format_date(easy_crm_case.contract_date) : '-'}</span>
          </p>
          <p>
            <span title=\"#{j EasyCrmCase.human_attribute_name(:next_action)}\">#{easy_crm_case.next_action ? format_date(easy_crm_case.next_action) : '-'}</span>
          </p>
          <p>
            <span title=\"#{j EasyCrmCase.human_attribute_name(:price)}\">#{easy_crm_case.price ? format_price(easy_crm_case.price, easy_crm_case.currency) : '-'}</span>
          </p>
        </div>
      </div>"
            eec.detail str

            eec.footer_left content_tag(:span, easy_crm_case.tag_list.map{|t| link_to(t, easy_tag_path(t))} .join(', ').html_safe, :class => 'entity-array') if !easy_crm_case.tag_list.blank?
            cl = []
            cl << link_to('QR', url_to_easy_crm_case(easy_crm_case, :format => :qr), :remote => true, :class => 'icon icon-qr', :title => l(:title_other_formats_links_qr))
            eec.footer_right cl.join(' ')

          end
        end
      end
    end

    module InstanceMethods

      def edit_entity_path_with_easy_crm(entity, options = {})
        if entity.is_a?(EasyCrmCase)
          edit_easy_crm_case_path(entity, options)
        else
          edit_entity_path_without_easy_crm(entity, options)
        end
      end

    end

    module ClassMethods
      def redmine_links_allowed_prefixes_with_easy_crm
        redmine_links_allowed_prefixes_without_easy_crm + ['easy_crm_case']
      end
    end

  end

end
EasyExtensions::PatchManager.register_helper_patch 'ApplicationHelper', 'EasyCrm::ApplicationHelperPatch'

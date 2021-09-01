module EasyPatch
  module AttachmentsHelperPatch

    def self.included(base)
      base.include(InstanceMethods)

      base.class_eval do

        alias_method_chain :link_to_attachments, :easy_extensions
        alias_method_chain :render_api_attachment_attributes, :easy_extensions
        alias_method_chain :render_pagination, :easy_extensions

        # Options:
        #   :preloaded_reads -- if contains a collection of EasyUserReadEntity for attachments param, then it is little quicker.
        def attachment_row(attachment, options = {})
          return if attachment.new_record?

          show_checkboxes = options[:show_checkboxes].nil? ? true : options[:show_checkboxes]
          row             = '<tr '
          row << 'class="hascontextmenu"' unless options[:do_not_show_context_menu]
          row << '>'
          checked = Array.wrap(options[:selected]).include?(attachment.id.to_s)
          row << content_tag(:td, check_box_tag('ids[]', attachment.id, checked, :id => nil), :class => 'checkbox', :style => !show_checkboxes && 'display: none;' || '')
          linked_attachment = attachment.current_version.new_record? ? attachment : attachment.current_version
          row << '<td class="doc-td-title name">' + link_to_attachment(linked_attachment, :class => 'icon icon-attachment')
          unless attachment.description.blank?
            row << h(" - #{attachment.description}")
          end
          row << "<span class=\"size\">(#{number_to_human_size attachment.filesize})</span>"
          row << content_tag(:em, "  - v#{attachment.version} ")
          if !options[:unread] &&
              (options[:preloaded_reads] ? !options[:preloaded_reads].detect { |read| read.user_id == User.current.id && read.entity_type == attachment.current_version.class.name && read.entity_id == attachment.current_version.id } : attachment.current_version.unread?(User.current)
              )
            row << content_tag(:span, '', :class => 'unread-entity icon-message red-icon', :title => l(:label_unread_entity))
          end

          call_hook(:helper_attachment_row_after_title, row: row, attachment: linked_attachment, options: options)

          row << '</td>'

          if options[:author]
            row << "<td><span class=\"author\">#{h(attachment.current_version.author)}, #{format_time(attachment.current_version.updated_at)}</span></td>"
          end

          row << '<td class="fast-icons easy-query-additional-ending-buttons hide-when-print">'

          if EasySetting.value('easy_webdav_enabled') && options[:editable]
            row << link_to(content_tag(:span, l(:heading_online_editing), :class => 'tooltip'), webdav_modal_attachment_path(attachment, :back_url => request.original_url), :class => 'icon icon-cloud', :remote => true, :title => l(:heading_online_editing))
          end

          row << link_to(content_tag(:span, l(:heading_easy_short_urls_new), :class => 'tooltip'), easy_short_urls_path(:entity_type => attachment.class.name, :entity_id => attachment.id, :source_url => named_attachment_url(attachment, attachment.filename)), :class => 'icon icon-crm-1', :remote => true, :title => l(:heading_easy_short_urls_new))
          row << link_to(content_tag(:span, l(:title_add_new_attachment_version), :class => 'tooltip'), new_attachment_version_path(:id => attachment.id), :class => 'icon icon-file-new', :remote => true, :title => l(:title_add_new_attachment_version)) if options[:show_new_version] && options[:editable]
          if attachment.is_a?(Attachment) && attachment.custom_values.any? { |custom_value| custom_value.value.present? }
            row << link_to_function('',
                                    "$.get('#{attachment_custom_fields_attachment_url(attachment)}', function(data) { $('#ajax-modal').html(data); showModal('ajax-modal', 500); $('#ajax-modal').dialog('option', { buttons: [] }); })",
                                    :class => 'icon icon-details', :title => l(:title_show_attachment_custom_fields)
            )
          end
          row << content_tag(:span, content_tag(:span, l(:button_attachment_context_menu), :class => 'tooltip'), :class => 'btn_contextmenu_trigger icon icon-list', :id => "btn-attachment-#{attachment.id}", :title => l(:button_attachment_context_menu)) unless options[:do_not_show_context_menu]

          row << options[:additional_buttons].call(attachment).to_s if options[:additional_buttons]

          if options[:deletable]
            row << link_to(content_tag(:span, l(:button_delete), :class => 'tooltip'), { :controller => 'attachments', :action => 'destroy', :id => attachment },
                           :data   => { :confirm => l(:text_are_you_sure) },
                           :method => :delete,
                           :class  => 'icon icon-del',
                           :title  => l(:button_delete))
          end
          row << '</td></tr>'

          row.html_safe
        end

        def load_reads_for_attachments(attachments, klass = nil, user = nil)
          klass ||= 'AttachmentVersion'
          user  ||= User.current
          ids   = attachments.collect { |a| a.current_version.id } if klass.end_with?('Version')
          ids   ||= attachments.collect { |a| a.id }
          EasyUserReadEntity.where(entity_id: ids, entity_type: klass, user_id: user.id)
        end

        def replace_cid_links(content)
          content.gsub!(/["']cid:([^>]+?)["']/) do # <img src="cid:522e1fa43219a.jpg"></a> ==> 522e1fa43219a.jpg
            url_for(request.query_parameters.merge(:cid => $1))
          end
          content
        end
      end

    end

    module InstanceMethods

      # Displays view/delete links to the attachments of the given object
      # Options:
      #   :author -- author names are not displayed if set to false
      def link_to_attachments_with_easy_extensions(container, options = {})
        attachments = (options[:attachments] || container.attachments.preload({ :versions => :author }, :custom_values, :container)).to_a
        if attachments.any? || container.has_attachments?
          options = {
              :editable         => container.attachments_editable?,
              :deletable        => container.attachments_deletable?,
              :author           => true,
              :show_new_version => true
          }.merge(options)
          attachments.select! { |attachment| attachment.category == options[:category] } if options[:category]

          email_extensions = ['.eml', '.msg']
          email_mimes      = email_extensions.map { |ext| Redmine::MimeType.of("attachment#{ext}") }
          attachments.select! do |attachment|
            email_mimes.include?(attachment.content_type) || email_extensions.include?(File.extname(attachment.filename))
          end if options[:only_mails]

          attachments.reject! do |attachment|
            email_mimes.include?(attachment.content_type) || email_extensions.include?(File.extname(attachment.filename))
          end if options[:without_mails]

          options[:preloaded_reads] = load_reads_for_attachments(attachments, options[:reads_klass])

          render :partial => 'attachments/links',
                 :locals  => {
                     :container   => container,
                     :attachments => attachments,
                     :options     => options,
                     :thumbnails  => (options[:thumbnails] && Setting.thumbnails_enabled?)
                 }
        end
      end

      def render_api_attachment_attributes_with_easy_extensions(attachment, api)
        api.id attachment.id
        api.filename attachment.filename
        api.filesize attachment.filesize
        api.content_type attachment.content_type
        api.description attachment.description
        api.content_url Rails.application.routes.url_helpers.download_named_attachment_url(attachment, attachment.filename, Mailer.default_url_options)
        api.href_url Rails.application.routes.url_helpers.named_attachment_url(attachment, attachment.filename, Mailer.default_url_options)
        if attachment.thumbnailable?
          api.thumbnail_url Rails.application.routes.url_helpers.thumbnail_url(attachment, Mailer.default_url_options)
        end
        if attachment.author
          api.author(:id => attachment.author.id, :name => attachment.author.name)
        end
        api.created_on attachment.created_on
      end

      def render_pagination_with_easy_extensions
        return unless @paginator

        pagination_links_each @paginator do |text, parameters, options|
          if att = @attachments[parameters[:page] - 1]
            link_to text, named_attachment_path(att, att.filename, no_download: true)
          end
        end
      end
    end

  end
end
EasyExtensions::PatchManager.register_helper_patch 'AttachmentsHelper', 'EasyPatch::AttachmentsHelperPatch'

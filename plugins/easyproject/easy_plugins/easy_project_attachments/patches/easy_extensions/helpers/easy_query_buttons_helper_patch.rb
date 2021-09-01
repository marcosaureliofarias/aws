module EasyProjectAttachments
  module EasyQueryButtonsHelperPatch

    def self.included(base)
      base.class_eval do

        def easy_project_attachment_query_additional_ending_buttons(easy_attachment, options = {})
          s = ''
          s << link_to_attachment(easy_attachment, text: l(:button_download), download: true) if easy_attachment.editable?
          s << link_to(l(:button_delete), attachment_path(easy_attachment), method: :delete, data: {confirm: l(:text_are_you_sure)}, class: 'icon icon-del', title: l(:button_delete)) if easy_attachment.deletable?
          s.html_safe
        end

      end
    end

  end
end

EasyExtensions::PatchManager.register_helper_patch 'EasyQueryButtonsHelper', 'EasyProjectAttachments::EasyQueryButtonsHelperPatch'

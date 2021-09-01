module EasyButtons
  module EasyQueryButtonsHelperPatch

    def self.included(base)
      base.class_eval do

        def easy_button_query_additional_ending_buttons(easy_button, options={})
          s = ''

          s << link_to(l(:button_edit), { controller: 'easy_buttons', action: 'edit', id: easy_button }, class: 'icon icon-edit', title: l(:button_edit))
          s << link_to(l(:button_copy), { controller: 'easy_buttons', action: 'copy', id: easy_button }, class: 'icon icon-copy', title: l(:button_copy))
          s << link_to(l(:button_delete), { controller: 'easy_buttons', action: 'destroy', id: easy_button, back_url: original_url }, method: :delete, data: { confirm: l(:text_are_you_sure) }, class: 'icon icon-del')

          s.html_safe
        end

      end
    end

  end
end

EasyExtensions::PatchManager.register_helper_patch 'EasyQueryButtonsHelper', 'EasyButtons::EasyQueryButtonsHelperPatch'

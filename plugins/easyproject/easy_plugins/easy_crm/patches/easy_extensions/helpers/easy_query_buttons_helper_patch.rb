module EasyCrm
  module EasyQueryButtonsHelperPatch

    def self.included(base)
      base.class_eval do

        def easy_crm_case_query_additional_beginning_buttons(easy_crm_case, options = {})
          return '' if easy_crm_case.nil?
          s = ''
          s << content_tag(:i, '', :class => 'icon-warning red', :title => l(:label_easy_crm_case_need_reaction)) if easy_crm_case.need_reaction?
          s << content_tag(:i, '', :class => 'icon-cancel red', :title => l(:label_canceled)) if easy_crm_case.is_canceled?
          s.html_safe
        end

        def easy_crm_case_query_additional_ending_buttons(entity, options = {})
          s = ''
          call_hook(:helper_easy_crm_case_query_ending_buttons, {:entity => entity, :content => s})
          s << link_to(content_tag(:span, l(:button_edit), :class => 'tooltip'), edit_easy_crm_case_path(entity), :class => 'icon icon-edit') if entity.editable?
          s << link_to(content_tag(:span, l(:button_delete), :class => 'tooltip'), easy_crm_case_path(entity, :back_url => back_url), :method => :delete, :data => {:confirm => l(:text_are_you_sure)}, :class => 'icon icon-del') if entity.deletable?
          s.html_safe
        end

        def easy_crm_contact_query_additional_ending_buttons(entity, options={})
          s = ''
          s << link_to('#', :onclick => "$(this).closest('tr').next('tr').find('table.easy_crm_cases').toggle();$(this).find('i').toggleClass('down');return false;", :class => 'icon icon-arrow') do
            l(:label_easy_crm_cases)
          end
          s << link_to(l(:button_easy_crm_new_case), new_easy_crm_case_path('easy_crm_case[easy_contact_ids][]' => entity, :project_id => @project), :class => 'icon icon-add')
          s.html_safe
        end

        def easy_crm_country_value_query_additional_ending_buttons(entity, options = {})
          s = ''
          s << link_to(content_tag(:span, l(:button_edit), :class => 'tooltip'), edit_easy_crm_country_value_path(entity), :class => 'icon icon-edit')
          s << link_to(content_tag(:span, l(:button_delete), :class => 'tooltip'), easy_crm_country_value_path(entity), :method => :delete, :data => {:confirm => l(:text_are_you_sure)}, :class => 'icon icon-del')
          s.html_safe
        end

        def easy_lead_score_query_additional_ending_buttons(entity, options = {})
          s = ''
          s << link_to(content_tag(:span, l(:button_edit), :class => 'tooltip'), edit_easy_lead_score_path(entity), :class => 'icon icon-edit')
          s << link_to(content_tag(:span, l(:button_delete), :class => 'tooltip'), easy_lead_score_path(entity), :method => :delete, :data => {:confirm => l(:text_are_you_sure)}, :class => 'icon icon-del')
          s.html_safe
        end
      end
    end

  end
end

EasyExtensions::PatchManager.register_helper_patch 'EasyQueryButtonsHelper', 'EasyCrm::EasyQueryButtonsHelperPatch'

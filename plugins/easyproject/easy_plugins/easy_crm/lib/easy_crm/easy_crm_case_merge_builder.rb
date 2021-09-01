module EasyCrm

  class EasyCrmCaseMergeBuilder < EasyExtensions::EasyLabelledFormBuilder

    def easy_crm_case_merge_select_tag(attribute)
      @template.select_tag(attribute, @template.options_for_select(@options[:source_easy_crm_cases].map { |c| [@template.merge_input_attributes_name(c, attribute.to_s), c.id] }, @object.id), class: 'push-right source', id: "source_easy_crm_case_#{attribute}")
    end

  end
end

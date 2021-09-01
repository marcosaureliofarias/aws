module EasyComputedCustomFields

  class EasyCrmCaseTokenSymbol < EasyComputedCustomFields::EasyRecordTokenSymbol

    def model
      EasyCrmCase
    end

    def identifier
      'easy_crm_case'
    end

    def available_fields
      ['price']
    end

    def nonsumable_fields
      ['price']
    end

    def label_for_field_price
      EasyCrmCase.human_attribute_name(:price)
    end

  end

end if Redmine::Plugin.installed?(:easy_computed_custom_fields)
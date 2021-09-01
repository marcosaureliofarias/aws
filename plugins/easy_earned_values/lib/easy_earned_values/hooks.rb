module EasyEarnedValues
  class Hooks < Redmine::Hook::ViewListener

    # Reset saved page module to prevent cross-project view
    def model_project_copy_before_save(context = {})
      destination_project = context[:destination_project]

      modules = EasyPageZoneModule.joins(:module_definition).
                                   where(entity_id: destination_project.id,
                                         easy_page_modules: { type: 'EpmEasyEarnedValue' })
      modules.each do |page_module|
        if page_module.settings.has_key?('easy_earned_value_id')
          page_module.settings.delete('easy_earned_value_id')
          page_module.save
        end
      end
    end

  end
end

module EasyCrm
  module EasyImportsHelperPatch
    def import_entities_tabs
      super << { name: 'crm_cases', partial: 'easy_imports/tabs/crm_cases', label: l('label_easy_crm_cases') }
    end
  end
end
EasyExtensions::PatchManager.register_helper_patch('EasyImportsHelper', 'EasyCrm::EasyImportsHelperPatch', prepend: true)

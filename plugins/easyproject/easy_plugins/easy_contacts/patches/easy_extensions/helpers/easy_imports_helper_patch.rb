module EasyContacts
  module EasyImportsHelperPatch
    def import_entities_tabs
      super << { name: 'contacts', partial: 'easy_imports/tabs/contacts', label: l('label_easy_contacts') }
    end
  end
end
EasyExtensions::PatchManager.register_helper_patch('EasyImportsHelper', 'EasyContacts::EasyImportsHelperPatch', prepend: true)

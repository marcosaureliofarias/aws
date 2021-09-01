module EasyContactPatch
  module EasyUserTypesHelperPatch

    def self.included(base)
      base.class_eval do

        def easy_contact_types_for_select
          select_options = [["<< #{l(:general_all)} >>", 'all']]
          select_options.concat(EasyContactType.sorted.pluck(:type_name, :id))
          select_options
        end

      end
    end

  end
end
EasyExtensions::PatchManager.register_helper_patch 'EasyUserTypesHelper', 'EasyContactPatch::EasyUserTypesHelperPatch'

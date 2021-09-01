module EasyAgileBoard
  module VersionPatch

    def self.included(base)
      base.class_eval do

        has_one :easy_sprint, dependent: :nullify

      end
    end

  end

end
EasyExtensions::PatchManager.register_model_patch 'Version', 'EasyAgileBoard::VersionPatch'

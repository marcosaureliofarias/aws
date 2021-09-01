module EasyPatch
  module JournalDetailPatch

    def self.included(base)
      base.class_eval do
        html_fragment :value, scrub: :strip
        html_fragment :old_value, scrub: :strip
      end
    end
  end
end
EasyExtensions::PatchManager.register_model_patch 'JournalDetail', 'EasyPatch::JournalDetailPatch'

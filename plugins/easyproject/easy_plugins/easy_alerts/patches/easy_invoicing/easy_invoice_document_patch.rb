module EasyAlerts
  module EasyInvoiceDocumentPatch

    def self.included(base)
      base.class_eval do

        scope :alerts_active_projects, -> { joins(:project).merge(Project.active) }

      end
    end

  end
end
EasyExtensions::PatchManager.register_model_patch 'EasyInvoiceDocument', 'EasyAlerts::EasyInvoiceDocumentPatch', if: -> { Redmine::Plugin.installed?(:easy_invoicing) }

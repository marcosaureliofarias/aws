module EasyMoney
  module EasyProjectAttachmentQueryPatch

    def self.included(base)
      base.include(InstanceMethods)

      base.class_eval do

        alias_method_chain :project_statement, :easy_money

      end
    end

    module InstanceMethods

      def project_statement_with_easy_money
        return nil unless self.project

        project_statement_without_easy_money +
        " OR CASE #{Attachment.table_name}.container_type
          WHEN 'EasyMoneyTravelExpense' THEN EXISTS(SELECT i.id FROM #{EasyMoneyTravelExpense.table_name} i WHERE i.id = #{Attachment.table_name}.container_id AND i.project_id = #{self.project.id})
          WHEN 'EasyMoneyTravelCost' THEN EXISTS(SELECT i.id FROM #{EasyMoneyTravelCost.table_name} i WHERE i.id = #{Attachment.table_name}.container_id AND i.project_id = #{self.project.id})
          WHEN 'EasyMoneyExpectedExpense' THEN EXISTS(SELECT i.id FROM #{EasyMoneyExpectedExpense.table_name} i WHERE i.id = #{Attachment.table_name}.container_id AND i.project_id = #{self.project.id})
          WHEN 'EasyMoneyOtherExpense' THEN EXISTS(SELECT i.id FROM #{EasyMoneyOtherExpense.table_name} i WHERE i.id = #{Attachment.table_name}.container_id AND i.project_id = #{self.project.id})
          WHEN 'EasyMoneyExpectedRevenue' THEN EXISTS(SELECT i.id FROM #{EasyMoneyExpectedRevenue.table_name} i WHERE i.id = #{Attachment.table_name}.container_id AND i.project_id = #{self.project.id})
          WHEN 'EasyMoneyOtherRevenue' THEN EXISTS(SELECT i.id FROM #{EasyMoneyOtherRevenue.table_name} i WHERE i.id = #{Attachment.table_name}.container_id AND i.project_id = #{self.project.id})
        END"
      end
    end
  end
end
EasyExtensions::PatchManager.register_model_patch('EasyProjectAttachmentQuery', 'EasyMoney::EasyProjectAttachmentQueryPatch', :if => Proc.new{Redmine::Plugin.installed?(:easy_project_attachments)})

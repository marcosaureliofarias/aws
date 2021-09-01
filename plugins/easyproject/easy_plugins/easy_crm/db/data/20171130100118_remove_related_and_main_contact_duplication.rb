class RemoveRelatedAndMainContactDuplication < EasyExtensions::EasyDataMigration
  def up
    if !Redmine::Plugin.installed?(:modification_easysoftware)
      case ActiveRecord::Base.connection.adapter_name.downcase
      when /(mysql|mariadb)/
        ActiveRecord::Base.connection.execute("DELETE #{EasyContactEntityAssignment.table_name}.* FROM #{EasyContactEntityAssignment.table_name} JOIN #{EasyCrmCase.table_name} ON #{EasyContactEntityAssignment.table_name}.entity_id = #{EasyCrmCase.table_name}.id AND #{EasyContactEntityAssignment.table_name}.entity_type = 'EasyCrmCase' WHERE #{EasyContactEntityAssignment.table_name}.entity_type = 'EasyCrmCase' AND #{EasyContactEntityAssignment.table_name}.easy_contact_id = #{EasyCrmCase.table_name}.main_easy_contact_id")
      when /postgresql/
        ActiveRecord::Base.connection.execute("DELETE FROM #{EasyContactEntityAssignment.table_name} USING #{EasyCrmCase.table_name} WHERE #{EasyContactEntityAssignment.table_name}.entity_id = #{EasyCrmCase.table_name}.id AND #{EasyContactEntityAssignment.table_name}.entity_type = 'EasyCrmCase' AND #{EasyContactEntityAssignment.table_name}.easy_contact_id = #{EasyCrmCase.table_name}.main_easy_contact_id")
      end
    end
  end


  def down
    # EasyCrmCase.preload(:easy_contacts, :main_easy_contact).where.not(main_easy_contact_id: nil).find_each(batch_size: 200) do |crm|
    #   crm.easy_contacts += [crm.main_easy_contact]
    # end
  end
end

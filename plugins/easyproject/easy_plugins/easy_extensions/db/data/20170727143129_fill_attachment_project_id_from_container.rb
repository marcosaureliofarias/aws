class FillAttachmentProjectIdFromContainer < EasyExtensions::EasyDataMigration
  def up
    types          = Attachment.where.not(container_type: nil).distinct.pluck(:container_type)
    selected_types = types.map do |type|
      klass        = type.safe_constantize
      have_project = klass.nil? ? false : klass.attribute_names.include?('project_id')
      klass if have_project
    end.compact

    case ActiveRecord::Base.connection.adapter_name.downcase
    when /mysql/
      selected_types.each do |type|
        Attachment.where(container_type: type.to_s).joins("INNER JOIN #{type.base_class.table_name} on #{type.base_class.table_name}.id = container_id").update_all("attachments.project_id = #{type.base_class.table_name}.project_id")
      end
      Attachment.joins(:versions).update_all('attachment_versions.project_id = attachments.project_id')
    when /postgresql/
      selected_types.each do |type|
        ActiveRecord::Base.connection.execute("
          UPDATE attachments
          SET project_id = #{type.base_class.table_name}.project_id
          FROM #{type.base_class.table_name}
          WHERE
            attachments.container_type = '#{type.base_class.to_s}' AND
            attachments.container_id = #{type.base_class.table_name}.id
          ")
      end
      ActiveRecord::Base.connection.execute("
          UPDATE attachment_versions
          SET project_id = attachments.project_id
          FROM attachments
          WHERE
            attachments.id = attachment_versions.attachment_id
          ")
    end

  end

  def down
  end
end

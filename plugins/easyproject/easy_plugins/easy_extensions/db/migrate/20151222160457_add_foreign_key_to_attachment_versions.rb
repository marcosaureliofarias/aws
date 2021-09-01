class AddForeignKeyToAttachmentVersions < ActiveRecord::Migration[4.2]
  def change
    AttachmentVersion.joins("LEFT OUTER JOIN #{Attachment.quoted_table_name} ON #{AttachmentVersion.quoted_table_name}.attachment_id = #{Attachment.quoted_table_name}.id").
        where("NOT EXISTS( SELECT 1 AS one FROM #{Attachment.quoted_table_name} WHERE id = #{AttachmentVersion.quoted_table_name}.attachment_id )").destroy_all
    add_index :attachment_versions, :attachment_id
  end
end
class AddColumnProjectIdToAttachment < ActiveRecord::Migration[4.2]
  def up
    add_column :attachments, :project_id, :integer, { null: true, index: true }
    add_column :attachment_versions, :project_id, :integer, { null: true, index: true }
    Attachment.reset_column_information
    AttachmentVersion.reset_column_information
  end

  def down
    remove_column :attachments, :project_id
    remove_column :attachment_versions, :project_id
  end
end

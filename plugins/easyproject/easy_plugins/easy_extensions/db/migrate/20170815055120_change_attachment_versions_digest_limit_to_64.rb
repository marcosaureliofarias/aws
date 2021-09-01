class ChangeAttachmentVersionsDigestLimitTo64 < ActiveRecord::Migration[4.2]
  def up
    change_column :attachment_versions, :digest, :string, limit: 64
  end

#  def down
#    change_column :attachment_versions, :digest, :string, limit: 40
#  end
end

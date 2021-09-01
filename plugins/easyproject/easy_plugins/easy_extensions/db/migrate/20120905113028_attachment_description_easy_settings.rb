class AttachmentDescriptionEasySettings < ActiveRecord::Migration[4.2]
  def up
    EasySetting.create(
        :name  => 'attachment_description',
        :value => false
    )
    EasySetting.create(
        :name  => 'attachment_description_required',
        :value => false
    )
  end

  def down
    EasySetting.where(:name => ['attachment_description', 'attachment_description_required']).destroy_all
  end
end
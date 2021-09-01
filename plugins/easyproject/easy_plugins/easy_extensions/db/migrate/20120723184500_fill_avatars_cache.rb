class FillAvatarsCache < ActiveRecord::Migration[4.2]
  def up
    User.reset_column_information
    User.preload(:attachments).all.each do |user|
      att = user.attachments.first
      next unless att
      next unless File.exist?(att.diskfile)

      user.update_column(:easy_avatar, att.disk_filename)
    end
  end

  def down
  end
end

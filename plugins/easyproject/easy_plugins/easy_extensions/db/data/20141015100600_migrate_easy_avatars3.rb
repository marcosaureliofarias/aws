class MigrateEasyAvatars3 < EasyExtensions::EasyDataMigration

  require 'fileutils'

  def self.up
    old_path      = File.join(Rails.public_path, 'images', 'easy_avatars')
    new_path_base = File.join(Attachment.storage_path, 'easy_images')
    new_path      = File.join(new_path_base, 'easy_avatars')
    if File.exists? old_path
      FileUtils.rm_rf new_path
      FileUtils.mkdir_p(new_path_base)
      FileUtils.cp_r(old_path, new_path)
      FileUtils.rm_rf old_path
    end
  end

  def self.down
  end

end


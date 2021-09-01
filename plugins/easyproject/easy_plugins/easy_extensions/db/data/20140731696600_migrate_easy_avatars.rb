class MigrateEasyAvatars < EasyExtensions::EasyDataMigration

  require 'fileutils'

  def self.up
    old_avatars_path = File.join(Rails.public_path, 'images', 'easy_avatars')
    FileUtils.rm(Dir.glob("#{old_avatars_path}/*"), :force => true)
    Attachment.where(:container_type => 'Principal', :description => ['avatar', 'avatar_original']).find_each(:batch_size => 50) do |avatar|
      filename = File.join(Attachment.storage_path, avatar.disk_directory.to_s, avatar.disk_filename.to_s)
      if File.exists?(filename)
        image = File.new(filename)
        unless EasyAvatar.create(:entity_type => avatar.container_type, :entity_id => avatar.container_id, :image => image)
          say("Converting avatar #{avatar.container_type}, id: #{avatar.container_id} failed")
        end
        image.close
      end
      avatar.destroy
    end

    remove_column :users, :easy_avatar if column_exists? :users, :easy_avatar
    User.reset_column_information
  end

  def self.down
  end

end

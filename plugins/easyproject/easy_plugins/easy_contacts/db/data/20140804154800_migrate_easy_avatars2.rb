class MigrateEasyAvatars2 < EasyExtensions::EasyDataMigration

  require 'fileutils'

  def self.up
    Attachment.where(:container_type => 'EasyContact', :description => 'avatar').find_each(:batch_size => 50) do |avatar|
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

    remove_column :easy_contacts, :easy_avatar if column_exists? :easy_contacts, :easy_avatar
    EasyContact.reset_column_information
  end

  def self.down
    add_column :easy_contacts, :easy_avatar, :string
  end

end

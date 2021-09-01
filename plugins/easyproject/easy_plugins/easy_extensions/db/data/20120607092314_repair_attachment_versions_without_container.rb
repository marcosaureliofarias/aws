class RepairAttachmentVersionsWithoutContainer < EasyExtensions::EasyDataMigration
  def up
    AttachmentVersion.includes(:attachment).where(:container_id => nil).each do |version|
      next if version.attachment.nil?
      version.container = version.attachment.container
      version.save
    end
  end

  def down
  end
end

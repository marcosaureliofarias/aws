class AttachmentVersion < ActiveRecord::Base
  belongs_to :container, :polymorphic => true
  belongs_to :attachment, :class_name => "::Attachment", :foreign_key => 'attachment_id'
  belongs_to :author, :class_name => 'User'

  before_save :set_project_id_from_container
  after_rollback :delete_from_disk, :on => :create
  after_commit :delete_from_disk, :on => :destroy

  acts_as_user_readable

  delegate :project, :thumbnailable?, :visible?, :editable?, :deletable?, :image?, :is_text?, :is_diff?, :is_message?, :is_image?, :is_pdf?, :is_markdown?, :is_textile?, :is_video?, :is_audio?, :increment_download, :to => :attachment

  def non_versioned_columns
    ['downloads', 'category']
  end

  def diskfile
    File.join(Attachment.storage_path, self.disk_directory.to_s, self.disk_filename.to_s)
  end

  def self.latest
    order(:version).last
  end

  def previous
    @previous ||= AttachmentVersion.order(version: :desc).where("attachment_id = ? AND version < ?", attachment_id, version).first
  end

  def next
    @next ||= AttachmentVersion.order(version: :asc).where("attachment_id = ? AND version > ?", attachment_id, version).first
  end

  def thumbnail(options = {})
    if thumbnailable? && readable?
      size = options[:size].to_i
      if size > 0
        # Limit the number of thumbnails per image
        size = (size / 50) * 50
        # Maximum thumbnail size
        size = 800 if size > 800
      else
        size = Setting.thumbnails_size.to_i
      end
      size   = 100 unless size > 0
      target = File.join(Attachment.thumbnails_storage_path, "version_#{id}_#{digest}_#{size}.thumb")

      begin
        Redmine::Thumbnail.generate(self.diskfile, target, size, is_pdf?)
      rescue => e
        logger.error "An error occured while generating thumbnail for #{disk_filename} to #{target}\nException was: #{e.message}" if logger
        return nil
      end
    end
  end

  def readable?
    disk_filename.present? && File.readable?(diskfile)
  end

  def delete_from_disk
    if AttachmentVersion.where('disk_filename = ? AND id <> ?', self.disk_filename, self.id).empty?
      delete_from_disk!
    end

    if self.attachment
      if self.attachment.versions.empty?
        self.attachment.destroy
      elsif self.attachment.version == self.version
        self.attachment.revert_to!(self.previous || self.attachment.versions.latest)
      end
    end
  end

  def self.update_digests_to_sha256
    AttachmentVersion.where("length(digest) < 64").find_each do |attachment|
      attachment.update_digest_to_sha256!
    end
  end

  def update_digest_to_sha256!
    if readable?
      sha = Digest::SHA256.new
      File.open(diskfile, 'rb') do |f|
        while buffer = f.read(8192)
          sha.update(buffer)
        end
      end
      update_column :digest, sha.hexdigest
    end
  end

  private

  def set_project_id_from_container
    self.project_id = container.try(:project_id)
  end

  def delete_from_disk!
    if self.disk_filename.present? && File.exist?(self.diskfile)
      File.delete(self.diskfile)
    end
  end
end
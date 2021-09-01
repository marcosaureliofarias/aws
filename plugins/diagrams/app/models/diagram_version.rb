class DiagramVersion < ActiveRecord::Base
  FILE_EXTENSION   = 'png'.freeze
  TIMESTAMP_FORMAT = '%b %-d %Y, %H:%M'

  acts_as_attachable

  belongs_to :diagram

  scope :ordered, -> { order(position: :desc) }

  delegate :title,
           :identifier,
           :file_name,
           :project, to: :diagram, allow_nil: true

  def position_with_timestamp
    "#{position} - #{created_at.strftime(TIMESTAMP_FORMAT)}"
  end

  def attachment_exists?
    attachments.any? || xml_png.present?
  end

  def attachment
    @attachment ||= attachments.first
  end

  def attachments_visible?(user = User.current)
    true
  end

  def attachment_path
    "/attachments/download/#{attachment.id}/#{attachment.try(:filename)}"
  end

  def attachment=(image)
    tempfile = image.respond_to?(:path) ? image : create_tempfile(image)

    attachment = attachments.first || attachments.build(author: User.current)
    attachment.content_type = FILE_EXTENSION
    attachment.filename = file_name
    attachment.filesize = tempfile.size
    attachment.file = File.read(tempfile.path)
    attachment.files_to_final_location
    attachment.save
  end

  private

  def create_tempfile(image)
    image_data = decode_base_64(image)

    file = Tempfile.new([identifier, ".#{FILE_EXTENSION}"])
    file.binmode
    file.write(image_data)
    file
  end

  def decode_base_64(data)
    data = data.remove('data:image/png;base64,')
    data = data.sub(' ', '+')
    Base64.decode64(data)
  end

  class << self
    def to_list(diagram)
      diagram.diagram_versions.ordered.distinct
    end
  end
end

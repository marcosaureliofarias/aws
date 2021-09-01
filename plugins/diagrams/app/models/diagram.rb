class Diagram < ActiveRecord::Base
  FILE_EXTENSION = '.png'.freeze

  has_many :diagram_versions, dependent: :destroy

  belongs_to :project
  belongs_to :author, class_name: 'User', optional: true

  delegate :attachment_exists?, :attachment_path, :attachment, :xml_png,
           to: :current_version, allow_nil: true
  delegate :diskfile, to: :attachment, prefix: true, allow_nil: true

  def to_s
    title.capitalize +
      " #{l('diagram_version', version: current_position)}"
  end

  def root_xml
    return if xml.nil?

    Addressable::URI.encode("<mxGraphModel>#{Nokogiri::XML(xml).xpath('//root').to_xml}</mxGraphModel>")
  end

  def identifier
    [id, title_formatted].join('--')
  end

  def title_formatted
    title.to_s.downcase.gsub(' ', '-')
  end

  def attachment=(image)
    return if image.nil?

    current_version.attachment = image
  end

  def attachment_base64
    return xml_png if xml_png.presence.present? || !File.file?(attachment_diskfile.to_s)

    File.open(attachment_diskfile, 'rb') do |img|
      'data:image/png;base64,' + Base64.strict_encode64(img.read)
    end
  end

  def file_name
    identifier + FILE_EXTENSION
  end

  def create_version!
    next_position = diagram_versions.maximum(:position).to_i.next
    update_column(:current_position, next_position)

    diagram_versions.create(xml_png: self[:xml_png], position: next_position)
  end

  def editable?(user = nil)
    user ||= User.current
    user.allowed_to?(:manage_diagrams, nil, global: true)
  end

  private

  def xml
    return super if current_version.nil?

    current_version.try(:xml)
  end

  def current_version
    if current_position
      diagram_versions.find_by(position: current_position)
    else
      diagram_versions.first
    end
  end
end

class EasyPdfTheme < ActiveRecord::Base
  include Redmine::SafeAttributes

  acts_as_attachable :after_add => :attachment_added

  validates :name, :presence => true

  after_initialize :set_default_colors
  before_save :check_default

  safe_attributes 'name', 'header_hex_color', 'header_font_hex_color', 'is_default'

  class << self
    def default
      where(:is_default => true).first
    end

    def default_logo
      EasyExtensions::EasyProjectSettings.default_pdf_logo
    end

    def default_logo_image
      EasyExtensions::EasyProjectSettings.default_pdf_logo_image
    end
  end

  def set_default_colors
    if new_record?
      self.header_color      = [57, 171, 227]
      self.header_font_color = [255, 255, 255]
    end
  end

  def header_color
    color_reader(:header_color)
  end

  def header_color=(color)
    self.header_color_r, self.header_color_g, self.header_color_b = color
  end

  def header_hex_color
    color_reader_hex(:header_color)
  end

  def header_hex_color=(hex_color)
    self.header_color = parse_hex_color(hex_color)
  end

  def header_font_color
    color_reader(:header_font_color)
  end

  def header_font_color=(color)
    self.header_font_color_r, self.header_font_color_g, self.header_font_color_b = color
  end

  def header_font_hex_color
    color_reader_hex(:header_font_color)
  end

  def header_font_hex_color=(hex_color)
    self.header_font_color = parse_hex_color(hex_color)
  end

  def logo
    a = attachments.first
    a ? a.diskfile : (easy_system_flag? ? self.class.default_logo : nil)
  end

  def to_s
    name
  end

  def project
    nil
  end

  def attachments_visible?(user = User.current)
    true
  end

  def attachments_deletable?(user = User.current)
    true
  end

  private

  def attachment_added(obj)
    attachments.where("id != #{obj.id}").destroy_all unless obj.new_record?
  end

  def color_reader(color_prefix)
    [
        attributes["#{color_prefix}_r"],
        attributes["#{color_prefix}_g"],
        attributes["#{color_prefix}_b"]
    ]
  end

  def color_reader_hex(color_prefix)
    '#' + color_reader(color_prefix).collect { |x| "%02x" % x }.join
  end

  def parse_hex_color(hex_color)
    hex_color = hex_color.dup.downcase
    if hex_color =~ /#(\d|[a-f]){6}/
      return [
          hex_color[1..2].hex,
          hex_color[3..4].hex,
          hex_color[5..6].hex
      ]
    else
      return [0, 0, 0]
    end
  end

  def check_default
    if self.is_default? && self.is_default_changed?
      self.class.update_all(:is_default => false)
    end
  end
end

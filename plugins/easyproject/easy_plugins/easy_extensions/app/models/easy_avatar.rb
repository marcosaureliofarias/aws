class EasyAvatar < ActiveRecord::Base

  IMAGE_RESOLUTIONS = {
      original: '600x600',
      large:    '128x128',
      medium:   '64x64',
      small:    '32x32' }

  IMAGE_STYLES = {
      original: ["#{IMAGE_RESOLUTIONS[:original]}>", :jpg],
      large:    IMAGE_RESOLUTIONS[:large],
      medium:   IMAGE_RESOLUTIONS[:medium],
      small:    IMAGE_RESOLUTIONS[:small] }

  CONVERT_OPTIONS = "-strip -gravity center -extent %s"

  belongs_to :entity, :polymorphic => true, :touch => true

  validates :image, :entity_id, :entity_type, :presence => true
  validates :entity_id, :uniqueness => { :scope => :entity_type }

  attr_accessor :crop_x, :crop_y, :crop_width, :crop_height

  has_attached_file :image, { :styles          => IMAGE_STYLES,
                              :convert_options => {
                                  large:  CONVERT_OPTIONS % IMAGE_RESOLUTIONS[:large],
                                  medium: CONVERT_OPTIONS % IMAGE_RESOLUTIONS[:medium],
                                  small:  CONVERT_OPTIONS % IMAGE_RESOLUTIONS[:small] },
                              :processors      => [:cropper],
                              url:             :easy_image_url,
                              path:            :easy_image_path
  }

  validates_attachment :image, :content_type => { :content_type => /image/ },
                       :size                 => { :in => 0..Setting.attachment_max_size.to_i.kilobytes }

  def cropping?
    !crop_x.blank? && !crop_y.blank? && !crop_width.blank? && !crop_height.blank?
  end

  def disable_cropping
    self.crop_x, self.crop_y, self.crop_width, self.crop_height = nil
  end

  def image_geometry(style = :original)
    @geometry        ||= {}
    @geometry[style] ||= Paperclip::Geometry.from_file(image.path(style))
  end

  def reprocess_original
    image.reprocess! :original
  end

  def reprocess_thumbnails
    image.reprocess! :large, :medium, :small
  end

  private

  def easy_image_url
    EasyExtensions::EasyAssets.easy_images_options(self.class, '/:id/:style/:basename.jpg')[:url]
  end


  def easy_image_path
    EasyExtensions::EasyAssets.easy_images_options(self.class, '/:id/:style/:basename.jpg')[:path]
  end

end

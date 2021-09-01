module EasyExtensions
  module ImageProcessing
    class MissingAdapterException < StandardError;
    end
    class AdapterProcessException < StandardError;
    end

    def self.avaliable_ip_adapters
      return @available_adapters if @available_adapters
      @available_adapters = []
      @available_adapters << :rmagick_adapter if Object.const_defined?(:Magick)
      @available_adapters << :imagemagick_adapter if ::Paperclip.with_imagemagick?
      @available_adapters
    end

    def self.ip_adapter
      return @ip_adapter if @ip_adapter
      raise MissingAdapterException, 'No suitable adapter avaliable' if self.avaliable_ip_adapters.empty?
      self.ip_adapter = self.avaliable_ip_adapters.first
      @ip_adapter
    end

    def self.ip_adapter=(adapter_name)
      @ip_adapter = EasyExtensions::ImageProcessing::Adapters.const_get(adapter_name.to_s.split('_').map(&:capitalize).join)
    end

    def self.resize_image(src, width, height, options = {})
      self.ip_adapter.resize_image(src, width, height, options)
    end

    def self.resize_image_to_fit(src, width, height, options = {})
      self.ip_adapter.resize_image_to_fit(src, width, height, options)
    end

    def self.crop_image(src, c = {}, options = {})
      self.ip_adapter.crop_image(src, c, options)
    end

    def self.get_geometry(src)
      self.ip_adapter.get_geometry(src)
    end

    def self.pdf_image_to_png(file, path)
      self.ip_adapter.pdf_image_to_png(file, path)
    end

    def self.base64_to_img(file, path)
      self.ip_adapter.base64_to_img(file, path)
    end

  end
end
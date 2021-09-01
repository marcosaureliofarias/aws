module EasyExtensions
  module EasyInlineFragmentStripper

    extend ActiveSupport::Concern

    included do
      def self.strip_inline_images(*args)
        cattr_accessor :inline_fragmet_stripper_options, :inline_fragmet_stripper_attributes
        attr_reader :stripped_images
        options                                 = args.extract_options! || {}
        options[:autosave]                      ||= Proc.new { false }
        self.inline_fragmet_stripper_options    = options
        self.inline_fragmet_stripper_attributes = Array(args.shift)

        before_save :strip_inline_image, if: options[:if]
        after_save :save_stripped_images, if: options[:autosave]
        after_commit :close_temp_files
        after_rollback :close_temp_files

      end
    end

    def strip_inline_image_for(attribute)
      @tmp_files       ||= Array.new
      @stripped_images ||= Array.new
      content          = self.send(attribute).to_s
      return content unless strip_inline_images?(content)
      regexp         = /data:image\/([a-zA-Z]*);base64,([^\"]*)/
      parsed_content = Nokogiri::HTML.parse(content)
      n              = 1
      parsed_content.search('img').each do |img|
        src = img.attributes['src']
        next unless src && src.value.include?('base64') && src.value.match(regexp)
        ext, data   = $1, $2
        filename    = "Image#{Time.now.strftime('%Y%m%d%H%M%S')}_#{n}.#{ext}"
        replacement = Nokogiri::XML::Text.new("\nattachment:\"#{filename}\"\n", img.parent)
        img.replace(replacement)
        generate_image(n, ext, filename, data)
        n += 1
      end
      parsed_content.at('body').inner_html
    end

    def strip_inline_image_for!(attribute)
      self.update_column(attribute, strip_inline_image_for(attribute))
      @stripped_images.compact.map(&:save)
      @stripped_images.clear
    end

    private

    def generate_image(n, ext, filename, data)
      t = Tempfile.new(["Image#{n}", ".#{ext}"])
      begin
        t.binmode
        t.write(Base64.decode64(data)) && t.rewind

        @tmp_files << t
        @stripped_images << attach_stripped_image(filename, t, ext)
      end
    end

    def strip_inline_images?(content)
      /data:image\/(.+);base64/.match?(content)
    end

    def save_stripped_images
      @stripped_images.compact.map(&:save) if @stripped_images
    end

    def attach_stripped_image(filename, file, extension)
      self.attachments.build(
          :file         => file,
          :filename     => filename,
          :author       => User.current,
          :description  => !!EasySetting.value('attachment_description_required') && '*' || '',
          :content_type => "image/#{extension}") if self.respond_to?(:attachments) && self.attachments.respond_to?(:build)
    end

    def strip_inline_image
      stripped_attrs = self.class.inline_fragmet_stripper_attributes.inject({}) do |mem, var|
        mem[var] = strip_inline_image_for(var)
        mem
      end
      # update_columns(stripped_attrs)
      self.attributes = stripped_attrs
    end

    def close_temp_files
      @tmp_files.each do |tmp|
        tmp.close if tmp && !tmp.closed?
      end if @tmp_files
    end
  end
end

require 'base64'

module EasyExtensions
  # Handle Avatar for given entity
  #   usually used for user - return image with avatar url (gravatar, easy avatar) or base64 or just LetterAvatar
  class Avatar

    attr_reader :entity
    attr_accessor :options

    # @param [ActiveRecord::Base] entity usually User
    # @param [Hash] options
    # @option options [Symbol] :style (small) @see EasyAvatar::IMAGE_RESOLUTIONS
    # @option options [String] :size (32x32) @see EasyAvatar::IMAGE_RESOLUTIONS
    # @option options [Boolean] :base64 (false) render image_tag with base64 source (for e-mails)
    def initialize(entity, view_context, **options)
      @entity = entity
      @view_context = view_context
      @options = options
      if @options[:style]
        @options[:size] = EasyAvatar::IMAGE_RESOLUTIONS.find { |(style, _size)| style == @options[:style].to_sym }[1] # => 32x32
      elsif @options[:size]
        @options[:style] = EasyAvatar::IMAGE_RESOLUTIONS.min_by { |(_style, size)| (size.to_i - @options[:size].to_i).abs }[0].to_sym
      else
        # Default dimensions
        @options.merge!(style: :small, size: EasyAvatar::IMAGE_RESOLUTIONS[:small])
      end
      @options[:size] = @options[:size].to_i.abs.to_s
      @options.delete(:size) if @options[:style].to_sym == :original
    end

    def enabled?
      EasySetting.value('avatar_enabled')
    end

    # @return [String] path / URI to image
    def image_path
      return nil unless enabled?
      return @image_path if defined? @image_path

      image_path = if entity.is_a?(User) && !entity.visible?
                     # For anonymize avatar use Letter
                     letter_avatar
                   elsif Setting.gravatar_enabled? && entity.is_a?(Principal)
                     # Gravatar part
                     gravatar_url || letter_avatar
                   elsif entity.respond_to?(:easy_avatar) && (@av = entity.easy_avatar).present?
                     # Easy Avatar, with Letter fallback if avatar not exist
                     easy_avatar_path = @av.image.url(options[:style], escape: true)
                     easy_avatar_path = letter_avatar unless @av.image.exists?
                     easy_avatar_path
                   elsif entity.respond_to?(:easy_avatar_url) && entity.easy_avatar_url.present?
                     # SSO avatar?
                     entity.easy_avatar_url
                   else
                     # Ensure with Letter
                     letter_avatar
                   end
      # Actually - this never happen
      image_path ||= default_avatar_image
      @image_path = if options[:base64]
                      mime_type = File.extname(image_path)[/([a-z]+)/i]
                      "data:image/#{mime_type || "png"};base64,#{generate_base64(image_path)}"
                    else
                      image_path
                    end
    end

    alias :path :image_path

    # @return [String] URI to gravatar.com (by default)
    def gravatar_url
      email = nil
      options[:default] = Setting.gravatar_default
      if entity.respond_to?(:mail)
        email = entity.mail
        options[:title] = entity.name unless options[:title]
      elsif entity.to_s =~ %r{<(.+?)>}
        email = $1
      end
      if email.present?
        @view_context.gravatar_url(email, options) rescue nil
      else
        nil
      end
    end

    # @return [String] in case of base64 return local-path, in rest of case HTTP URI
    def letter_avatar
      if options[:base64]
        Rails.root.join(entity.letter_avatar_path(options[:size].to_i || 64)).to_s
      else
        @view_context.letter_avatar_url_for(entity, options[:size].to_i)
      end
    end

    # @return [String] HTML <img> tag
    def to_html
      return "" unless enabled?

      @view_context.image_tag image_path, image_tag_options
    end

    # @return [String] image bin from server
    def image
      return "" unless image_path

      if image_path.start_with? "http" # Gravatar
        URI.open(image_path) { |io| io.read }
      elsif image_path.start_with? "/" # Easy Avatar
        if @av
          File.binread @av.image.path(options[:style])
        else
          File.binread File.join(Rails.public_path, URI(image_path).path)
        end
      else # Letter avatar
        File.binread Rails.root.join(image_path)
      end
    end

    # Just name of avatar, possibility with extension.
    # @example "dark-avatar.bmp"
    # @return [String]
    def name
      return "" unless image_path

      @name ||= if image_path.start_with? "http"
                  path = URI(image_path).path
                  name = [File.basename(URI(image_path).path)]
                  name << ".jpg" if File.extname(path).empty?
                  name.join
                elsif image_path.start_with? "/"
                  if @av
                    @av.image_file_name
                  else
                    File.basename URI(image_path).path
                  end
                else
                  File.basename image_path
                end
    end

    # @return [Hash{Symbol->String}] img tag options
    def image_tag_options
      {
        width: options[:size],
        height: options[:size],
        alt: entity.to_s,
        class: "gravatar #{options[:style]}",
      }
    end

    private

    # Easy default avatar
    def default_avatar_image
      "/plugin_assets/easy_extensions/images/avatar.jpg"
    end

    def generate_base64(path)
      src = if path.start_with? "http" # Gravatar
              URI.open(path) { |io| io.read }
            elsif path.start_with? "/" # Easy Avatar.path
              if @av
                File.binread @av.image.path(options[:style])
              else
                image_path = URI(path).path # Clean path, letter_avatar could add timestamp there
                if File.exist?(image_path)
                  # If image_path is absolute filesystem path
                  File.read(image_path)
                else
                  File.read(File.join(Rails.public_path, image_path))
                end
              end
            else # Letter avatar
              File.read(Rails.root.join(path))
            end
      ::Base64.encode64 src
    end
  end
end

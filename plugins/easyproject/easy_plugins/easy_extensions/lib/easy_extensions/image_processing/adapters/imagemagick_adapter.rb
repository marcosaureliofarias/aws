module EasyExtensions
  module ImageProcessing
    module Adapters
      module ImagemagickAdapter
        class << self
          def resize_image(src, width, height, options = {})
            File.open(src) do |f|
              t          = ::Paperclip::Thumbnail.new(f)
              format     = "#{options[:format]}:" if options[:format]
              geometry   = options[:geometry] || Paperclip::Geometry.new(width, height, '>')
              parameters = ["\"#{File.expand_path(src)}\""]
              parameters << "-crop #{options[:crop][:width].to_i}x#{options[:crop][:height].to_i}+#{options[:crop][:x].to_i}+#{options[:crop][:y].to_i}" if options[:crop]
              parameters += ["-resize \"#{geometry}\"", '-auto-orient', '-strip', '-gravity', 'center', "-extent \"#{geometry}\""]
              parameters << "#{format}\"#{File.expand_path(options[:dst] || src)}\""
              t.convert(parameters.join(' ').strip)
            end
          rescue Terrapin::ExitStatusError, Terrapin::CommandNotFoundError => e
            raise EasyExtensions::ImageProcessing::AdapterProcessException.new, e.message
          end

          def resize_image_to_fit(src, width, height, options = {})
            File.open(src) do |f|
              t          = ::Paperclip::Thumbnail.new(f)
              format     = "#{options[:format]}:" if options[:format]
              geometry   = options[:geometry] || Paperclip::Geometry.new(width, height)
              parameters = ["\"#{File.expand_path(src)}\"", '-auto-orient', '-strip', "-resize \"#{geometry}\""]
              parameters << "-crop #{options[:crop][:width].to_i}x#{options[:crop][:height].to_i}+#{options[:crop][:x].to_i}+#{options[:crop][:y].to_i}" if options[:crop]
              parameters << "#{format}\"#{File.expand_path(options[:dst] || src)}\""
              t.convert(parameters.join(' ').strip)
            end
          rescue Terrapin::ExitStatusError, Terrapin::CommandNotFoundError => e
            raise EasyExtensions::ImageProcessing::AdapterProcessException.new, e.message
          end

          def crop_image(src, crop = {}, options = {})
            File.open(src) do |f|
              t          = ::Paperclip::Thumbnail.new(f)
              format     = "#{options[:format]}:" if options[:format]
              parameters = ["\"#{File.expand_path(src)}\"", '-strip', '-auto-orient']
              parameters << "-crop #{crop[:width].to_i}x#{crop[:height].to_i}+#{crop[:x].to_i}+#{crop[:y].to_i}"
              parameters << "#{format}\"#{File.expand_path(options[:dst] || src)}\""
              t.convert(parameters.join(' ').strip)
            end
          rescue Terrapin::ExitStatusError, Terrapin::CommandNotFoundError => e
            raise EasyExtensions::ImageProcessing::AdapterProcessException.new, e.message
          end

          def get_geometry(src)
            geometry = ::Paperclip::GeometryDetector.new(src).make
            geometry || raise(EasyExtensions::ImageProcessing::AdapterProcessException.new)
          rescue ::Paperclip::Errors::NotIdentifiedByImageMagickError
            raise(EasyExtensions::ImageProcessing::AdapterProcessException.new)
          end

          def pdf_image_to_png(src, tmp_path)
            tmp = Tempfile.new(['', '_' + File::basename(src) + '.png'], tmp_path)
            tmp.binmode
            File.open(src) do |f|
              t          = ::Paperclip::Thumbnail.new(f)
              geometry   = Paperclip::Geometry.new(200, 40)
              parameters = ["\"#{File.expand_path(src)}\"", '-strip', '-alpha', 'Background', '-auto-orient', "-resize \"#{geometry}\""]
              parameters << "png:\"#{File.expand_path(tmp.path)}\""
              t.convert(parameters.join(' ').strip)
            end
            tmp
          rescue Terrapin::ExitStatusError, Terrapin::CommandNotFoundError => e
            raise EasyExtensions::ImageProcessing::AdapterProcessException.new, e.message
          ensure
            tmp.close if tmp
          end

          def base64_to_img(coded_image, tmp_path)
            begin
              tmp = Tempfile.new(['base64_image', '.png'], tmp_path)
              tmp.binmode
              if coded_image[0..9] == 'data:image'
                tmp.write Base64.decode64(coded_image)
              else
                tmp.write open(coded_image).read
              end
              geometry = Paperclip::Geometry.from_file(tmp)
            rescue
              return nil
            ensure
              tmp.close if tmp
            end
            return [tmp.path, geometry.height.to_i]
          end

        end
      end
    end
  end
end

module EasyExtensions
  module ImageProcessing
    module Adapters
      module RmagickAdapter
        class << self
          def resize_image(src, width, height, options = {})
            original_image = Magick::Image.read(src).first
            original_image.change_geometry(options[:geometry] || "#{width}x#{height}") { |cols, rows, img|
              img.crop!(options[:crop][:x], options[:crop][:y], options[:crop][:width], options[:crop][:height], true) if options[:crop]
              img.resize!(cols, rows)
              white_bg  = Magick::Image.new(width, height)
              new_image = white_bg.composite(img, Magick::CenterGravity, Magick::OverCompositeOp)
              begin
                new_image.format = options[:format] || 'JPG'
              rescue ArgumentError
                new_image.format = 'JPG'
              end
              new_image.write(options[:dst] || src)
            }
          rescue Magick::ImageMagickError => e
            raise EasyExtensions::ImageProcessing::AdapterProcessException.new, e.message
          end

          def resize_image_to_fit(src, width, height, options = {})
            original_image = Magick::Image.read(src).first
            original_image.change_geometry(options[:geometry] || "#{width}x#{height}>") { |cols, rows, img|
              img.crop!(options[:crop][:x], options[:crop][:y], options[:crop][:width], options[:crop][:height], true) if options[:crop]
              img.resize_to_fit!(cols, rows)
              begin
                original_image.format = options[:format] || 'JPG'
              rescue ArgumentError
                original_image.format = 'JPG'
              end
              original_image.strip!
              original_image.write(options[:dst] || src)
            }
          rescue Magick::ImageMagickError => e
            raise EasyExtensions::ImageProcessing::AdapterProcessException.new, e.message
          end

          def crop_image(src, crop = {}, options = {})
            img = Magick::Image.read(src).first
            img = img.crop(crop[:x], crop[:y], crop[:width], crop[:height], true)
            begin
              img.format = options[:format] || 'JPG'
            rescue ArgumentError
              img.format = 'JPG'
            end
            img.strip!
            img.write(options[:dst] || src)
          rescue Magick::ImageMagickError => e
            raise EasyExtensions::ImageProcessing::AdapterProcessException.new, e.message
          end

          def get_geometry(src)
            image = Magick::Image.read(src).first
            ::Paperclip::Geometry.new(image.columns, image.rows)
          rescue Magick::ImageMagickError => e
            raise EasyExtensions::ImageProcessing::AdapterProcessException.new, e.message
          end

          def pdf_image_to_png(src, tmp_path)
            img = Magick::ImageList.new(src)
            tmp = Tempfile.new(['', '_' + File::basename(src) + '.png'], tmp_path);
            tmp.binmode
            img.change_geometry('200x40>') { |cols, rows, i|
              i.resize_to_fit!(cols, rows)
              img.format = 'PNG'
              img.alpha(Magick::BackgroundAlphaChannel)
              img.strip!
              tmp.print img.to_blob
            }
            tmp
          rescue Magick::ImageMagickError => e
            raise EasyExtensions::ImageProcessing::AdapterProcessException.new, e.message
          ensure
            tmp.close if tmp
          end

          def base64_to_img(coded_image, tmp_path = nil)
            out    = []
            images = []
            begin
              if coded_image[0..9] == 'data:image'
                images = Magick::Image.read_inline(coded_image)
              else
                images = Magick::ImageList.new(coded_image)
              end
            rescue
              return nil
            end
            images.each do |img|
              tmp = Tempfile.new(['base64_image', '.png'], tmp_path)
              begin
                tmp.binmode
                img.format = 'PNG'
                img.alpha(Magick::BackgroundAlphaChannel)
                img.strip!
                tmp.print img.to_blob
                out << [tmp, img.rows]
              rescue
                return nil
              ensure
                tmp.close if tmp
              end

            end
            out
          end
        end
      end
    end
  end
end

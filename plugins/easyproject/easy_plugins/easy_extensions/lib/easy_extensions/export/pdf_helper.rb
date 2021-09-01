module EasyExtensions
  module Export
    module PDFHelper

      private

      def theme_class
        EasyPdfTheme
      end

      def theme
        # @theme ||= theme_class.find_by_id(@options[:theme_id]) if @options[:theme_id]
        @theme ||= _theme
      end

      def _theme
        first = theme_class.first
        if first
          theme_class.first
        else
          nil
        end
      end

      def render_logo
        if theme && theme.logo
          path = theme.logo
        else
          path = theme_class.default_logo
        end

        begin
          img = @pdf.easyImageToPNG(path).path

          if img
            @pdf.SetY(15)
            @pdf.Image(img, LOGO_X, LOGO_Y, LOGO_WIDTH, LOGO_HEIGHT)
          end
        rescue
        end
      end

    end
  end
end

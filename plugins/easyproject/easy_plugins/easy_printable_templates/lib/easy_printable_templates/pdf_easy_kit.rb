module EasyPrintableTemplates
  class PDFEasyKit < PDFKit

    cattr_accessor :debug

    def initialize(html, options = {})
      html = Nokogiri::HTML.parse(html)
      html.css("head link, head script").remove
      html.css("body img").each{|img| img[:src] = img[:src].to_s.gsub(/\?\d+/, '')}

      save_with = Nokogiri::XML::Node::SaveOptions::DEFAULT_HTML -
                  Nokogiri::XML::Node::SaveOptions::FORMAT

      super(html.to_html(save_with: save_with), options)
    end

    def to_pdf(path=nil)
      append_stylesheets
      remove_fonts

      root = PDFKit.configuration.root_url || "#{Setting.protocol}://#{Setting.host_name}"
      root += '/' unless root.ends_with?('/')

      # @source = PDFKit::Source.new(@source.to_s.gsub(/(href|src|url)(=|\()(['"])(\/|\.\.?\/)([^\/]([^\"']*|[^"']*))['"]/, '\1\2\3' + root + '\5\3'))if @source.html?
      @source = PDFKit::Source.new(@source.to_s.gsub(/(href|src)=(['"])\/([^\/]([^\"']*|[^"']*))['"]/, '\1=\2' + root + '\3\2')) if @source.html?

      invoke = command(path)

      File.open("tmp/pdf_easy_kit_source.html", 'w') do |f|
        f.write @source
      end if self.class.debug

      result = IO.popen(invoke, "wb+") do |pdf|
        pdf.puts(@source.to_s) if @source.html?
        pdf.close_write
        pdf.gets(nil)
      end
      result = File.read(path) if path

      # | ExitCode  | Explanation                                                    |
      # ============+=================================================================
      # | 0         | All OK                                                         |
      # | 1         | PDF generated OK, but some request(s) did not return HTTP 200  |
      # | 2         | Could not something something                                  |
      # | X         | Could not write PDF: File in use                               |
      # | Y         | Could not write PDF: No write permission                       |
      # | Z         | PDF generated OK, but some JavaScript requests(s) timeouted    |
      # | A         | Invalid arguments provided                                     |
      # | B         | Could not find input file(s)                                   |
      # | C         | Process timeouted                                              |
      # ==============================================================================
      # https://github.com/KnpLabs/snappy/pull/84

      exitstatus = $?.exitstatus
      if exitstatus == 1
        Rails.logger.warn("PDFKit not find some assets")
      else
        # $? is thread safe per http://stackoverflow.com/questions/2164887/thread-safe-external-process-in-ruby-plus-checking-exitstatus
        raise "command failed (exitstatus=#{exitstatus}): #{invoke}" if result.to_s.strip.empty? or !successful?($?)
      end

      return result
    end

    protected

    def append_stylesheets
      raise ImproperSourceError.new('Stylesheets may only be added to an HTML source') if stylesheets.any? && !@source.html?

      stylesheets.each do |stylesheet|
        dir = File.dirname(stylesheet)
        style_tag = style_tag_for(stylesheet).to_str
        style_tag = style_tag.gsub(/url\(([^)(]+)\);?/){|i| "url('#{File.absolute_path(File.join(dir, $1.gsub(/["']/, '')))}');"}
        if /<\/head>/.match?(@source.to_s)
          @source = Source.new(@source.to_s.gsub(/(<\/head>)/) { |s|
            style_tag + (s.respond_to?(:html_safe) ? s.html_safe : s)
          })
        else
          @source.to_s.insert(0, style_tag)
        end
      end
    end

    def remove_fonts
      @source = Source.new(@source.to_s.gsub(/(@font-face\s*\{[^}]+\})/, ''))
    end

  end
end

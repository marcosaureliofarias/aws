class WarningSuppressor
  IGNORES = [
    /QFont::setPixelSize: Pixel size <= 0/,
    /CoreText performance note:/,
    /Heya! This page is using wysihtml5/,
    /You must provide a success callback to the Chooser to see the files that the user selects/
  ]

  class << self
    def write(message)
      if suppress?(message)
        0
      else
        puts(message)
        1
      end
    end

    private

      def suppress?(message)
        IGNORES.any? { |re| message =~ re }
      end
  end
end

Capybara.register_driver :chrome do |app|
  chrome_options = Selenium::WebDriver::Chrome::Options.new(args: CHROME_OPTIONS)
  Capybara::Selenium::Driver.new(app, browser: :chrome, options: chrome_options)
end

Capybara.register_driver :chrome_headless do |app|
  args = CHROME_OPTIONS
  args << 'headless'
  args << 'disable-gpu'
  args << 'no-sandbox'
  args << "window-size=#{RESOLUTION.join(',')}"

  chrome_options = Selenium::WebDriver::Chrome::Options.new(args: args)
  Capybara::Selenium::Driver.new(app, browser: :chrome, options: chrome_options)
end

Capybara.javascript_driver = JS_DRIVER

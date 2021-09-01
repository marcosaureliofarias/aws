class EasyPdfPrinter < ApplicationController
  include EasyPrintableTemplates::ApplicationControllerPatch
  helper :custom_fields, :easy_printable_template_pages

  def initialize(easy_printable_template)
    super()
    @easy_printable_template = easy_printable_template
    self.action_name = "attach_pdf"
    self.request =  ActionDispatch::Request.new('rack.input' => [], 'REQUEST_METHOD' => 'GET', 'HTTP_HOST' => Setting.host_name, 'rack.url_scheme' => Setting.protocol)
    self.response = ActionDispatch::Response.new
  end

end
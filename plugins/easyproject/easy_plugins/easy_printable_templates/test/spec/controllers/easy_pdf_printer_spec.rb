require 'easy_extensions/spec_helper'

describe EasyPdfPrinter do

  render_views

  let(:issue) { FactoryBot.create(:issue) }
  let(:easy_printable_template) { FactoryBot.create(:easy_printable_template, :with_easy_printable_template_pages) }

  subject { described_class.new(easy_printable_template) }

  it "#create_pdf_attachment" do
    skip("No wkhtmltopdf executable") unless File.exist?(PDFKit.configuration.wkhtmltopdf)

    expect { subject.create_pdf_attachment(issue) }.to change(issue.attachments, :count).by 1
  end
end

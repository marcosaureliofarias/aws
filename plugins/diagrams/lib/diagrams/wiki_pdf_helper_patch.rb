module Diagrams
  module WikiPdfHelperPatch
    def self.included(base)
      base.send(:include, InstanceMethods)

      base.class_eval do
        unloadable

        alias_method :write_wiki_page_without_diagrams, :write_wiki_page
        alias_method :write_wiki_page, :write_wiki_page_with_diagrams
      end
    end
  end

  module InstanceMethods
    def write_wiki_page_with_diagrams(pdf, page)
      text = textilizable(page.content, :text,
        :only_path => false,
        :edit_section_links => false,
        :headings => false,
        :inline_attachments => false
      )
      text.gsub!('/images/', '')
      pdf.RDMwriteFormattedCell(190,5,'','', text, page.attachments, 0)
      if page.attachments.any?
        pdf.ln(5)
        pdf.SetFontStyle('B',9)
        pdf.RDMCell(190,5, l(:label_attachment_plural), "B")
        pdf.ln
        for attachment in page.attachments
          pdf.SetFontStyle('',8)
          pdf.RDMCell(80,5, attachment.filename)
          pdf.RDMCell(20,5, number_to_human_size(attachment.filesize),0,0,"R")
          pdf.RDMCell(25,5, format_date(attachment.created_on),0,0,"R")
          pdf.RDMCell(65,5, attachment.author.name,0,0,"R")
          pdf.ln
        end
      end
    end
  end
end

unless Redmine::Export::PDF::WikiPdfHelper.include? Diagrams::WikiPdfHelperPatch
  Redmine::Export::PDF::WikiPdfHelper.send(:include, Diagrams::WikiPdfHelperPatch)
end
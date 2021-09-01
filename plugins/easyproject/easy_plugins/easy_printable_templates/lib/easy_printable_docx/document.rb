require 'easy_printable_docx/containers'
require 'easy_printable_docx/elements'
require 'nokogiri'
require 'zip'

module EasyPrintableDocx
  # The Document class wraps around a docx file and provides methods to
  # interface with it.
  #
  #   # get a EasyPrintableDocx::Document for a docx file in the local directory
  #   doc = EasyPrintableDocx::Document.open("test.docx")
  #
  #   # get the text from the document
  #   puts doc.text
  #
  #   # do the same thing in a block
  #   Docx::Document.open("test.docx") do |d|
  #     puts d.text
  #   end
  class Document
    attr_reader :xml, :doc, :zip, :styles, :headers, :footers

    def initialize(path, &block)
      @replace = {}
      @zip = Zip::File.open(path)
      @document_xml = @zip.read('word/document.xml')
      @doc = Nokogiri::XML(@document_xml)
      @styles_xml = @zip.read('word/styles.xml')
      @styles = Nokogiri::XML(@styles_xml)

      @headers = []
      @footers = []
      @zip.glob('word/header*.xml').each { |e| @headers << Nokogiri::XML(@zip.read(e.name)) }
      @zip.glob('word/footer*.xml').each { |e| @footers << Nokogiri::XML(@zip.read(e.name)) }

      if block_given?
        yield self
        @zip.close
      end
    end


    # This stores the current global document properties, for now
    def document_properties
      {
        font_size: font_size
      }
    end


    # With no associated block, Docx::Document.open is a synonym for Docx::Document.new. If the optional code block is given, it will be passed the opened +docx+ file as an argument and the Docx::Document oject will automatically be closed when the block terminates. The values of the block will be returned from Docx::Document.open.
    # call-seq:
    #   open(filepath) => file
    #   open(filepath) {|file| block } => obj
    def self.open(path, &block)
      self.new(path, &block)
    end

    def paragraphs
      @doc.xpath('//w:document//w:body//w:p').map { |p_node| parse_paragraph_from p_node }
    end

    def all_headers
      @headers.map { |h| h.xpath('//w:hdr//w:p').map { |p_node| parse_paragraph_from p_node } }.flatten
    end

    def all_footers
      @footers.map { |f| f.xpath('//w:ftr//w:p').map { |p_node| parse_paragraph_from p_node } }.flatten
    end

    def bookmarks
      bkmrks_hsh = Hash.new
      bkmrks_ary = @doc.xpath('//w:bookmarkStart').map { |b_node| parse_bookmark_from b_node }
      # auto-generated by office 2010
      bkmrks_ary.reject! {|b| b.name == "_GoBack" }
      bkmrks_ary.each {|b| bkmrks_hsh[b.name] = b }
      bkmrks_hsh
    end

    def tables
      @doc.xpath('//w:document//w:body//w:tbl').map { |t_node| parse_table_from t_node }
    end

    # Some documents have this set, others don't.
    # Values are returned as half-points, so to get points, that's why it's divided by 2.
    def font_size
      size_tag = @styles.xpath('//w:docDefaults//w:rPrDefault//w:rPr//w:sz').first
      size_tag ? size_tag.attributes['val'].value.to_i / 2 : nil
    end

    ##
    # *Deprecated*
    #
    # Iterates over paragraphs within document
    # call-seq:
    #   each_paragraph => Enumerator
    def each_paragraph
      paragraphs.each { |p| yield(p) }
    end

    # call-seq:
    #   to_s -> string
    def to_s
      paragraphs.map(&:to_s).join("\n")
    end

    # Output entire document as a String HTML fragment
    def to_html
      paragraphs.map(&:to_html).join('\n')
    end

    # Save document to provided path
    # call-seq:
    #   save(filepath) => void
    def save(path)
      update
      Zip::OutputStream.open(path) do |out|
        zip.each do |entry|
          out.put_next_entry(entry.name)

          if @replace[entry.name]
            out.write(@replace[entry.name])
          else
            out.write(zip.read(entry.name))
          end
        end
      end
      zip.close
    end

    alias_method :text, :to_s

    def replace_entry(entry_path, file_contents)
      @replace[entry_path] = file_contents
    end

    def generate(template, project, view_context)
      @view_context = view_context
      replace_docx_tokens(project)

      new_file_name = "#{project.name}.docx"
      attachment = template.dup
      attachment.container = project
      attachment.filename = new_file_name
      attachment.project_id = project.id
      attachment.disk_filename = Attachment.disk_filename(new_file_name, template.disk_directory)
      attachment.save

      save(attachment.diskfile)

      attachment
    end

    private

    def replace_docx_tokens(entity)
      %w[all_headers paragraphs all_footers].each do |part|
        self.send(part).each do |paragraph|
          parse_paragraph(paragraph, entity)
        end
      end
    end

    def parse_paragraph(paragraph, entity)
      prepare_table(paragraph, entity) if paragraph.text.to_s.start_with? 'Source query:'
      return if paragraph.has_insert_text?

      if paragraph.text_runs.size > 1
        paragraph.text_runs[0].text = @view_context.replace_easy_printable_template_page_text(paragraph.text.to_s, entity)

        paragraph.text_runs.drop(1).map { |t| t.text = '' }
      else
        paragraph.text_runs.each do |text_run|
          text_run.text = @view_context.replace_easy_printable_template_page_text(text_run.to_s, entity)
        end
      end
    end

    def prepare_table(paragraph, entity)
      table = paragraph.parent_table
      if table
        query_id = paragraph.text.to_s.match(/%\s*query_(\d+)\s*%/)[1]
        if query_id.presence
          # remove first row with 'Source query:'
          table.rows.first.remove!
          replace_table_tokens_by_data(table, entity, query_id)
        end
      end
    end

    def replace_table_tokens_by_data(table, project, query_id)
      query = EasyQuery.find_by(id: query_id)
      return if query.nil?

      if table.rows.size > 1
        query.project = project
        entities = query.entities(limit: Setting.issues_export_limit.to_i, include_entities: true)
        fill_table_by_tokens(table, entities)
      end
    end

    def fill_table_by_tokens(table, entities)
      # use last row as default with tokens
      row = table.rows.last.copy
      table.rows.last.remove!

      entities.each do |entity|
        add_row = row.copy
        add_row.cells.each do |cell|
          replace_entity_tokens(cell, entity)
        end
        add_row.insert_after(table.rows.last)
      end
    end

    def replace_entity_tokens(cell, entity)
      cell.paragraphs.each do |p|
        if p.text_runs.size > 1
          p.text_runs[0].text = @view_context.replace_easy_printable_template_page_text(p.text.to_s, entity)

          p.text_runs.drop(1).map { |t| t.text = '' }
        else
          p.text_runs.each do |t|
            t.text = @view_context.replace_easy_printable_template_page_text(t.to_s, entity)
          end
        end
      end
    end

    #--
    # TODO: Flesh this out to be compatible with other files
    # TODO: Method to set flag on files that have been edited, probably by inserting something at the
    # end of methods that make edits?
    #++
    def update
      replace_entry "word/document.xml", doc.serialize(save_with: 0)
      headers.each_with_index do |header, i|
        replace_entry "word/header#{i + 1}.xml", header.serialize(save_with: 0)
      end
      footers.each_with_index do |footer, i|
        replace_entry "word/footer#{i + 1}.xml", footer.serialize(save_with: 0)
      end
    end

    # generate Elements::Containers::Paragraph from paragraph XML node
    def parse_paragraph_from(p_node)
      Elements::Containers::Paragraph.new(p_node, document_properties)
    end

    # generate Elements::Bookmark from bookmark XML node
    def parse_bookmark_from(b_node)
      Elements::Bookmark.new(b_node)
    end

    def parse_table_from(t_node)
      Elements::Containers::Table.new(t_node)
    end
  end
end

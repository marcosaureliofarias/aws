require 'easy_printable_docx/containers/table_row'
require 'easy_printable_docx/containers/table_column'
require 'easy_printable_docx/containers/container'

module EasyPrintableDocx
  module Elements
    module Containers
      class Table
        include Container
        include Elements::Element

        def self.tag
          'tbl'
        end

        def initialize(node)
          @node = node
          @properties_tag = 'tblGrid'
        end

        # Array of row
        def rows
          @node.xpath('w:tr').map {|r_node| Containers::TableRow.new(r_node) }
        end

        def row_count
          @node.xpath('w:tr').count
        end

        # Array of column
        def columns
          columns_containers = []
          (0..(column_count-1)).each do |i|
            columns_containers[i] = Containers::TableColumn.new @node.xpath("w:tr//w:tc[#{i+1}]")
          end
          columns_containers
        end

        def column_count
          @node.xpath('w:tblGrid/w:gridCol').count
        end

        # Iterate over each row within a table
        def each_rows
          rows.each { |r| yield(r) }
        end

        def alt_text
          alter_tag = @node.xpath('w:tblPr//w:tblCaption').first
          alter_tag ? alter_tag.attributes['val'].to_s : nil
        end

        def alt_text=(value)
          parent = @node.xpath('w:tblPr').first
          alt = Nokogiri::XML::Node.new 'tblCaption', @node.document
          alt.namespace = parent.namespace
          alt.set_attribute('val', value)
          alt.attributes['val'].namespace = parent.namespace
          parent.add_child(alt)
        end

      end
    end
  end
end

require 'easy_printable_docx/containers/table_cell'
require 'easy_printable_docx/containers/container'

module EasyPrintableDocx
  module Elements
    module Containers
      class TableColumn
        include Container
        include Elements::Element

        def self.tag
          'w:gridCol'
        end

        def initialize(cell_nodes)
          @node = ''
          @properties_tag = ''
          @cells = cell_nodes.map { |c_node| Containers::TableCell.new(c_node) }
        end

        # Array of cells contained within row
        def cells
          @cells
        end
        
      end
    end
  end
end

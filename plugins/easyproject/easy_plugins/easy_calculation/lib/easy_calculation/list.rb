module EasyCalculations
  class List

    def initialize(items, item)
      @items = sort(items)
      @item = item
      @item_index = @items.index(@item).to_i
    end

    def move_item_to(pos)
      return if pos.blank?
      case pos.to_s
      when 'highest'
        if @item_index > 0
          @items.insert(0, @items.delete_at(@item_index))
        end
      when 'higher'
        if @item_index > 0
          @items.insert(@item_index - 1, @items.delete_at(@item_index))
        end
      when 'lower'
        if @item_index < @items.size - 1
          @items.insert(@item_index + 1, @items.delete_at(@item_index))
        end
      when 'lowest'
        if @item_index < @items.size - 1
          @items.insert(@items.size - 1, @items.delete_at(@item_index))
        end
      end
      reset_positions_in_list
    end

    def reorder_to_position=(position)
      return if position.nil?
      position = position.to_i
      @items.insert(position - 1, @items.delete_at(@item_index))
      reset_positions_in_list
    end

    def reset_positions_in_list
      @items.each_with_index do |item, i|
        if item.calculation_position != (i + 1)
          item.update_column(:calculation_position, i + 1)
        end
      end
    end

    def sort(things)
      if things.first && (things.first.is_a?(Issue) || things.first.is_a?(EasyCalculationItem))
        things.sort_by{|e| [e.calculation_position || 0, e.is_a?(Issue) ? e.due_date || e.start_date || e.created_on.to_date : Date.today]}
      else
        things.sort_by{|e| e.calculation_position || 0}
      end
    end

  end
end

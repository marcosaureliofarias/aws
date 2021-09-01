Rys::Patcher.add('EasyGanttHelper') do

  apply_if_plugins :easy_gantt

  instance_methods(feature: 'project_flags') do

    def gantt_format_column(entity, column, value)
      if column.is_a?(EasyQueryCustomFieldColumn) && (column.custom_field.field_format == 'flag')
        return column.custom_field.format.formatted_value(self, column.custom_field, value, entity, true)
      end
      super
    end

  end

end

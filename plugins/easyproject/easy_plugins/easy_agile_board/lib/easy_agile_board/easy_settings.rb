EasySetting.map do

  key :agile_board_statuses do
    from_params { |raw_value|
      value = raw_value.to_hash rescue {}
      value[:progress] = value.delete('progress') if value['progress']
      value[:done] = value.delete('done') if value['done']
      value
    }
  end

  key :scrum_output_setting do
    default({})
  end

  key :kanban_output_setting do
    default({})
  end

end

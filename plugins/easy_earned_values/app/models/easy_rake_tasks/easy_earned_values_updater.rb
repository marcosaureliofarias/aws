class EasyEarnedValuesUpdater < EasyRakeTask

  def category_caption_key
    :label_easy_earned_values
  end

  def registered_in_plugin
    :easy_earned_values
  end

  def execute
    earned_values = EasyEarnedValue.for_reloading
    earned_values.find_each(batch_size: 10).with_index do |earned_value, index|
      if earned_value.reload_constantly
        earned_value.reload_all
      elsif earned_value.data_initilized
        earned_value.reload_actual
      else
        earned_value.reload_all
      end
    end

    true
  end

end

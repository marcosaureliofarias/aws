class EasyRakeTaskDisabled < EasyRakeTask

  def execute
    true
  end

  def in_disabled_plugin?
    true
  end

end
module EasyEarnedValues

  # Until patch is removed from easy_demo plugin
  def self.debug_mode?(*)
    false
  end

  def self.easy_baseline?
    Redmine::Plugin.installed?(:easy_baseline)
  end

end

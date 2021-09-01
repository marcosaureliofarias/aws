class EpmOrgChart < EasyPageModule
  AVAILABLE_VERTICAL_DEPTH = 5
  AVAILABLE_VERTICAL_DEPTH_OPTIONS = [['None', 0]] + AVAILABLE_VERTICAL_DEPTH.times.map{|i| ["#{i + 1} level" , i + 2] }

  def self.async_load
    false
  end

  def self.show_placeholder
    false
  end

  def category_name
    @category_name ||= 'users'
  end
end

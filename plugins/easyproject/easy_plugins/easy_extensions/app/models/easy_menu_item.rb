class EasyMenuItem < Redmine::MenuManager::MenuItem

  def initialize(name, url, options = nil)
    super
    @html_options[:class] = @html_options[:class].remove(@name.to_s.dasherize)
  end

end
module MindmupHelper

  def open_sidebar
    if page.has_css?('.nosidebar')
      page.find('.sidebar-control > a').click
    end
  end

  def close_sidebar
    unless page.has_css?('.nosidebar')
      page.find('.sidebar-control > a').click
    end
  end

  def mindmup_scale_down
    menu=page.find('#wbs_menu')
    scale_down=menu.find('.scaleDown')
    scale_down.click
    scale_down.click
  end

end

RSpec.configure do |config|
  config.include MindmupHelper, mindmup: true
end

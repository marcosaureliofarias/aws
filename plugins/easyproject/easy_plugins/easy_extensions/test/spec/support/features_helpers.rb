module FeaturesHelpers
  def wait_for_ajax(wait_time = nil)
    Timeout.timeout(wait_time || Capybara.default_max_wait_time) do
      loop until finished_all_ajax_requests?
    end
  end

  def wait_for_late_scripts(wait_time = nil)
    Timeout.timeout(wait_time || Capybara.default_max_wait_time) do
      loop until page_late_loaded?
    end
  end

  def finished_all_ajax_requests?
    # in feature jQuery.ajax.active
    # sleep 0.075
    page.evaluate_script('window.jQuery && jQuery.active') == 0
  end

  def page_late_loaded?
    page.evaluate_script('window.EasyGem && EasyGem.test.schedule.lateIsLoaded()')
  end

  def open_group(selector)
    group = find(selector)
    unless /open/.match?(group[:class])
      group.find('.module-heading').click
    end
  end

  def element_position(selector)
    x = page.evaluate_script("jQuery('#{selector}').position().left").to_i
    y = page.evaluate_script("jQuery('#{selector}').position().top").to_i
    [x, y]
  end

  def element_width(selector)
    page.evaluate_script("jQuery('#{selector}').width()").to_i
  end

  def scroll_to(element)
    script = <<-JS
      arguments[0].scrollIntoView(true);
    JS

    page.execute_script(script, element.native)
  end

  def scroll_to_and_click(element)
    scroll_to(element)
    element.click
  end

end
RSpec.configure do |config|
  config.include FeaturesHelpers, type: :feature
end

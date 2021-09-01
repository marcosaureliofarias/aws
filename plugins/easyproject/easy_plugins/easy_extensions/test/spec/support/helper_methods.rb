module HelperMethods

  def with_settings(options, &block)
    saved_settings = options.keys.inject({}) do |h, k|
      h[k] = case Setting[k]
             when Symbol, false, true, nil
               Setting[k]
             else
               Setting[k].dup
             end
      h
    end
    options.each { |k, v| Setting[k] = v }
    Setting.clear_cache
    yield
  ensure
    saved_settings.each { |k, v| Setting[k] = v } if saved_settings
    Setting.clear_cache
  end

  def with_easy_settings(options, project = nil, &block)
    saved_settings = options.keys.inject({}) do |h, k|
      value = EasySetting.value(k, project)
      h[k]  = case value
              when Symbol, Integer, false, true, nil
                value
              else
                value.dup
              end
      h
    end
    options.each do |k, v|
      set       = EasySetting.find_by(:name => k, :project_id => project.try(:id))
      set       ||= EasySetting.new(:name => k, :project => project)
      set.value = v
      set.save!
    end

    yield
  ensure
    if saved_settings
      saved_settings.each do |k, v|
        set       = EasySetting.find_by(:name => k, :project_id => project.try(:id))
        set.value = v
        set.save!
      end
    end
  end

  def with_user_pref(options, &block)
    user           = User.current
    pref           = user.pref
    saved_settings = options.keys.inject({}) do |h, k|
      value = pref.send(k)
      h[k]  = case value
              when Symbol, false, true, nil
                value
              else
                value.dup
              end
      h
    end
    options.each { |k, v| pref.send("#{k}=", v) }
    pref.save
    yield
  ensure
    saved_settings.each { |k, v| pref.send("#{k}=", v) } if saved_settings
    pref.save
  end

  def set_easy_setting(name, project, value)
    setting       = EasySetting.find_by(name: name, project_id: project.try(:id))
    setting       ||= EasySetting.new(name: name, project_id: project.try(:id))
    setting.value = value
    setting.save
  end

  # Yields the block with user as the current user
  def with_current_user(user, &block)
    saved_user = User.current
    allow(User).to receive(:current).and_return(user)
    yield
  ensure
    #not original, it is probably already stubed
    allow(User).to receive(:current).and_return(saved_user)
  end

  def logged_user(user)
    allow(User).to receive(:current).and_return(user)
  end

  def with_time_travel(amount, options = {}, &block)
    x = (options[:now] || Time.now) + amount
    allow(Time).to receive(:now).and_return(x)
    allow(Date).to receive(:today).and_return(x.to_date)
    allow(DateTime).to receive(:now).and_return(x.to_datetime)
    yield
  ensure
    allow(Time).to receive(:now).and_call_original
    allow(Date).to receive(:today).and_call_original
    allow(DateTime).to receive(:now).and_call_original
  end

  # fills a CKeditor with content of with
  def fill_in_ckeditor(identification, options = {})
    raise 'You have to provide an options hash containing :with' unless options.is_a?(Hash) && options[:with]

    content = options.fetch(:with).to_json
    if options[:context]
      case identification
      when Integer
        locator = ":first" if identification == 1
        locator ||= ":last"
        page.execute_script <<-SCRIPT
        if (typeof CKEDITOR !== "undefined") {
            var locator = jQuery("#{options[:context]}").find('textarea#{locator}').attr('id');
        CKEDITOR.instances[locator].setData(#{content});
        }
        SCRIPT
      when String
        page.execute_script <<-SCRIPT
          if (typeof CKEDITOR !== "undefined") {CKEDITOR.instances[#{identification}].setData(#{content});}
        SCRIPT
      end
    end
  end

  # time selects are not reliable across different browsers
  def convert_field_type_to_text(selector)
    page.execute_script("$('#{selector}').attr('type', 'text');")
  end

  def select_easy_page_module(name, zone)
    within("#list-#{zone}") { select name, :from => 'module_id' }
    wait_for_ajax
  end

  def save_easy_page_modules
    page.execute_script("$('.save-modules-back').trigger('click');") # top menu hack
  end

  def visit_issue_with_edit_open(issue)
    visit issue_path(issue)

    wait_for_late_scripts
    page.find('.primary-actions a.icon-edit').click
    page.find('.issue-edit-hidden-attributes').click
    wait_for_ajax
  end

  def self.tested_easy_queries
    q = EasyQuery.constantized_subclasses - EasyIssueQuery.descendants + [EasyAdminProjectQuery]
    q << EasyMoneyUserRateQuery if Redmine::Plugin.installed?(:easy_money)
    q
  end

  def self.instanced_easy_queries
    instanced = {}
    tested_easy_queries.each { |q| instanced[q] = q.new }
    instanced
  end

  def with_deliveries(&block)
    adapter                                 = ActionMailer::DeliveryJob.queue_adapter
    ActionMailer::DeliveryJob.queue_adapter = ActiveJob::QueueAdapters::InlineAdapter.new
    yield
  ensure
    ActionMailer::DeliveryJob.queue_adapter = adapter
  end

end

RSpec.configure do |config|
  config.include HelperMethods
end

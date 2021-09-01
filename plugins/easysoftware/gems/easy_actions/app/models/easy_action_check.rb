class EasyActionCheck < ActiveRecord::Base
  include Easy::Redmine::BasicEntity

  belongs_to :easy_action_check_template
  belongs_to :entity, polymorphic: true

  enum status: { unknown: 0, ok: 1, failed: 9 }, _prefix: :status

  def action_worker
    return @action_worker if @action_worker

    @action_worker = easy_action_check_template.create_worker

    if @action_worker.is_a?(EasyActions::Actions::CallUrl)
      @action_worker.query                   ||= {}
      @action_worker.query[:passed_callback] = "#{Setting.protocol}://#{Setting.host_name}/#{Rails.application.routes.url_helpers.passed_easy_action_check_path(self, format: :json)}"
      @action_worker.query[:failed_callback] = "#{Setting.protocol}://#{Setting.host_name}/#{Rails.application.routes.url_helpers.failed_easy_action_check_path(self, format: :json)}"
    end

    @action_worker
  end

  def fire
    action_worker&.fire(self)
  end

  def fire!
    response = fire

    if response == false
      self.status = :failed
    elsif response == true
      self.status = :ok
    else
      self.status = :ok
      self.result = response.to_s
    end

    save
  end

end

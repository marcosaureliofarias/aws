class EasyActionCheckTemplate < ActiveRecord::Base
  include Easy::Redmine::BasicEntity

  has_many :easy_action_checks, dependent: :destroy

  store :action_settings, coder: JSON

  safe_attributes 'action_class', 'action_settings'

  validates :name, :action_class, presence: true

  def create_worker
    action_class.safe_constantize&.new(action_settings) if action_class.present?
  end

end

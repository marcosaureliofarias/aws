class EasyOauth2Application < ActiveRecord::Base
  include Easy::Redmine::BasicEntity

  self.permission_show    = :view_easy_oauth2
  self.permission_edit    = :manage_easy_oauth2
  self.permission_destroy = :manage_easy_oauth2
  self.allowed_subclasses = %w[EasyOauth2ServerApplication EasyOauth2ClientApplication]

  has_many :easy_oauth2_application_callbacks, dependent: :destroy
  has_many :easy_oauth2_application_user_authorizations, dependent: :destroy
  has_many :easy_oauth2_access_grants, foreign_key: 'easy_oauth2_application_id', dependent: :destroy

  scope :active, lambda { where(active: true) }
  scope :like, ->(q) { where(arel_table[:name].matches("%#{q}%")) }

  store :settings, accessors: %i[], coder: JSON

  validates :name, :type, :app_url, presence: true
  validates_uniqueness_of :app_id, :app_secret, scope: [:type], case_sensitive: true

  safe_attributes 'name', 'active', 'app_url'

  before_validation :set_guid, on: :create
  before_validation :set_name

  def self.format_html_entity_name
    'easy_oauth2_application'
  end

  def partial_form_view
    "easy_oauth2_applications/form_#{type.demodulize.underscore}" if type
  end

  def partial_show_view
    "easy_oauth2_applications/#{type.demodulize.underscore}" if type
  end

  protected

  def set_guid
    self.guid = SecureRandom.uuid
  end

  def set_name
    self.name = app_url if self.name.blank?
  end

end

class EasyJenkins::Setting < ApplicationRecord
  self.table_name = 'easy_jenkins_settings'

  belongs_to :project

  has_many :pipelines, class_name: 'EasyJenkins::Pipeline', dependent: :destroy, foreign_key: 'easy_jenkins_setting_id'

  validates :url, :user_name, :user_token, :project_id, presence: true
  validates :project_id, uniqueness: true

  accepts_nested_attributes_for :pipelines, reject_if: :all_blank, allow_destroy: true
end

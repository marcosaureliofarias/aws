class EasyActionSequenceCategory < ActiveRecord::Base
  include Easy::Redmine::BasicEntity

  belongs_to :easy_action_sequence_template

  validates :name, presence: true

  safe_attributes 'name', 'description'

end

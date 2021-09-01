class ReRating < ActiveRecord::Base
  belongs_to :re_artifact_properties
  belongs_to :user
end

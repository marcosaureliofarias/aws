class ReStatus < ActiveRecord::Base
  belongs_to :project
  has_many :re_artifact_properties

  def to_s
    alias_name || label
  end
end
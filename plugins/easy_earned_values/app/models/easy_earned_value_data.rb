class EasyEarnedValueData < ActiveRecord::Base

  validates :date, uniqueness: { scope: [:easy_earned_value_id] }

end

require 'easy_extensions/spec_helper'

RSpec.describe EasyGanttResource, type: :model, logged: :admin do

  it 'hours_per_day' do
    with_easy_settings(easy_gantt_resources_advance_hours_definition: false,
                       easy_gantt_resources_hours_per_day: 8,
                       easy_gantt_resources_users_hours_limits: { '1' => 2, '2' => 4 }) do

      expect( EasyGanttResource.hours_on_week(1).first ).to eq(2.0)
      expect( EasyGanttResource.hours_on_week(2).first ).to eq(4.0)
      expect( EasyGanttResource.hours_on_week(3).first ).to eq(8.0)
   end
  end

end

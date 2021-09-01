FactoryBot.define do
  factory :easy_gantt_reservation do
    assigned_to_id { User.current.id }
    author_id { User.current.id }
    sequence(:name){ |n| "Reservation ##{n}" }
    estimated_hours { 5 }
    allocator { 'evenly' }
    start_date { Date.today }
    due_date { Date.today + 1.day }
  end
end
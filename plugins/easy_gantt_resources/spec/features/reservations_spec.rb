require 'easy_extensions/spec_helper'

RSpec.feature 'Resource reservations', js: true, logged: :admin, if: Redmine::Plugin.installed?(:easy_gantt_pro) do
  anchor = Date.today.beginning_of_week

  let(:project) {
    FactoryGirl.create(:project, number_of_members: 1, add_modules: ['easy_gantt', 'easy_gantt_resources'])
  }

  let!(:reservation_1) {
    FactoryGirl.create(:easy_gantt_reservation,
      assigned_to_id: project.members[0].user_id,
      estimated_hours: 25,
      start_date: anchor,
      due_date: anchor + 4.days
    )
  }

  around(:each) do |example|
    with_settings(rest_api_enabled: 1) {
      with_easy_settings(easy_gantt_resources_change_allocator_enabled: true, easy_gantt_resources_reservation_enabled: true) {
        example.run
      }
    }
  end


  scenario 'update reservations' do
    user = project.members[0].user
    expect(reservation_1.assigned_to).to eq(user)
    old_start = reservation_1.start_date
    old_due = reservation_1.due_date
    visit easy_gantt_path(project, gantt_type: 'rm')
    wait_for_ajax
    expect(page).to have_text(user.name)
    expect(page).to have_text(reservation_1.name)
    expect(gather_allocations).to eq([5, 5, 5, 5, 5])
    move_reservation(reservation_1, 0, -1)
    expect(gather_allocations).to eq([6, 6, 6, 7])
    move_reservation(reservation_1, 2, 4)
    expect(gather_allocations).to eq([5, 5, 5, 0, 0, 5, 5])
    click_link(I18n.t(:button_save))
    wait_for_ajax
    reservation_1.reload
    expect(reservation_1.start_date).to eq(old_start + 2.days)
    expect(reservation_1.due_date).to eq(old_due + 4.days)
    allocations = reservation_1.resources.map { |allocation| allocation.hours }
    expect(allocations).to eq([5, 5, 5, 0, 0, 5, 5])
  end

  scenario 'create reservations' do
    visit easy_gantt_path(project, gantt_type: 'rm')
    wait_for_ajax
    expect(page).to have_text(reservation_1.name)

    id_1 = create_reservation(anchor + 2.days, anchor + 3.days, 5)
    expect(gather_allocations(id_1)).to eq([2, 3])
    id_2 = create_reservation(anchor + 3.days, anchor + 7.days, 10)
    expect(gather_allocations(id_2)).to eq([3, 3, 0, 0, 4])

  end

  def move_reservation(reservation, start_shift, due_shift)
    script = <<-EOF
      (function(){var reservation = ysy.data.resourceReservations.getByID(#{reservation.id});
        reservation.set({
          start_date:moment('#{reservation.start_date + start_shift.days}'),
          end_date:moment('#{reservation.due_date + due_shift.days}')
        });
        return "success";
      })()
    EOF
    expect(page.evaluate_script(script)).to eq('success')
  end

  def gather_allocations(id = reservation_1.id)
    script = <<-EOF
      (function(){
        var reservation = ysy.data.resourceReservations.getByID(#{id});
        var allocations = reservation.allocPack.allocations;
        var dates = Object.getOwnPropertyNames(allocations).sort();
        return dates.map(function(date){return allocations[date]});
      })();
    EOF
    page.evaluate_script(script)
  end

  def create_reservation(start_date, due_date, estimated_hours)
    script = <<-EOF
      (function(){
        ysy.pro.resource.reservations.createReservation([
          {name:'easy_gantt_reservation[start_date]',value:'#{start_date}'},
          {name:'easy_gantt_reservation[due_date]',value:'#{due_date}'},
          {name:'easy_gantt_reservation[estimated_hours]',value:#{estimated_hours}}
        ]);
        return ysy.data.resourceReservations.get(ysy.data.resourceReservations.array.length-1).id;
      })();
    EOF
    page.evaluate_script(script)
  end
end

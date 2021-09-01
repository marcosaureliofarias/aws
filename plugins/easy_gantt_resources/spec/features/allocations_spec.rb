require 'easy_extensions/spec_helper'

RSpec.feature 'Resource', js: true, logged: :admin do

  let(:project) {
    FactoryGirl.create(:project, number_of_members: 1, add_modules: ['easy_gantt', 'easy_gantt_resources'])
  }

  let!(:issue_1) {
    FactoryGirl.create(:issue,
      project_id: project.id,
      assigned_to_id: project.members[0].user_id,
      estimated_hours: 25,
      start_date: '2017-08-07',
      due_date: '2017-08-11'
    )
  }

  around(:each) do |example|
    with_settings(rest_api_enabled: 1) {
      with_easy_settings(easy_gantt_resources_change_allocator_enabled: true) {
        example.run
      }
    }
  end

  scenario 'allocate by allocator' do
    user=project.members[0].user
    expect(issue_1.assigned_to).to eq(user)
    visit easy_gantt_path(project, gantt_type: 'rm')
    wait_for_ajax
    expect(page).to have_text(user.name)
    change_allocator 'from_start'
    expect(extract_allocations).to eq([8, 8, 8, 1, 0])
    change_allocator 'from_end'
    expect(extract_allocations).to eq([0, 1, 8, 8, 8])
    change_allocator 'evenly'
    expect(extract_allocations).to eq([5, 5, 5, 5, 5])
    clear_history
  end

  def change_allocator(allocator)
    change_script= <<-EOF
      (function(){
        var issueAllocations = ysy.data.allocations.getByID(#{issue_1.id});
        issueAllocations.set({allocator: "#{allocator}"});
        return "success";
      })()
    EOF
    expect(page.evaluate_script(change_script)).to eq('success')
  end

  def extract_allocations
    script= <<-EOF
      (function(){
        var issueAllocations = ysy.data.allocations.getByID(#{issue_1.id});
        var allocations = issueAllocations.allocPack.allocations;
        var dates = Object.getOwnPropertyNames(allocations).sort();
        return dates.map(function(date){return allocations[date]});
      })();
    EOF
    page.evaluate_script(script)
  end
  def clear_history
    script= <<-EOF
      (function(){
        ysy.history.clear();
      })();
    EOF
    page.execute_script(script)
  end
end

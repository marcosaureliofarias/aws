require File.expand_path('../../../../easyproject/easy_plugins/easy_extensions/test/spec/spec_helper', __FILE__)
require 'json'

RSpec.feature 'Relation move', logged: :admin, js: true do
  around(:each) do |example|
    with_settings(rest_api_enabled: 1) { example.run }
  end

  let!(:project) { FactoryGirl.create(:project, add_modules: ['easy_gantt'], number_of_issues: 0) }

  describe 'classic' do
    before(:all) do
      @render_counter=0
    end

    scenario 'should move other issues' do
      init_data = '{"issues":[{"subject":"Ascendant","start_date":"2017-11-20","due_date":"2017-11-20"},{"subject":"Parent task","start_date":"2017-11-21","due_date":"2017-11-30"},{"subject":"Second subtask","start_date":"2017-11-21","due_date":"2017-11-24","parent_issue":1},{"subject":"First subtask","start_date":"2017-11-21","due_date":"2017-11-21","parent_issue":1},{"subject":"Third subtask","start_date":"2017-11-23","due_date":"2017-11-24","parent_issue":1},{"subject":"Forth subtask","start_date":"2017-11-23","due_date":"2017-11-30","parent_issue":1},{"subject":"Middle man","start_date":"2017-12-01","due_date":"2017-12-01"},{"subject":"Descendant","start_date":"2017-12-01","due_date":"2017-12-01","milestone":0}],"milestones":[{"name":"Milestone","due_date":"2017-12-05"}],"relations":[{"source":0,"target":1,"type":"precedes","delay":0},{"source":1,"target":7,"type":"precedes","delay":0},{"source":3,"target":5,"type":"precedes","delay":1},{"source":2,"target":6,"type":"precedes","delay":2}]}'
      zero_move = '{"issues":[{"subject":"Ascendant","start_date":"2017-11-20","due_date":"2017-11-20"},{"subject":"Parent task","start_date":"2017-11-21","due_date":"2017-11-30"},{"subject":"Second subtask","start_date":"2017-11-21","due_date":"2017-11-24","parent_issue":1},{"subject":"First subtask","start_date":"2017-11-21","due_date":"2017-11-21","parent_issue":1},{"subject":"Third subtask","start_date":"2017-11-23","due_date":"2017-11-24","parent_issue":1},{"subject":"Forth subtask","start_date":"2017-11-23","due_date":"2017-11-30","parent_issue":1},{"subject":"Middle man","start_date":"2017-11-27","due_date":"2017-11-27"},{"subject":"Descendant","start_date":"2017-12-01","due_date":"2017-12-01","milestone":0}],"milestones":[{"name":"Milestone","due_date":"2017-12-05"}],"relations":[{"source":0,"target":1,"type":"precedes","delay":0},{"source":1,"target":7,"type":"precedes","delay":0},{"source":3,"target":5,"type":"precedes","delay":1},{"source":2,"target":6,"type":"precedes","delay":2}]}'
      two_days_forward = '{"issues":[{"subject":"Ascendant","start_date":"2017-11-22","due_date":"2017-11-22"},{"subject":"Parent task","start_date":"2017-11-23","due_date":"2017-12-04"},{"subject":"Second subtask","start_date":"2017-11-23","due_date":"2017-11-28","parent_issue":1},{"subject":"First subtask","start_date":"2017-11-23","due_date":"2017-11-23","parent_issue":1},{"subject":"Third subtask","start_date":"2017-11-27","due_date":"2017-11-28","parent_issue":1},{"subject":"Forth subtask","start_date":"2017-11-27","due_date":"2017-12-04","parent_issue":1},{"subject":"Middle man","start_date":"2017-12-01","due_date":"2017-12-01"},{"subject":"Descendant","start_date":"2017-12-05","due_date":"2017-12-05","milestone":0}],"milestones":[{"name":"Milestone","due_date":"2017-12-05"}],"relations":[{"source":0,"target":1,"type":"precedes","delay":0},{"source":1,"target":7,"type":"precedes","delay":0},{"source":3,"target":5,"type":"precedes","delay":1},{"source":2,"target":6,"type":"precedes","delay":2}]}'
      three_days_backward = '{"issues":[{"subject":"Ascendant","start_date":"2017-11-17","due_date":"2017-11-17"},{"subject":"Parent task","start_date":"2017-11-20","due_date":"2017-11-29"},{"subject":"Second subtask","start_date":"2017-11-20","due_date":"2017-11-23","parent_issue":1},{"subject":"First subtask","start_date":"2017-11-20","due_date":"2017-11-20","parent_issue":1},{"subject":"Third subtask","start_date":"2017-11-22","due_date":"2017-11-23","parent_issue":1},{"subject":"Forth subtask","start_date":"2017-11-22","due_date":"2017-11-29","parent_issue":1},{"subject":"Middle man","start_date":"2017-11-27","due_date":"2017-11-27"},{"subject":"Descendant","start_date":"2017-11-30","due_date":"2017-11-30","milestone":0}],"milestones":[{"name":"Milestone","due_date":"2017-12-05"}],"relations":[{"source":0,"target":1,"type":"precedes","delay":0},{"source":1,"target":7,"type":"precedes","delay":0},{"source":3,"target":5,"type":"precedes","delay":1},{"source":2,"target":6,"type":"precedes","delay":2}]}'
      visit easy_gantt_path(project, debug: true)
      wait_for_ajax
      init_render_waiter
      expect(obtain_relation_mode).to be_falsey
      insert_model init_data
      moved_issue_index = 0
      compare_js_state_with_data init_data, 'Integrity check'
      move_by(moved_issue_index, 0)
      compare_js_state_with_data zero_move, 'Zero days move'
      expect(page).to have_css('.gantt_task_link')
      expect(page).not_to have_css('.gantt_task_link.wrong')
      move_by(moved_issue_index, 2)
      compare_js_state_with_data two_days_forward, 'Two days forward'
      expect(page).not_to have_css('.gantt_task_link.wrong')
      reset_move
      move_by(moved_issue_index, -3)
      compare_js_state_with_data three_days_backward, 'Three days backward'
      expect(page).not_to have_css('.gantt_task_link.wrong')
      reset_move
      move_by(moved_issue_index, 5)
      compare_js_state_with_data two_days_forward, 'Five days forward blocked by milestone'
      expect(page).not_to have_css('.gantt_task_link.wrong')
      reset_move

    end

  end

  ######################################################################################################################

  def insert_model(test_model)
    evaluate_script("ysy.insertTestModel('#{test_model}');")
    wait_for_render
  end

  def init_render_waiter
    evaluate_script(
    # language=JavaScript
    'ysy.renderWaiter.init();')
  end

  def wait_for_render
    @render_counter+=1
    evaluate_script("ysy.renderWaiter.set(#{@render_counter});")
    expect(page).to have_text("Render Waiter: << #{@render_counter} >>")
  end

  def obtain_js_state
    JSON.parse evaluate_script('ysy.exportForTest();')
  end

  def obtain_relation_mode
    evaluate_script('ysy.settings.fixedRelations;')
  end

  def compare_js_state_with_data(data, test_group)
    if data.is_a? String
      data = JSON.parse data
    end
    js_state = obtain_js_state
    data['milestones'].each_with_index do |milestone_data, index|
      milestone_state=js_state['milestones'][index]
      expect(milestone_state['name']).to eq(milestone_data['name'])
      expect(milestone_state['due_date']).to eq(milestone_data['due_date']), "#{test_group}: expected #{milestone_state['name']} have due_date=#{milestone_data['due_date']}, got #{milestone_state['due_date']}"
    end
    data['issues'].each_with_index do |issue_data, index|
      issue_state=js_state['issues'][index]
      expect(issue_state['subject']).to eq(issue_data['subject'])
      expect(issue_state['start_date']).to eq(issue_data['start_date']), "#{test_group}: expected #{issue_state['subject']} have start_date=#{issue_data['start_date']}, got #{issue_state['start_date']}"
      expect(issue_state['due_date']).to eq(issue_data['due_date']), "#{test_group}: expected #{issue_state['subject']} have due_date=#{issue_data['due_date']}, got #{issue_state['due_date']}"
    end
    data['relations'].each_with_index do |relation_data, index|
      relation_state=js_state['relations'][index]
      expect(relation_state['source']).to eq(relation_data['source'])
      expect(relation_state['target']).to eq(relation_data['target'])
      expect(relation_state['type']).to eq(relation_data['type'])
      expect(relation_state['delay']).to eq(relation_data['delay'])
    end
  end

  def move_by(issue_index, days)
    evaluate_script(
      #language=JavaScript
      "(function(){
        var issueId = ysy.data.issues.get(#{issue_index}).id;
        var task = gantt._pull[issueId];
        var copy = dhtmlx.mixin({}, task);
        var limits = gantt.prepareMultiStop(task);
        var new_start = moment(task.start_date).add(#{days}+0,'days');
        var new_end = gantt._working_time_helper.add_worktime(new_start, task.duration, 'day', true);
        gantt.multiStop(copy, new_start, new_end, limits);
        copy.start_date = new_start;
        copy.end_date = new_end;
        gantt.moveDependent(copy);
        // task.widget.update(copy);
        task.start_date = copy.start_date;
        task.end_date = copy.end_date;
        task._changed = true;
        gantt.updateAllTask();
      })()"
    )
    wait_for_render
  end

  def reset_move
    execute_script('ysy.history.revert();')
    wait_for_render
  end

end

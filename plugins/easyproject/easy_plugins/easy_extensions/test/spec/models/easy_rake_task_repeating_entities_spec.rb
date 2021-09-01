require 'easy_extensions/spec_helper'

describe EasyRakeTaskRepeatingEntities do

  let(:issue) { FactoryGirl.create(:issue, :reccuring, :update_repeat_entity_attributes => true) }
  let(:watcher) { FactoryGirl.create(:watcher, watchable: issue) }
  let(:author) { issue.author }
  let(:the_boss) { FactoryGirl.create(:user) }
  let(:assigned_to) { issue.assigned_to }
  let(:rake_task) { EasyRakeTaskRepeatingEntities.new(:active => true, :settings => {}, :period => :daily, :interval => 1, :next_run_at => Time.now) }

  it 'create issue to be repeated with the right params' do
    issue

    with_time_travel(1.day) do
      expect { rake_task.execute }.to change(Issue, :count).by(1)
    end

    issue.reload

    expect(issue.relations_from.count).to eq(1)
    expect(issue.easy_repeat_settings['entity_attributes']['author_id']).to eq(author.id)
    issue_to = issue.relations_from.first.issue_to

    expect(issue_to.author).to eq(author)
    expect(issue_to.assigned_to).to eq(assigned_to)
  end

  context 'updating issue without altering attributes for repeating' do
    it 'repeats issue using old attributes' do
      issue; author

      issue.update_repeat_entity_attributes = false
      issue.update_attributes(:author_id => the_boss.id)

      with_time_travel(1.day) do
        expect { rake_task.execute }.to change(Issue, :count).by(1)
      end

      issue.reload
      expect(issue.author).to eq(the_boss)
      expect(issue.easy_repeat_settings['entity_attributes']['author_id']).to eq(author.id)
      issue_to = issue.relations_from.first.issue_to

      expect(issue_to.author).to eq(author)
    end
  end

  it 'set right repeat date, when created' do
    issue       = FactoryGirl.create(:issue, :recurring_monthly)
    repeat_day  = issue.easy_repeat_settings['monthly_day'].to_i
    date_should = (Date.today.mday < repeat_day ? Date.today : Date.today.next_month).beginning_of_month + (repeat_day - 1).days

    expect(issue.easy_next_start).to eq(date_should)
  end

  it 'repeat with watchers' do
    watcher
    issue.reload

    with_time_travel(1.day) do
      expect {
        expect { rake_task.execute }.to change(Watcher, :count).by(1)
      }.not_to change(issue.watchers, :count)
    end
  end

end

require 'easy_extensions/spec_helper'

describe EpmIssuesCreateNew, logged: :admin do
  let(:user) { FactoryBot.create(:user) }
  let(:group) { FactoryBot.create(:group) }
  let(:issue) { FactoryBot.build(:issue) }
  context 'show coworkers' do
    let(:page_module) { described_class.new }
    let(:settings) {
      {
        'show_fields_option' => 'only_selected',
        'selected_fields' => { watchers: { 'enabled' => '1', 'default_value' => [group.id, user.id] } }
      }
    }
    let(:context) { { issue: issue } }

    subject(:show_data) { page_module.get_show_data(settings, User.current, context) }

    before do
      allow(issue).to receive(:assignable_users) { [user] }
      allow(issue).to receive(:available_groups) { [group] }
      allow(issue).to receive(:addable_watcher_users) { [User.current] }
    end

    it 'selected coworkers' do
      expect(show_data[:issue].watched_by?(group)).to be_truthy
      expect(show_data[:issue].watched_by?(user)).to be_falsey
    end
  end
end

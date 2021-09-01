require 'easy_extensions/spec_helper'

RSpec.describe EasyChecklist, type: :model do

  let(:project) {FactoryGirl.create(:project, :add_modules => ['easy_checklists'])}
  let(:issue) {
    issue = FactoryGirl.create(:issue, :project => project)
    easy_checklist = FactoryGirl.create(:easy_checklist, :with_easy_checklist_items, :entity => issue)
    issue
  }
  let(:not_saved_issue) { FactoryGirl.build(:issue, :project => issue.project) }
  let(:easy_checklist) { FactoryGirl.create(:easy_checklist, :with_easy_checklist_items, :entity => issue) }
  let(:not_saved_easy_checklist) { FactoryGirl.build(:easy_checklist, :with_easy_checklist_items, :entity => issue) }

  it 'changes done ratio when settings is enabled' do
    with_easy_settings({
      'easy_checklist_use_project_settings' => true,
      'easy_checklist_enable_change_done_ratio' => true }, project) do
      issue
      easy_checklist = issue.easy_checklists.first
      item = easy_checklist.easy_checklist_items.first
      item.done = true

      expect {
        item.save
      }.to change{ issue.reload.done_ratio }.to(30)

      expect {
        easy_checklist.easy_checklist_items.create(subject: 'xxx')
        easy_checklist.reload.easy_checklist_items.create(subject: 'xxx2')
      }.to change{ issue.reload.done_ratio }.to(20)

      expect {
        easy_checklist.reload.easy_checklist_items.where(subject: ['xxx', 'xxx2']).destroy_all
      }.to change{ issue.reload.done_ratio }.to(30)
    end
  end

  it 'will create issue with easy_checklist if easy_checklist is present in form' do
    not_saved_issue.easy_checklists = [not_saved_easy_checklist]

    expect {
      not_saved_issue.save
    }.to change{ EasyChecklist.count }.by(1)
  end

end

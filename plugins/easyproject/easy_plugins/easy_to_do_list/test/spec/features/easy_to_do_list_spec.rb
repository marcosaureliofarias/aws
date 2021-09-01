require 'easy_extensions/spec_helper'

feature 'Easy To Do', js: true, logged: :admin do
  let(:issue)  { FactoryBot.create(:issue) }

  def open_todo
    page.find('#easy_to_do_list_toolbar_trigger').click
    wait_for_ajax
  end

  def add_item(name)
    page.find('.add-easy-to-do-lists-item').click
    page.find('#easy_to_do_list_item_name').set(name)
    page.find('#new_easy_to_do_list_item input[type=\'submit\']').click
  end

  scenario 'add an item' do
    visit root_path
    open_todo
    add_item('item')
    expect(page.find('.to-do-lists')).to have_text('item')
  end

 scenario 'add an issue by drag & drop' do
   visit issue_path(issue)
   open_todo
   add_item('item')
   issue_handler = page.find('.issue-detail-header .ui-draggable-handle', :visible => false)
   todo_item_handler = page.find('.to-do-lists .ui-sortable-handle')
   issue_handler.drag_to(todo_item_handler)
   wait_for_ajax
   expect(page.find('.to-do-lists')).to have_text(issue.subject)
 end
end

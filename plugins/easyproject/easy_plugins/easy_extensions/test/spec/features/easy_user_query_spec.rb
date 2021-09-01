require 'easy_extensions/spec_helper'

feature 'User query view', :js => true, :logged => :admin do
  let!(:project1) { FactoryGirl.create(:project) }
  let!(:project2) { FactoryGirl.create(:project) }
  let(:user) { FactoryGirl.create(:user) }
  let(:last_user) { FactoryGirl.create(:user, :login => 'Loggin', :firstname => 'ZZ') }


  context 'lists roles according to context' do
    let!(:member1) { FactoryGirl.create(:member, :project => project1, :principal => user) }
    let!(:member2) { FactoryGirl.create(:member, :project => project2, :principal => user) }

    scenario 'on users show' do
      visit users_path(:set_filter => '1', :column_names => ['roles'])
      expect(page.find('table.entities').all("#entity-#{user.id} > td.roles a").count).to eq(2)
    end

    scenario 'on project page inside a module', js_wait: :long do
      visit project_path(project1)

      page.find('.customize-button').click
      wait_for_ajax
      within('#list-top') { select I18n.t(:users_query, scope: [:easy_pages, :modules]), :from => 'module_id' }
      wait_for_ajax
      page.find('.easy-query-output-list input[value="list"]').click
      page.first('.easy-query-columns').find('[value=roles]').select_option
      page.find('#modal_selector_move_column_right_button').click
      save_easy_page_modules

      expect(page).to have_css('.easy-page-content.show')
      expect(page.current_path).to eq "/projects/#{project1.id}"

      page.find('table.entities')
      expect(page.find('table.entities').all("#entity-#{user.id} > td.roles a").count).to eq(1)
    end
  end

  context 'grouped' do
    scenario 'open group' do
      last_user
      visit users_path(:set_filter => '1', :column_names => ['login', 'firstname'], :group_by => 'firstname', :load_groups_opened => false)
      page.find('table.entities').all('tr.group span.expander').last.click
      wait_for_ajax
      expect(page).to have_text('Loggin')
    end
  end

end

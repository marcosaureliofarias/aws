require 'easy_extensions/spec_helper'

feature 'easy knowledge permissions', js: true do
  let(:user) { FactoryBot.create(:user) }
  let(:user2) { FactoryBot.create(:user) }
  let(:project) {FactoryBot.create(:project, add_modules: ['easy_knowledge']).reload}
  let(:easy_knowledge_story) { FactoryBot.create(:easy_knowledge_story) }
  let(:easy_knowledge_global_story) { FactoryBot.create(:easy_knowledge_story) }
  let(:easy_knowledge_assigned_story) { FactoryBot.create(:easy_knowledge_assigned_story, easy_knowledge_story: easy_knowledge_story, entity: User.current, read_date: nil) }
  let(:easy_knowledge_project_story) {
    story = FactoryBot.create(:easy_knowledge_story, author: user2)
    story.projects << project
    story
  }
  let!(:easy_knowledge_project_category) {
    category = FactoryBot.build(:easy_knowledge_category)
    category.entity = project
    category.save
    category
  }
  let!(:easy_knowledge_global_category) { FactoryBot.create(:easy_knowledge_category) }
  let(:easy_knowledge_user_story) {
    FactoryBot.create(:easy_knowledge_story, author: user)
  }
  let(:easy_knowledge_project_user_story) {
    story = FactoryBot.create(:easy_knowledge_story, author: user, entity: project)
    story.projects << project
    story
  }
  let(:easy_knowledge_other_user_global_story) {
    FactoryBot.create(:easy_knowledge_story, author: user2)
  }
  let(:easy_knowledge_overview_page) { EasyPage.create!(:page_name => 'easy-knowledge-overview', :layout_path => 'easy_page_layouts/two_column_header_three_rows_right_sidebar')}

  # global permissions

  scenario 'create_global_stories should allow create global stories' do
    log_user_with_permissions(:create_global_stories, :read_global_stories)

    can_create_global_story?
  end

  scenario 'read_global_stories should allow show global stories' do
    log_user_with_permissions(:read_global_stories)

    can_show_global_story?(easy_knowledge_global_story)
  end

  scenario 'manage_global_stories should allow manage global categories' do
    log_user_with_permissions(:manage_global_categories)

    can_create_global_categories?
    can_edit_global_categories?(easy_knowledge_global_category)
  end

  scenario 'manage_easy_knowledge page should not allow manage knowledge layout' do
    easy_knowledge_overview_page
    log_user_with_permissions(:manage_global_categories)

    cannot_customise_page?
  end

  scenario 'manage_easy_knowledge page should allow manage knowledge layout' do
    easy_knowledge_overview_page
    log_user_with_permissions(:manage_easy_knowledge_page)

    can_customise_page?
  end

  scenario 'edit_own_global_stories should allow edit own global stories' do
    log_user_with_permissions(:edit_own_global_stories, :read_global_stories)

    can_edit_global_story?(easy_knowledge_user_story)
  end

  scenario 'edit_all_global_stories should allow edit global stories' do
    log_user_with_permissions(:edit_all_global_stories, :read_global_stories)

    can_edit_global_story?(easy_knowledge_other_user_global_story)
  end

  # project permissions

  scenario 'read_project_stories should allow show project stories' do
    log_user_with_permissions(:read_project_stories)

    can_show_project_story?(project, easy_knowledge_project_story)
  end

  scenario 'create_project_stories should allow create project stories' do
    log_user_with_permissions(:create_project_stories, :read_project_stories)

    can_create_project_story?(project)
    cannot_see_global_categories_in_project_new?(project)
  end

  scenario 'edit_all_project_stories should allow edit project stories' do
    log_user_with_permissions(:edit_all_project_stories, :read_project_stories)

    can_edit_project_story?(project, easy_knowledge_project_story)
  end

  scenario 'edit_own_project_stories should allow edit own project stories' do
    log_user_with_permissions(:edit_own_project_stories, :read_project_stories)

    can_edit_project_story?(project, easy_knowledge_project_user_story)
  end

  scenario 'manage_project_categories should allow manage project categories' do
    log_user_with_permissions(:manage_project_categories)

    can_create_project_categories?(project)
    can_edit_project_categories?(easy_knowledge_project_category)
  end

  def log_user_with_permissions(*permissions)
    role = FactoryBot.create(:role)
    role.permissions = permissions
    role.permissions << :view_easy_knowledge
    role.save
    member = FactoryBot.create(:member, :without_roles, project: project, user: user)
    member_role = FactoryBot.create(:member_role, member: member, role: role)
    logged_user(user)
    I18n.locale = User.current.language if User.current.language.present?
  end

  def can_create_project_story?(project)
    visit easy_knowledge_project_stories_overview_path(project)
    expect(page).to have_content(Regexp.new(I18n.t(:label_easy_knowledge_new_story)))
    can_see_project_categories_in_new?(project)
  end

  def can_edit_project_story?(project, story)
    visit edit_project_easy_knowledge_story_path(project, story)
    expect(page).to have_css('.easy-knowledge-stories-form-right-panel')
  end

  def can_show_project_story?(project, story)
    visit project_easy_knowledge_story_path(project, story)
    expect(page).to have_content(story.name)
    expect(page).to have_content(I18n.t(:easy_knowledge_project_menu))
  end

  def can_create_global_story?
    # check top menu item new post
    visit root_path
    page.find('a#top-menu-rich-more-toggler').click
    expect(page).to have_content(I18n.t(:menu_easy_knowledge))

    page.execute_script('$(".menu-children").show()')
    expect(page).to have_content(I18n.t(:label_easy_knowledge_new_story))
    can_see_global_categories_in_new?
  end

  def can_edit_global_story?(story)
    # check top menu item knowledge
    # check edit button in show
    # check context menu button
    visit edit_easy_knowledge_story_path(story)
    expect(page).to have_css('.easy-knowledge-stories-form-right-panel')
    page.find('a#top-menu-rich-more-toggler').click
    expect(page).to have_content(I18n.t(:menu_easy_knowledge))
  end

  def can_show_global_story?(story)
    # check top menu item knowledge
    # check visible
    # visit show
    visit easy_knowledge_story_path(story)
    expect(page).to have_content(story.name)

    page.find('a#top-menu-rich-more-toggler').click
    expect(page).to have_content(I18n.t(:menu_easy_knowledge))
  end

  def can_create_project_categories?(project)
    visit project_easy_knowledge_projects_path(project)
    expect(page).to have_content(Regexp.new(I18n.t(:label_easy_knowledge_new_project_category), 'i'))

    visit new_project_easy_knowledge_project_path(project)
    expect(page).to have_css('#top-menu')  # status 200
  end

  def can_edit_project_categories?(category)
    visit project_easy_knowledge_project_path(category.entity_id, category)
    expect(page).to have_content(Regexp.new(I18n.t(:button_edit), 'i'))

    visit edit_project_easy_knowledge_project_path(category.entity_id, category)
  end

  def can_create_global_categories?
    visit easy_knowledge_globals_path
    expect(page).to have_content(Regexp.new(I18n.t(:label_easy_knowledge_new_global_category), 'i'))

    visit new_easy_knowledge_global_path
  end

  def can_edit_global_categories?(category)
    visit easy_knowledge_global_path(category)
    expect(page).to have_content(Regexp.new(I18n.t(:button_edit), 'i'))
    visit edit_easy_knowledge_global_path(category)
  end

  def can_customise_page?
    visit easy_knowledge_overview_path
    expect(page).to have_css('.customize-button')
    expect(page).to have_content(Regexp.new(I18n.t(:label_personalize_page), 'i'))
  end

  def cannot_customise_page?
    visit easy_knowledge_overview_path
    expect(page).not_to have_css('.customize-button')
    expect(page).not_to have_content(Regexp.new(I18n.t(:label_personalize_page), 'i'))
  end

  def can_see_project_categories_in_new?(project)
    visit new_project_easy_knowledge_story_path(project)
    expect(page).to have_content(I18n.t(:label_easy_knowledge_index_project))
    expect(page).to have_css('.easy-knowledge-stories-form-right-panel')
  end

  def can_see_global_categories_in_new?
    visit new_easy_knowledge_story_path
    expect(page).to have_content(I18n.t(:label_easy_knowledge_index_global))
    expect(page).to have_css('.easy-knowledge-stories-form-right-panel')
  end

  def cannot_see_global_categories_in_project_new?(project)
    visit new_project_easy_knowledge_story_path(project)
    expect(page).not_to have_content(I18n.t(:label_easy_knowledge_index_global))
  end
end

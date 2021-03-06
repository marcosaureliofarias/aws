require File.expand_path('../../../../easyproject/easy_plugins/easy_extensions/test/spec/spec_helper', __FILE__)

RSpec.feature 'Baseline', :logged => :admin, :js => true do
  include ActiveJob::TestHelper

  let!(:project_no_baseline) { FactoryGirl.create(:project, add_modules: %w(easy_gantt)) }
  let!(:project) { FactoryGirl.create(:project, add_modules: %w(easy_gantt easy_baselines)) }

  around(:each) do |example|
    with_settings(rest_api_enabled: 1) do
      example.run
    end
  end

  def open_baseline_toolbar
    find('.easy-gantt__menu-tools').hover
    expect(page).to have_selector('#button_baseline')
    find('#button_baseline').click
    find('#button_jump_today').hover
  end

  it 'should not be displayed if module is turned off' do
    visit easy_gantt_path(project_no_baseline)
    wait_for_ajax
    page.find('.easy-gantt__menu-tools').hover
    expect(page).to have_no_selector('#button_baseline')
  end

  it 'should load empty header' do
    visit easy_gantt_path(project)
    wait_for_ajax
    within('#content') do
      find('.easy-gantt__menu-tools').hover
      open_baseline_toolbar
      expect(page).to have_selector('#baseline_create')
      expect(page).to have_no_selector('#baseline_select')
    end
  end

  it 'create, load and delete new baseline' do
    visit easy_gantt_path(project)
    wait_for_ajax
    within('#content') do
      open_baseline_toolbar
      expect(page).to have_no_selector('.gantt-baseline')
      find('#baseline_create').click
    end
    within('#form-modal') do
      fill_in(I18n.t(:field_name), :with => 'Baseline of '+project.name)
    end
    expect {
      find('#baseline_modal_submit').click
      wait_for_ajax 20
    }.to have_enqueued_job(CreateEasyBaselineJob)
    perform_enqueued_jobs do
      CreateEasyBaselineJob.perform_later(project, User.current, { title: 'Baseline of '+project.name })
    end

    visit easy_gantt_path(project)
    wait_for_ajax
    within('#content') do
      open_baseline_toolbar
    end

    expect(page).to have_selector('#baseline_select') #.to have_content('Baseline of '+project.name)
    expect(page).to have_selector('.gantt-baselines')
    expect(page).to have_selector('.gantt-baseline')
  end

end

RSpec.shared_examples :make_project_from_template do |original_start_date, new_start_date, dates_settings, expectation|
  it '#make_project_from_template' do
    issue = template.issues.first
    issue.update_columns(start_date: original_start_date)
    issue.reload
    post :make_project_from_template, params: {
        id:       template,
        template: {
            dates_settings: dates_settings,
            start_date:     new_start_date
        }
    }
    new_issue = assigns(:new_project).issues.where(subject: issue.subject).first
    expect(expectation).to eq(new_issue.start_date)
  end
end

RSpec.shared_examples :copy_project_from_template do |original_start_date, new_start_date, dates_settings, expectation|
  it '#copy_project_from_template' do
    issue = template.issues.first
    issue.update_columns(start_date: original_start_date)
    issue.reload
    post :copy_project_from_template, params: {
        id:       template,
        template: {
            target_root_project_id: project,
            dates_settings: dates_settings,
            start_date:     new_start_date
        }
    }
    new_issue = Issue.where(project_id: project).where(subject: issue.subject).first
    expect(expectation).to eq(new_issue.start_date)
  end
end

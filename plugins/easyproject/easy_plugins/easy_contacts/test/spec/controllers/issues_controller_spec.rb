require 'easy_extensions/spec_helper'

describe IssuesController, logged: :admin do

  let(:easy_contact) { FactoryGirl.create(:easy_contact) }
  let(:issue) { FactoryGirl.create(:issue) }

  render_views
  it 'render issue to JSON with related contacts' do
    issue.easy_contacts = [easy_contact]
    issue.save; issue.reload
    get :show, params: {id: issue.id, include: ['related_contacts'], format: 'json'}
    expect(response).to be_successful
    expect(response.body).to include(easy_contact.firstname)
    expect(response.body).to include(easy_contact.lastname)
  end
end

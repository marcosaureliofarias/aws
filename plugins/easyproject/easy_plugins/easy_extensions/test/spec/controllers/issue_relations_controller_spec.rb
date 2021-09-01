require 'easy_extensions/spec_helper'

describe IssueRelationsController, :logged => :admin do

  let(:project) { FactoryGirl.create(:project, number_of_issues: 0) }
  let(:issue1) { FactoryGirl.create(:issue, :project => project) }
  let(:issue2) { FactoryGirl.create(:issue, :project => project) }
  let(:issue3) { FactoryGirl.create(:issue, :project => project) }

  render_views

  def create_relation
    relation               = IssueRelation.new
    relation.issue_from    = issue1
    relation.issue_to      = issue2
    relation.relation_type = 'relates'
    relation.save!
    relation
  end

  it 'create json' do
    expect {
      post :create, params: { issue_id: issue1.id, relation: { issue_to_id: issue2.id, relation_type: 'relates' }, format: 'json' }
    }.to change(IssueRelation, :count).by(1)
    expect(response).to be_successful
    expect(response.body).not_to be_blank
  end

  it 'create json multiple relations' do
    expect {
      post :create, params: { issue_id: issue1.id, relation: { issue_to_id: [issue2.id, issue3.id], relation_type: 'relates' }, format: 'json' }
    }.to change(IssueRelation, :count).by(2)
    expect(response).to be_successful
    expect(response.body).to be_blank
  end

  it 'destroy html' do
    delete :destroy, :params => { :id => create_relation.id, :issue_id => issue1.id }
    expect(response).to have_http_status(302)
  end

  it 'destroy js' do
    delete :destroy, :params => { :id => create_relation.id, :issue_id => issue1.id, :format => 'js' }
    expect(response).to be_successful
  end

  it 'destroy json' do
    delete :destroy, :params => { :id => create_relation.id, :issue_id => issue1.id, :format => 'json' }
    expect(response).to be_successful
  end

end

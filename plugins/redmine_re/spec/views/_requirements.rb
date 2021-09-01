require_relative "../spec_helper"

shared_examples :requirements do
  let(:user) { create :user }

  before :each do
    assign(:project, double(Project, id: 1, identifier: 'project-1'))

    # allow(User).to receive(:current).and_return(user)
    allow(user).to receive(:allowed_to?).and_return(true)

    assign(:re_artifact_settings, [['ReRequirement', { in_use: true, alias: 're_requirement' }]])
  end
end
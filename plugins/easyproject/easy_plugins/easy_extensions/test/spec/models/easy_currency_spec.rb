require 'easy_extensions/spec_helper'

describe EasyCurrency, logged: :admin do

  let(:project) { FactoryGirl.create(:project, name: 'My project') }

  it 'assign project_ids' do
    c                 = EasyCurrency.new
    c.safe_attributes = { 'project_ids' => [project.id] }
    expect(c.projects.map(&:id)).to eq([project.id])
  end

end

require 'easy_extensions/spec_helper'

describe EnumerationsController, :logged => :admin do
  let(:time_entry_activity) { FactoryBot.create(:time_entry_activity) }

  it 'create' do
    expect {
      post :create, params: { enumeration: { allow_time_entry_zero_hours: '1', name: 'enum', type: 'TimeEntryActivity' } }
    }.to change(Enumeration, :count).by(1)
    expect(Enumeration.last.allow_time_entry_zero_hours).to eq(true)
  end

  it 'update' do
    put :update, params: { id: time_entry_activity.id,
                           enumeration: { allow_time_entry_zero_hours: '1',
                                          name: 'enum',
                                          description: 'Enumeration Description' } }
    enum = Enumeration.find time_entry_activity.id
    expect(enum.name).to eq('enum')
    expect(enum.description).to eq('Enumeration Description')
    expect(enum.allow_time_entry_zero_hours).to eq(true)
  end

  context 'assign projects' do
    let(:project) { FactoryBot.create(:project) }
    let(:project2) { FactoryBot.create(:project) }

    it 'multiple' do
      project; project2
      expect {
        post :create, params: { enumeration: { name: 'enum', type: 'TimeEntryActivity', project_ids: [project.id, project2.id] } }
      }.to change(Enumeration, :count).by(1)
    end

    it 'invalid' do
      project
      allow_any_instance_of(Project).to receive(:valid?).and_return(false)
      expect {
        post :create, params: { enumeration: { name: 'enum', type: 'TimeEntryActivity', project_ids: [project.id] } }
      }.to change(Enumeration, :count).by(1)
    end
  end
end

require_relative "../spec_helper"

describe ReRelationtype, type: :model do
  let(:project) { create :project, add_modules: ['requirements'] }

  before :each do
    ReRelationtype.create!(
      project_id: project.id,
      relation_type: 'parentchild',
      alias_name: 'parentchild name',
      color: '#111111',
      is_system_relation: 1,
      is_directed: 1,
      in_use: 1
    )

    ReRelationtype.create!(
      project_id: project.id,
      relation_type: 'type 2',
      alias_name: 'type 2 name',
      color: '#222222',
      is_system_relation: 0,
      is_directed: 1,
      in_use: 1
    )

    ReRelationtype.create!(
      project_id: project.id,
      relation_type: 'type 3',
      alias_name: 'type 3 name',
      color: '#333333',
      is_system_relation: 1,
      is_directed: 1,
      in_use: 0
    )
  end

  describe '#relation_types' do
    it 'should have 3 relations' do
      expect(ReRelationtype.relation_types(project.id)).to eq(['parentchild', 'type 2', 'type 3'])
    end

    it 'should have 2 system relations' do
      expect(ReRelationtype.relation_types(project.id, true)).to eq(['parentchild', 'type 3'])
    end

    it 'should have 1 non system relation' do
      expect(ReRelationtype.relation_types(project.id, false)).to eq(['type 2'])
    end

    it 'should have 2 used relations' do
      expect(ReRelationtype.relation_types(project.id, nil, true)).to eq(['parentchild', 'type 2'])
    end

    it 'should have 1 unused relation' do
      expect(ReRelationtype.relation_types(project.id, nil, false)).to eq(['type 3'])
    end

    it 'should have 1 system used relation' do
      expect(ReRelationtype.relation_types(project.id, true, true)).to eq(['parentchild'])
    end

    it 'should have 1 system unused relations' do
      expect(ReRelationtype.relation_types(project.id, true, false)).to eq(['type 3'])
    end

    it 'should have 1 non system used relation' do
      expect(ReRelationtype.relation_types(project.id, false, true)).to eq(['type 2'])
    end

    it 'should have 0 non system unused relations' do
      expect(ReRelationtype.relation_types(project.id, false, false)).to eq([])
    end
  end

  describe '#in_use' do
    it 'should have relation with parentchild type' do
      expect(ReRelationtype.in_use('parentchild', project.id)).to eq(true)
    end

    it 'should have no relation with Type 4 type' do
      expect(ReRelationtype.in_use('Type 4', project.id)).to eq(false)
    end
  end

  describe '#get_alias_name' do
    it 'should have alias_name' do
      expect(ReRelationtype.get_alias_name('parentchild', project.id)).to eq('parentchild name')
    end

    it 'should have no alias_name' do
      expect(ReRelationtype.get_alias_name('Type 4', project.id)).to eq('')
    end
  end
end

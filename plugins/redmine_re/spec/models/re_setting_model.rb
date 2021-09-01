require_relative "../spec_helper"

describe ReSetting, type: :model do
  let(:project) { create :project, add_modules: ['requirements'] }
  let(:params) { { name: 'Pokus', project_id: project.id, value: 'Value' } }
  let(:hash_value) { { 'value' => params[:value] } }
  let(:serialized_value) { "{\"value\":\"#{params[:value]}\"}" }

  it 'has unique name within project' do
    ReSetting.create! params
    expect { ReSetting.create! params }.to raise_error(ActiveRecord::RecordInvalid)
  end

  it 'can save plain value' do
    value = ReSetting.set_plain(params[:name], params[:project_id], params[:value])
    expect(value).to eq(params[:value])
  end

  it 'can get plain value from database' do
    ReSetting.create! params
    value = ReSetting.get_plain(params[:name], params[:project_id])
    expect(value).to eq(params[:value])
  end

  it 'can get plain value from cache' do
    ReSetting.set_plain(params[:name], params[:project_id], params[:value])
    expect(ReSetting.get_plain(params[:name], params[:project_id])).to eq(params[:value])
  end

  it 'can store serialized value' do
    ReSetting.set_serialized(params[:name], params[:project_id], hash_value)
    setting = ReSetting.find_by(name: params[:name], project_id: params[:project_id])
    expect(setting.value).to eq(serialized_value)
  end

  it 'can get serialized value' do
    param = params.dup
    param[:value] = serialized_value
    ReSetting.create! param
    expect(ReSetting.get_serialized(param[:name], param[:project_id])).to eq(hash_value)
  end

  context 'with setup artifacts' do
    let(:artifact_order) { ['ReRequirement', 'ReChangeRequest', 'ReSection'] }
    let(:artifact_settings) do
      [
        { name: 'ReRequirement', value: { in_use: true, alias: '', color: '#111111' } },
        { name: 'ReChangeRequest', value: { in_use: false, alias: '', color: '#222222' } },
        { name: 'ReSection', value: { in_use: true, alias: '', color: '#333333' } }
      ]
    end

    before :each do
      ReSetting.set_serialized('artifact_order', project.id, artifact_order)
      artifact_settings.each { |artifact| ReSetting.set_serialized(artifact[:name], project.id, artifact[:value]) }
    end

    it 'should get artifact settings' do
      active_settings = ReSetting.active_re_artifact_settings(project.id)
      expect(active_settings.keys.size).to eq(2)
    end
  end

  context 'with setup relations' do
    let(:relation_order) { ['conflict', 'parentchild', 'dependency'] }
    let(:relation_settings) do
      [
        { name: 'conflict', value: { directed: true, in_use: true, alias: 'conflict', color: '#444444' } },
        { name: 'parentchild', value: { directed: true, in_use: true, alias: 'parentchild', color: '#555555' } },
        { name: 'dependency', value: { directed: true, in_use: false, alias: 'dependency', color: '#666666' } }
      ]
    end

    before :each do
      ReSetting.set_serialized('relation_order', project.id, relation_order)
      relation_settings.each { |relation| ReSetting.set_serialized(relation[:name], project.id, relation[:value]) }
    end

    it 'should get relation settings' do
      active_settings = ReSetting.active_re_relation_settings(project.id)
      expect(active_settings.keys.size).to eq(2)
    end
  end

  # never used
  it 'should force project reconfiguration' do
    ReSetting.set_serialized('unconfirmed', project.id, false)
    ReSetting.force_reconfig
    expect(ReSetting.get_serialized('unconfirmed', project.id)).to eq(true)
  end
end
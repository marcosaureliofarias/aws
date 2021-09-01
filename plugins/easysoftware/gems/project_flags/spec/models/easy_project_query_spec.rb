RSpec.describe EasyProjectQuery do

  let(:custom_field) { FactoryBot.create(:project_custom_field, field_format: 'flag', show_on_list: true) }

  it 'includes query column' do
    custom_field
    query = EasyProjectQuery.new
    expect(query.available_columns.map(&:name)).to include(:"cf_#{custom_field.id}")
  end

  it 'allows grouping by a flag custom field' do
    custom_field
    query = EasyProjectQuery.new

    expect(query.groupable_columns.map(&:name)).to include :"cf_#{custom_field.id}"
  end
end
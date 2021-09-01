RSpec.describe EasyGanttHelper, type: :helper do

  let(:custom_field) { FactoryBot.create(:custom_field, type: 'ProjectCustomField', field_format: 'flag') }
  let(:project) { FactoryBot.create(:project) }

  helper :custom_fields

  it "#gantt_format_column" do
    column = EasyQueryCustomFieldColumn.new(custom_field)
    expect(helper.gantt_format_column(project, column, nil)).to match 'icon icon-project-flag icon-project-flag'
  end

end if Redmine::Plugin.installed?(:easy_gantt)

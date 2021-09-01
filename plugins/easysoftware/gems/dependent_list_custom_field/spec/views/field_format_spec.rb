RSpec.describe "issues/new.html.erb" do
  include_context "depended custom field"

  it "render cf" do
    issue = FactoryBot.build :issue
    assign :issue, issue
    assign :custom_field_values, [CustomFieldValue.new(custom_field: automaker_cf, customized: issue), CustomFieldValue.new(custom_field: brand_cf, customized: issue)]
    stub_template "issues/new.html.erb" => "<%= @custom_field_values.each do |value| %>\n  <%= custom_field_tag_with_label 'issue', value %>\n<% end %>"
    render
    expect(rendered).to match /select.*id="issue_custom_field_values_#{automaker_cf.id}_".*data\-dependency/
    expect(rendered).to match /select.*id="issue_custom_field_values_#{brand_cf.id}_".*data\-dependency/
  end
end
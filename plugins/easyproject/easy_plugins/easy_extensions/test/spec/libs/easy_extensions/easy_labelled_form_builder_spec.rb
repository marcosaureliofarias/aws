RSpec.describe EasyExtensions::EasyLabelledFormBuilder do
  it 'checkbox' do
    context = ApplicationController.new.view_context
    tag     = described_class.new("issue", Issue.new, context, {}).check_box(:private_notes)
    expect(tag).to match(/<label.*for=\"issue_private_notes\"/)
    expect(tag).to match(/<input type=\"checkbox\".*id=\"issue_private_notes\"/)
  end
end

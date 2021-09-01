require "easy_extensions/spec_helper"

RSpec.describe EasyExtensions::ApiViewContext do
  let(:issue) { FactoryBot.create :issue }
  it ".get_context" do
    context = described_class.get_context
    context.instance_variable_set :@issue, issue
    context.render template: "issues/show", locals: { issue: issue }
  end
end
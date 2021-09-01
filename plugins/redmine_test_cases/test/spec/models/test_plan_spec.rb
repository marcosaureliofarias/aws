require 'easy_extensions/spec_helper'

describe TestPlan do
  let(:project) { FactoryBot.create :project, :add_modules => %w(test_cases) }
  let(:test_plan) { FactoryBot.create :test_plan, project: project, id: 6543 }

  it 'finds test case with like by id' do
    test_plan # touch it to create
    tp = TestPlan.like("54").first
    expect(tp.id).to eq(6543)
  end

end

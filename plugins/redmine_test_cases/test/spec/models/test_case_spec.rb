require 'easy_extensions/spec_helper'

describe TestCase do
  let(:project) { FactoryBot.create :project, :add_modules => %w(test_cases) }
  let(:test_case) { FactoryBot.create :test_case, project: project, id: 6543 }

  it 'finds test case with like by id' do
    test_case # touch it to create
    tc = TestCase.like("54").first
    expect(tc.id).to eq(6543)
  end

end

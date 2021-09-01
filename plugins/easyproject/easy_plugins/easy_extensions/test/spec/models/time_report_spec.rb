require 'easy_extensions/spec_helper'

describe Redmine::Helpers::TimeReport do

  let(:scope_stub) { spy('TimeEntry', sum: {
      [11, 2019, 1, 1, '2019-01-04'.to_date] => 5.0,
      [14, 2019, 1, 1, '2019-01-05'.to_date] => 5.0,
      [17, 2019, 1, 1, '2019-01-06'.to_date] => 5.0,
      [20, 2019, 1, 2, '2019-01-07'.to_date] => 5.0
  }) }

  subject { Redmine::Helpers::TimeReport.new(nil, nil, ['user'], 'week', scope_stub) }

  it 'uniq periods' do
    expect(subject.periods).to eq(["2019-1", "2019-2"])
  end

end
require 'easy_extensions/spec_helper'

RSpec.describe IssueEasySprintRelation do

  let(:value1) { "estimated_hours" }
  let(:project) { FactoryBot.create(:project) }
  let(:sprint1) { FactoryBot.create(:easy_sprint, project: project) }
  around(:each) do |scenario|
    sprint1_settings = {}
    sprint1_settings["easy_sprint_burndown_#{sprint1.id}"] = value1
    with_easy_settings(sprint1_settings) do
      scenario.run
    end
  end

  describe '#column_for_rating' do

    subject { described_class.column_for_rating(sprint1.id, project.id) }

    context 'with settings present' do

      before do
        allow_any_instance_of(EasyIssueQuery).to receive(:get_column).and_return(value1)
      end

      it 'returns column for matching setting' do
        expect(subject).to eq(value1)
      end

      it 'returns null for no matching sprint' do
        expect(IssueEasySprintRelation.column_for_rating(1231231, project.id)).to be_nil
      end

      it 'returns setting regardless of no matching project' do
        expect(IssueEasySprintRelation.column_for_rating(sprint1.id, 3123123)).to eq(value1)
      end
    end

    context 'caches value' do

      it 'for subsequent call for same sprint' do
        query_instance = instance_double('EasyIssueQuery', :get_column => value1)
        expect(EasyIssueQuery).to receive(:new).and_return(query_instance).once
        expect(subject).to eq(value1)
        expect(subject).to eq(value1)
      end
    end

    context 'returns values' do
      let(:value2) { "story_points" }
      let(:sprint2) { FactoryBot.create(:easy_sprint, project: project) }

      before do
        allow_any_instance_of(EasyIssueQuery).to receive(:get_column).with(value1).and_return(value1)
        allow_any_instance_of(EasyIssueQuery).to receive(:get_column).with(value2).and_return(value2)
      end

      it 'for each sprint' do
        sprint2_settings = {}
        sprint2_settings["easy_sprint_burndown_#{sprint2.id}"] = value2
        with_easy_settings(sprint2_settings) do
          expect(subject).to eq(value1)
          value_for_sprint2 = described_class.column_for_rating(sprint2.id, project.id)
          expect(value_for_sprint2).to eq(value2)
        end
      end
    end

  end
end
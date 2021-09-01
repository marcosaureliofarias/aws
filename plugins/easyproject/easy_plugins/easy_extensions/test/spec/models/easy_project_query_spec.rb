require 'easy_extensions/spec_helper'

describe EasyProjectQuery, logged: :admin do
  subject(:project_query) { described_class.new(name: '_') }

  let(:user) { FactoryBot.create(:user) }
  let(:project_ok) { FactoryBot.create(:project, easy_due_date: nil) }
  let(:project_alert) { FactoryBot.create(:project, easy_due_date: Date.today - 1.day) }
  let(:project_author) { FactoryBot.create(:project, author: user, easy_due_date: Date.today + 1.day) }
  let(:project_tmpl) { FactoryBot.create(:project, author: user, easy_due_date: Date.today + 1.day, easy_is_easy_template: true) }

  context 'when filtering by indicator' do
    before do
      project_ok
      project_alert
      project_author
      project_tmpl
    end

    it 'retruns correct results for indicator alert' do
      params = { 'set_filter' => '1', 'author_id' => 'me', 'easy_indicator' => Project::EASY_INDICATOR_ALERT.to_s }
      project_query.from_params(params)

      expect(project_query.entity_count).to eq 1
      expect(project_query.entities).to include project_alert
    end

    it 'retruns correct results for indicator ok' do
      params = { 'set_filter' => '1', 'author_id' => user.id.to_s, 'easy_indicator' => Project::EASY_INDICATOR_OK.to_s }
      project_query.from_params(params)

      expect(project_query.entity_count).to eq 1
      expect(project_query.entities).to include project_author
    end

    it 'retruns correct results for indicator combined with other filter criteria' do
      params = { 'set_filter' => '1', 'author_id' => user.id.to_s, 'easy_indicator' => Project::EASY_INDICATOR_ALERT.to_s }
      project_query.from_params(params)

      expect(project_query.entity_count).to eq 0
      expect(project_query.entities).to be_empty
    end

    it 'excludes projects with no indicator from results according to settings' do
      with_easy_settings(default_project_indicator: '0') do
        params = { 'set_filter' => '1', 'author_id' => 'me', 'easy_indicator' => "#{Project::EASY_INDICATOR_ALERT}|#{Project::EASY_INDICATOR_OK}|#{Project::EASY_INDICATOR_WARNING}" }
        project_query.from_params(params)

        expect(project_query.entity_count).to eq 1
        expect(project_query.entities).to include project_alert
      end
    end

    it 'includes projects with no indicator from results according to settings' do
      with_easy_settings(default_project_indicator: '20') do
        params = { 'set_filter' => '1', 'author_id' => 'me', 'easy_indicator' => "#{Project::EASY_INDICATOR_ALERT}|#{Project::EASY_INDICATOR_OK}|#{Project::EASY_INDICATOR_WARNING}" }
        project_query.from_params(params)

        expect(project_query.entity_count).to eq 2
        expect(project_query.entities).to include project_ok
        expect(project_query.entities).to include project_alert
      end
    end
  end

  context 'when filtering by tags' do
    let(:project_with_tag) { FactoryBot.create(:project, tag_list: ['hello']) }

    before do
      project_with_tag; project_ok
    end

    it 'retruns correct results for specific tag' do
      params = { 'set_filter' => '1', 'tags' => 'hello' }
      project_query.from_params(params)

      expect(project_query.entity_count).to eq 1
      expect(project_query.entities).to include project_with_tag
    end

    it 'retruns correct results for any tag' do
      params = { 'set_filter' => '1', 'tags' => '*' }
      project_query.from_params(params)

      expect(project_query.entity_count).to eq 1
      expect(project_query.entities).to include project_with_tag
    end
  end

  context 'when filtering by free text' do
    let(:project_earth) { FactoryBot.create(:project, name: 'Planet Earth') }
    let(:project_mars) { FactoryBot.create(:project, name: 'Planet Mars') }
    let(:project_moon) { FactoryBot.create(:project, name: 'Moon') }
    let(:project_list) { FactoryBot.create_list(:project, 26) }

    it 'retruns correct results for non-empty search terms' do
      project_earth
      project_mars
      project_moon

      params = { 'easy_query_q' => 'planet' }
      project_query.from_params(params)

      expect(project_query.entities).to include project_earth
      expect(project_query.entities).to include project_mars
      expect(project_query.entities).to_not include project_moon
    end

    it 'retruns first 25 projects for empty search terms' do
      project_list

      params = { 'easy_query_q' => '' }
      project_query.from_params(params)

      expect(project_query.entity_count).to eq 25
    end
  end
end

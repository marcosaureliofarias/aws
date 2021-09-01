require 'easy_extensions/spec_helper'

RSpec.describe EasyApiDecorators::Issue, logged: :admin do
  ISSUE_INCLUDES = %w[children changesets relations watchers journals attachments]

  describe 'api includes' do
    let!(:tracker) { FactoryGirl.create(:tracker) }
    let(:issue) { FactoryBot.create(:issue, :with_journals, :with_attachment, author: User.current, tracker: tracker).reload }

    it 'works with includes output json' do
      json_issue = JSON.parse(EasyApiDecorators::Issue.new(issue, ISSUE_INCLUDES).to_json)
      expect(json_issue['issue']['journals'].map { |journal| journal['notes'] }).to contain_exactly(*issue.journals.map(&:notes))
      expect(json_issue['issue']['attachments'][0]['filename']).to eq issue.attachments.first.filename
    end

    it 'works with includes output xml' do
      xml_issue = Nokogiri.parse(EasyApiDecorators::Issue.new(issue, ISSUE_INCLUDES).to_xml)
      expect(xml_issue.xpath('//issue/journals/journal/notes').map(&:text)).to contain_exactly(*issue.journals.map(&:notes))
      expect(xml_issue.xpath('//issue/attachments/attachment/filename').text).to eq issue.attachments.first.filename
    end

    context 'with lookup custom field' do
      let!(:lookup_cf) { FactoryGirl.create(:issue_custom_field,
                                            field_format: 'easy_lookup',
                                            settings:     {
                                                              entity_type:      'User',
                                                              entity_attribute: 'link_with_name' }.with_indifferent_access,
                                            trackers:     [tracker],
                                            is_for_all:   true
      )
      }

      before(:each) do
        issue.custom_field_values = { lookup_cf.id.to_s => User.current.id }
        issue.save
      end

      it 'output json' do
        json_issue = JSON.parse(EasyApiDecorators::Issue.new(issue, ISSUE_INCLUDES).to_json)
        expect(json_issue['issue']['journals'].map { |journal| journal['notes'] }).to contain_exactly(*issue.journals.map(&:notes))
        expect(json_issue['issue']['attachments'][0]['filename']).to eq issue.attachments.first.filename
      end

      it 'output xml' do
        xml_issue = Nokogiri.parse(EasyApiDecorators::Issue.new(issue, ISSUE_INCLUDES).to_xml)
        expect(xml_issue.xpath('//issue/journals/journal/notes').map(&:text)).to contain_exactly(*issue.journals.map(&:notes))
        expect(xml_issue.xpath('//issue/attachments/attachment/filename').text).to eq issue.attachments.first.filename
      end

    end

  end

end

require 'easy_extensions/spec_helper'

describe EasyJournalHelper do
  let!(:attachment) { FactoryBot.build_stubbed(:attachment, filename: 'test.png', versions: [attachment_version]) }
  let!(:attachment_with_more_versions) { FactoryBot.build_stubbed(:attachment, filename: 'test.png', versions: [attachment_version, attachment_version_lastest]) }
  let!(:attachment_version) { FactoryBot.build_stubbed(:attachment_version, filename: 'test.png') }
  let!(:attachment_version_lastest) { FactoryBot.build_stubbed(:attachment_version, filename: 'test.png') }
  let!(:issue) { FactoryBot.build_stubbed(:issue, attachments: [attachment, attachment_with_more_versions]) }

  it '#easy_journal_link_to_attachment' do
    expect(helper.easy_journal_link_to_attachment(attachment)).not_to include('v1')
    expect(helper.easy_journal_link_to_attachment(attachment_with_more_versions)).to include('v1')
    expect(helper.easy_journal_link_to_attachment(attachment_version)).to include("v#{attachment_version.version}")
    expect(helper.easy_journal_link_to_attachment(attachment_version_lastest)).to include("v#{attachment_version_lastest.version}")
  end
end

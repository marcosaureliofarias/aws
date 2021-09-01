require 'easy_extensions/spec_helper'

describe JournalsHelper do
  context 'attachments' do
    let!(:attachment) { FactoryGirl.build_stubbed(:attachment, filename: 'test.png', versions: [attachment_version, attachment_version_lastest]) }
    let!(:attachment_version) { FactoryGirl.build_stubbed(:attachment_version, filename: 'test.png') }
    let!(:attachment_version_lastest) { FactoryGirl.build_stubbed(:attachment_version, filename: 'test.png') }
    let!(:issue) { FactoryGirl.build_stubbed(:issue, attachments: [attachment]) }
    let!(:journal) { FactoryGirl.build_stubbed(:journal, journalized_type: 'Issue', journalized_id: issue.id, journalized: issue, details: [journal_detail_attachment, journal_detail_version, journal_detail_version_lastest]) }
    let!(:journal_detail_attachment) { FactoryGirl.build_stubbed(:journal_detail, property: 'attachment', prop_key: attachment.id.to_s, value: attachment.filename) }
    let!(:journal_detail_version) { FactoryGirl.build_stubbed(:journal_detail, property: 'attachment_version', prop_key: attachment_version.id.to_s, value: attachment.filename) }
    let!(:journal_detail_version_lastest) { FactoryGirl.build_stubbed(:journal_detail, property: 'attachment_version', prop_key: attachment_version_lastest.id.to_s, value: attachment.filename) }

    it 'thumbnails' do
      allow_any_instance_of(Attachment).to receive(:thumbnailable?).and_return(true)
      allow_any_instance_of(AttachmentVersion).to receive(:thumbnailable?).and_return(true)
      thumbnails = helper.journal_thumbnail_attachments(journal)
      expect(thumbnails.size).to eq(3)
      expect(thumbnails.map(&:id)).to eq([attachment_version, attachment_version, attachment_version_lastest].map(&:id))
    end

  end
end

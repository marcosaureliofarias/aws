require 'easy_extensions/spec_helper'

describe Attachment, logged: true do
  context 'versions' do
    let!(:attachment) { FactoryGirl.create(:attachment, filename: 'test.png') }
    let!(:attachment_version) { attachment.versions.first }
    let!(:attachment_version2) { attachment.versions.first.dup.tap { |a| a.version = 2; a.save } }

    it 'next' do
      expect(attachment_version.next).to eq(attachment_version2)
      expect(attachment_version2.next).to eq(nil)
    end

    it 'previous' do
      expect(attachment_version.previous).to eq(nil)
      expect(attachment_version2.previous).to eq(attachment_version)
    end

    it 'latest' do
      expect(attachment.versions.latest).to eq(attachment_version2)
    end
  end

  describe 'custom fields' do
    let!(:required_custom_field) { FactoryGirl.create(:attachment_custom_field, :is_required => true) }

    context 'when new attachment' do
      context 'when file is loaded (no container)' do
        let(:attachment) { FactoryGirl.create(:attachment, :container => nil) }

        it 'has no custom field values' do
          expect(CustomValue.where(:customized_id => attachment.id).count).to eq 0
        end
      end

      context 'when loaded file is submitted' do
        let(:attachment) { FactoryGirl.create(:attachment) }

        it 'custom fields values are saved' do
          expect(CustomValue.where(:customized_id => attachment.id).count).to eq 1
        end

        context 'when required custom fields are empty' do
          it 'attachment is invalid' do
            attachment.custom_field_values = { required_custom_field.id => nil }

            expect(attachment).not_to be_valid
          end
        end
      end
    end

    context 'when new version' do
      let(:loaded_version_file) { FactoryGirl.create(:attachment, :container => nil, :digest => 'a3463455635742ca3e2b9cc9f28448b1') }

      context 'when file is loaded (no container)' do
        it 'has no custom field values' do
          expect(CustomValue.where(:customized_id => loaded_version_file.id).count).to eq 0
        end
      end

      context 'when loaded file is submitted' do
        let(:former_custom_value) { 'X' }
        let(:new_version_custom_value) { 'Y' }
        let(:attachment) { FactoryGirl.create(:attachment, :custom_field_values => { required_custom_field.id => 'X' }) }
        let(:issue) { attachment.container }
        let(:attachment_version_params) do
          {
              'token'                            => "#{loaded_version_file.id}.#{loaded_version_file.digest}",
              'custom_version_for_attachment_id' => attachment.id,
              'custom_field_values'              => { required_custom_field.id => new_version_custom_value }
          }
        end

        it 'saves its custom fields values to the former attachment version' do
          expect(CustomValue.where(:customized_id => attachment.id).first.value).to eq(former_custom_value)

          issue.save_attachments([attachment_version_params])

          expect(CustomValue.where(:customized_id => attachment.id).first.value).to eq(new_version_custom_value)
        end

        it 'increments version of the former attachment by 1' do
          saved = issue.save_attachments([attachment_version_params])

          expect(saved[:new_versions].first.version).to eq(attachment.version + 1)
        end

        context 'when required custom fields are empty' do
          it 'new attachment version is not saved' do
            attachment_version_params['custom_field_values'] = { required_custom_field.id => nil }
            saved                                            = issue.save_attachments([attachment_version_params])

            expect(saved[:new_versions]).to be_empty
          end
        end

        context 'without custom fields defined' do
          it 'saves attachment', :x => true do
            attachment_params                        = attachment_version_params.dup
            attachment_params['custom_field_values'] = nil

            saved = issue.save_attachments([attachment_params])

            expect(saved[:new_versions].count).to eq 0
          end
        end
      end
    end
  end

  it 'set content_type' do
    expect(FactoryBot.create(:attachment, filename: 'test.txt').content_type).to eq('text/plain')
  end
end
